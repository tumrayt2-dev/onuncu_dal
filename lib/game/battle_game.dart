import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../models/enums.dart';
import '../models/stats.dart';
import '../services/combat_service.dart';
import '../services/wave_service.dart';
import 'hero_component.dart';
import 'enemy_component.dart';
import 'floating_text_component.dart';
import 'lane_system.dart';

/// Flame tabanli savas sahnesi — 3 serit aktif sistem
class BattleGame extends FlameGame with TapCallbacks {
  BattleGame({
    required this.heroClass,
    required this.heroStats,
    this.stageId = 1,
    this.worldId = 1,
  });

  final HeroClass heroClass;
  final Stats heroStats;
  final int stageId;
  final int worldId;

  late LaneSystem laneSystem;
  late HeroComponent heroComponent;
  late WaveService waveService;
  Lane _currentLane = Lane.middle;

  int _totalXp = 0;
  int _totalGold = 0;
  bool _stageComplete = false;
  double _battleTimer = 0;
  bool _isPaused = false;

  // AFK AI
  bool afkEnabled = false;
  double _afkCheckTimer = 0;
  double _laneSwitchCooldown = 0;
  static const _afkCheckInterval = 1.0;
  static const _laneSwitchCooldownMax = 0.5;

  // Callbacks
  void Function(Lane lane)? onLaneChanged;
  void Function(int wave, int total)? onWaveChanged;
  void Function(double current, double max)? onHeroHpChanged;
  void Function()? onHeroDied;
  void Function(int xp, int gold, double hpPercent, double time)? onStageComplete;
  void Function(int xp, int gold)? onRewardPopup;
  void Function(int newLevel)? onLevelUp;
  void Function(Map<Lane, int> counts, Lane? bufferLane)? onLaneInfoChanged;
  void Function(Lane damageLane)? onSideDamageFlash;

  Lane get currentLane => _currentLane;
  bool get isPaused => _isPaused;

  void togglePause() {
    _isPaused = !_isPaused;
  }

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

