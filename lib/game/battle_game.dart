import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../models/enums.dart';
import '../models/enemy.dart';
import '../models/stats.dart';
import '../services/combat_service.dart';
import 'hero_component.dart';
import 'enemy_component.dart';
import 'floating_text_component.dart';
import 'lane_system.dart';

/// Flame tabanli savas sahnesi
class BattleGame extends FlameGame with TapCallbacks {
  BattleGame({
    required this.heroClass,
    required this.heroStats,
    this.stageId = 1,
  });

  final HeroClass heroClass;
  final Stats heroStats;
  final int stageId;

  late LaneSystem laneSystem;
  late HeroComponent heroComponent;
  Lane _currentLane = Lane.middle;

  void Function(Lane lane)? onLaneChanged;
  void Function(int wave, int total)? onWaveChanged;
  void Function(double current, double max)? onHeroHpChanged;
  void Function()? onHeroDied;

  Lane get currentLane => _currentLane;

  @override
  ui.Color backgroundColor() => const ui.Color(0xFF0F0F1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    laneSystem = LaneSystem(gameHeight: size.y);

    add(_BackgroundComponent(gameSize: size));
    add(_LaneIndicator(laneSystem: laneSystem, gameSize: size));

    heroComponent = HeroComponent(
      heroClass: heroClass,
      heroStats: heroStats,
      position: Vector2(80, laneSystem.laneY(Lane.middle)),
    );
    add(heroComponent);

    _spawnTestEnemy();
  }

  void _spawnTestEnemy() {
    final testEnemy = Enemy(
      id: 'w1_yelbegen_yavrusu',
      nameKey: 'enemyYelbegenYavrusu',
      archetype: EnemyArchetype.melee,
      worldId: 1,
      baseStats: const Stats(hp: 45, atk: 9, def: 2, spd: 1.0),
      lootTable: const LootTable(goldMin: 4, goldMax: 7, xp: 6),
    );

    add(EnemyComponent(
      enemyData: testEnemy,
      position: Vector2(size.x - 120, laneSystem.laneY(Lane.middle)),
      stageId: stageId,
      lane: Lane.middle,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (heroComponent.isDead) return;

    // Ayni serit dusmanlarini bul
    final enemies = children
        .whereType<EnemyComponent>()
        .where((e) => !e.isDead)
        .toList();

    // Hero otomatik saldiri
    if (heroComponent.updateAttack(dt)) {
      final sameLane =
          enemies.where((e) => e.lane == _currentLane).toList();
      if (sameLane.isNotEmpty) {
        // En yakin dusmana saldir
        sameLane.sort(
            (a, b) => a.position.x.compareTo(b.position.x));
        final target = sameLane.first;

        final result = CombatService.calculateDamage(
          attacker: heroStats,
          defender: Stats(
            def: target.scaledDef,
            dodge: target.enemyData.baseStats.dodge,
          ),
        );

        if (result.isMiss) {
          _spawnFloatingText('MISS', target.position,
              color: const ui.Color(0xFF888888), fontSize: 14);
        } else {
          target.takeDamage(result.damage);

          if (result.isCrit) {
            _spawnFloatingText(
              '${result.damage.toInt()}!',
              target.position,
              color: const ui.Color(0xFFFFD700),
              fontSize: 22,
            );
          } else {
            _spawnFloatingText(
              '${result.damage.toInt()}',
              target.position,
            );
          }

          // Lifesteal
          if (heroStats.lifesteal > 0) {
            final healAmt = result.damage * heroStats.lifesteal / 100;
            heroComponent.heal(healAmt);
            _spawnFloatingText(
              '+${healAmt.toInt()}',
              heroComponent.position,
              color: const ui.Color(0xFF4CAF50),
              fontSize: 14,
            );
          }
        }
      }
    }

    // Enemy AI + saldiri
    for (final enemy in enemies) {
      final shouldAttack =
          enemy.updateAI(dt, heroComponent.position.x, _currentLane);
      if (shouldAttack) {
        final result = CombatService.calculateDamage(
          attacker: Stats(
            atk: enemy.scaledAtk,
            spd: enemy.enemyData.baseStats.spd,
            crit: enemy.enemyData.baseStats.crit,
            critDmg: enemy.enemyData.baseStats.critDmg > 0
                ? enemy.enemyData.baseStats.critDmg
                : 150,
          ),
          defender: heroStats,
        );

        if (result.isMiss) {
          _spawnFloatingText('MISS', heroComponent.position,
              color: const ui.Color(0xFF888888), fontSize: 14);
        } else {
          heroComponent.takeDamage(result.damage);
          onHeroHpChanged?.call(
              heroComponent.currentHp, heroComponent.maxHp);

          if (result.isCrit) {
            _spawnFloatingText(
              '${result.damage.toInt()}!',
              heroComponent.position,
              color: const ui.Color(0xFFFF4444),
              fontSize: 22,
            );
          } else {
            _spawnFloatingText(
              '${result.damage.toInt()}',
              heroComponent.position,
              color: const ui.Color(0xFFFF8888),
            );
          }

          if (heroComponent.isDead) {
            onHeroDied?.call();
          }
        }
      }
    }
  }

  void _spawnFloatingText(
    String text,
    Vector2 origin, {
    ui.Color color = const ui.Color(0xFFFFFFFF),
    double fontSize = 16,
  }) {
    add(FloatingTextComponent(
      text: text,
      position: origin.clone()..y -= 30,
      textColor: color,
      fontSize: fontSize,
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final tappedLane = laneSystem.laneFromY(event.localPosition.y);
    if (tappedLane != _currentLane) {
      _currentLane = tappedLane;
      heroComponent.moveTo(laneSystem.laneY(tappedLane));
      onLaneChanged?.call(tappedLane);
    }
  }
}

/// Arka plan gradient
class _BackgroundComponent extends PositionComponent {
  _BackgroundComponent({required this.gameSize})
      : super(size: gameSize, position: Vector2.zero());

  final Vector2 gameSize;

  @override
  void render(ui.Canvas canvas) {
    final rect = ui.Rect.fromLTWH(0, 0, gameSize.x, gameSize.y);
    final gradient = ui.Gradient.linear(
      ui.Offset(gameSize.x / 2, 0),
      ui.Offset(gameSize.x / 2, gameSize.y),
      [
        const ui.Color(0xFF1A2A1A),
        const ui.Color(0xFF0F1A0F),
        const ui.Color(0xFF0A120A),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, ui.Paint()..shader = gradient);
  }
}

/// Serit gostergesi
class _LaneIndicator extends PositionComponent {
  _LaneIndicator({required this.laneSystem, required this.gameSize})
      : super(size: gameSize, position: Vector2.zero());

  final LaneSystem laneSystem;
  final Vector2 gameSize;

  @override
  void render(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = const ui.Color(0x22FFFFFF)
      ..strokeWidth = 1;

    for (final lane in Lane.values) {
      final y = laneSystem.laneY(lane);
      canvas.drawLine(
        ui.Offset(0, y),
        ui.Offset(gameSize.x, y),
        paint,
      );
    }
  }
}