    waveService = WaveService(stageId: stageId, worldId: worldId);
    waveService.init();
    onWaveChanged?.call(waveService.currentWave, waveService.totalWaves);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isPaused || heroComponent.isDead || _stageComplete) return;

    _battleTimer += dt;
    _laneSwitchCooldown = (_laneSwitchCooldown - dt).clamp(0, _laneSwitchCooldownMax);

    final enemies = children
        .whereType<EnemyComponent>()
        .where((e) => !e.isDead)
        .toList();

    // Dalga sistemi — yeni mob spawn
    final newEnemy = waveService.update(dt, enemies.length);
    if (newEnemy != null) {
      final lane = waveService.randomLane();
      add(EnemyComponent(
        enemyData: newEnemy,
        position: Vector2(size.x + 40, laneSystem.laneY(lane)),
        stageId: stageId,
        lane: lane,
      ));
      onWaveChanged?.call(waveService.currentWave, waveService.totalWaves);
    }

    // Stage tamamlandi mi?
    final currentEnemies = children
        .whereType<EnemyComponent>()
        .where((e) => !e.isDead)
        .toList();

    if (waveService.allWavesDone && currentEnemies.isEmpty && _battleTimer > 1.0) {
      _stageComplete = true;
      final hpPercent = heroComponent.currentHp / heroComponent.maxHp;
      onStageComplete?.call(_totalXp, _totalGold, hpPercent, _battleTimer);
      return;
    }

    // Serit bazli mob sayilarini hesapla (sadece ekran icindekiler)
    final visibleEnemies = currentEnemies.where((e) => e.position.x < size.x).toList();
    final laneCounts = <Lane, int>{};
    Lane? bufferLane;
    for (final lane in Lane.values) {
      final count = visibleEnemies.where((e) => e.lane == lane).length;
      laneCounts[lane] = count;
      if (bufferLane == null &&
          visibleEnemies.any((e) => e.lane == lane && e.isBufferOrHealer)) {
        bufferLane = lane;
      }
    }
    onLaneInfoChanged?.call(laneCounts, bufferLane);

    // AFK AI — otomatik serit degistirme (sadece aciksa)
    if (afkEnabled) {
      _afkCheckTimer += dt;
      if (_afkCheckTimer >= _afkCheckInterval && _laneSwitchCooldown <= 0) {
        _afkCheckTimer = 0;
        _autoSwitchLane(currentEnemies, bufferLane, laneCounts);
      }
    }

    // Hero otomatik saldiri — sadece ana serit, ekran icindeki en yakin mob
    if (heroComponent.updateAttack(dt)) {
      final sameLane = currentEnemies
          .where((e) => e.lane == _currentLane && e.position.x < size.x)
          .toList();
      if (sameLane.isNotEmpty) {
        sameLane.sort((a, b) => a.position.x.compareTo(b.position.x));
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
          }

          if (target.isDead || target.currentHp <= 0) {
            _onEnemyKilled(target);
          }
        }
      }
    }

    // Enemy AI — TUM seritler aktif
    for (final enemy in currentEnemies) {
      final shouldAttack =
          enemy.updateAI(dt, heroComponent.position.x, _currentLane);
      if (shouldAttack) {
        final isMainLane = enemy.lane == _currentLane;
        final damageMultiplier = isMainLane ? 1.0 : 0.5;

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
          final finalDmg = result.damage * damageMultiplier;
          heroComponent.takeDamage(finalDmg);
          onHeroHpChanged?.call(
              heroComponent.currentHp, heroComponent.maxHp);

          // Yan serit hasari flash
          if (!isMainLane) {
            onSideDamageFlash?.call(enemy.lane);
          }

          final dmgColor = isMainLane
              ? const ui.Color(0xFFFF4444)
              : const ui.Color(0xFFFF8888);
          final dmgText = isMainLane
              ? '${finalDmg.toInt()}'
              : '${finalDmg.toInt()} (x0.5)';

          if (result.isCrit) {
            _spawnFloatingText(
              '${finalDmg.toInt()}!',
              heroComponent.position,
              color: dmgColor,
              fontSize: 22,
            );
          } else {
            _spawnFloatingText(
              dmgText,
              heroComponent.position,
              color: dmgColor,
            );
          }

          if (heroComponent.isDead) {
            onHeroDied?.call();
          }
        }
      }
    }
  }

  /// AFK AI: mevcut serit bossa > buffer > 2x fazla mob > kalma
  void _autoSwitchLane(
    List<EnemyComponent> enemies,
    Lane? bufferLane,
    Map<Lane, int> laneCounts,
  ) {
    final currentCount = laneCounts[_currentLane] ?? 0;

    // Mevcut seritte hala mob varsa, onlari oncelikle temizle
    if (currentCount > 0) {
      // Sadece buffer mob icin istisna — buffer cok tehlikeli
      if (bufferLane != null && bufferLane != _currentLane) {
        // Buffer varsa bile mevcut seritte 2+ mob varsa kalma
        if (currentCount >= 2) return;
      } else {
        return; // Mevcut seritte mob var, kal
      }
    }

    Lane? targetLane;

    // 1. Buffer/healer mob varsa o seride gec
    if (bufferLane != null && bufferLane != _currentLane) {
      targetLane = bufferLane;
    }

    // 2. En cok mob olan serit
    if (targetLane == null) {
      int maxCount = 0;
      for (final lane in Lane.values) {
        if (lane == _currentLane) continue;
        final count = laneCounts[lane] ?? 0;
        if (count > maxCount) {
          maxCount = count;
          targetLane = lane;
        }
      }
      // Diger seritte mob yoksa gecme
      if (maxCount == 0) targetLane = null;
    }

    if (targetLane != null && targetLane != _currentLane) {
      _currentLane = targetLane;
      heroComponent.moveTo(laneSystem.laneY(targetLane));
      onLaneChanged?.call(targetLane);
      _laneSwitchCooldown = _laneSwitchCooldownMax;
    }
  }

  void _onEnemyKilled(EnemyComponent enemy) {
    final loot = enemy.enemyData.lootTable;
    final xp = loot.xp;
    final gold = loot.goldMin +
        (loot.goldMax > loot.goldMin
            ? (loot.goldMin + (loot.goldMax - loot.goldMin) ~/ 2)
            : 0);

    _totalXp += xp;
    _totalGold += gold;

    _spawnFloatingText(
      '+$xp XP',
      enemy.position.clone()..x -= 15,
      color: const ui.Color(0xFF64B5F6),
      fontSize: 13,
    );
    _spawnFloatingText(
      '+$gold G',
      enemy.position.clone()..x += 15,
      color: const ui.Color(0xFFFFD700),
      fontSize: 13,
    );

    onRewardPopup?.call(xp, gold);
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
    if (_isPaused) return;

    final tappedLane = laneSystem.laneFromY(event.localPosition.y);
    if (tappedLane != _currentLane && _laneSwitchCooldown <= 0) {
      _currentLane = tappedLane;
      heroComponent.moveTo(laneSystem.laneY(tappedLane));
      onLaneChanged?.call(tappedLane);
      _laneSwitchCooldown = _laneSwitchCooldownMax;
      _afkCheckTimer = 0; // Manuel gecis AFK timer'i sifirla
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
