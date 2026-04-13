import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../models/enemy.dart';
import '../models/enums.dart';
import '../services/combat_service.dart';

/// Dusman componenti — tum seritlerde hareket eder
class EnemyComponent extends PositionComponent {
  EnemyComponent({
    required this.enemyData,
    required Vector2 position,
    required this.stageId,
    required this.lane,
  }) : super(
          position: position,
          size: Vector2(36, 50),
          anchor: Anchor.center,
        ) {
    _maxHp = _calculateHp();
    _currentHp = _maxHp;
    _atkScaled = enemyData.baseStats.atk * math.pow(1.06, stageId - 1);
    _defScaled = enemyData.baseStats.def * math.pow(1.04, stageId - 1);
    _attackInterval = CombatService.attackInterval(enemyData.baseStats.spd);
  }

  final Enemy enemyData;
  final int stageId;
  final Lane lane;

  late final double _maxHp;
  late double _currentHp;
  late final double _atkScaled;
  late final double _defScaled;
  late final double _attackInterval;
  double _attackTimer = 0;
  bool _isAttacking = false;
  double _attackAnimTimer = 0;

  bool isDead = false;
  bool _dying = false;
  double _deathTimer = 0;
  static const _deathDuration = 0.4;

  /// Hareket hizi (piksel/sn)
  static const _moveSpeed = 60.0;

  /// Saldiri menzili (piksel) — ana serit
  static const _attackRange = 100.0;

  double get hpPercent => _currentHp / _maxHp;
  double get currentHp => _currentHp;
  double get scaledAtk => _atkScaled;
  double get scaledDef => _defScaled;

  double _calculateHp() {
    return enemyData.baseStats.hp * math.pow(1.08, stageId - 1);
  }

  void takeDamage(double amount) {
    _currentHp = (_currentHp - amount).clamp(0, _maxHp);
    if (_currentHp <= 0 && !_dying) {
      _dying = true;
      _deathTimer = 0;
    }
  }

  /// TUM seritlerde hero'ya dogru yuru.
  /// Menzile girince dur ve saldir.
  /// Ana serit: tam hasar. Yan serit: hasar cagiran taraf x0.5 uygular.
  bool updateAI(double dt, double heroX, Lane heroLane) {
    if (isDead || _dying) return false;

    final dist = position.x - heroX;

    // Menzile girmemisse yuru (tum seritler)
    if (dist > _attackRange) {
      position.x -= _moveSpeed * dt;
      // Hero'yu gecmesini engelle
      if (position.x < heroX + _attackRange * 0.5) {
        position.x = heroX + _attackRange * 0.5;
      }
      return false;
    }
    // Menzildeyken de gecmesini engelle
    if (position.x < heroX) {
      position.x = heroX + _attackRange * 0.5;
    }

    // Menzilde — dur ve saldir
    if (_isAttacking) return false; // animasyon sirasinda tekrar saldirma
    _attackTimer += dt;
    if (_attackTimer >= _attackInterval) {
      _attackTimer = 0;
      _isAttacking = true;
      _attackAnimTimer = 0;
      return true;
    }
    return false;
  }

  /// Buffer/healer mob mu?
  bool get isBufferOrHealer =>
      enemyData.archetype == EnemyArchetype.buffer ||
      enemyData.archetype == EnemyArchetype.caster;

  ui.Color get _color => switch (enemyData.archetype) {
        EnemyArchetype.melee => const ui.Color(0xFF8B0000),
        EnemyArchetype.caster => const ui.Color(0xFF4B0082),
        EnemyArchetype.fast => const ui.Color(0xFFFF8C00),
        EnemyArchetype.pack => const ui.Color(0xFF556B2F),
        EnemyArchetype.tank => const ui.Color(0xFF2F4F4F),
        EnemyArchetype.charger => const ui.Color(0xFF8B4513),
        EnemyArchetype.buffer => const ui.Color(0xFF9932CC),
        EnemyArchetype.flying => const ui.Color(0xFF4682B4),
        EnemyArchetype.miniBoss => const ui.Color(0xFFB22222),
        EnemyArchetype.worldBoss => const ui.Color(0xFF8B0000),
      };

  @override
  void update(double dt) {
    super.update(dt);

    // Saldiri animasyonu — sola atilip geri don
    if (_isAttacking) {
      _attackAnimTimer += dt;
      if (_attackAnimTimer < 0.1) {
        position.x -= 150 * dt;
      } else if (_attackAnimTimer < 0.2) {
        position.x += 150 * dt;
      } else {
        _isAttacking = false;
      }
    }

    if (_dying) {
      _deathTimer += dt;
      if (_deathTimer >= _deathDuration) {
        isDead = true;
        removeFromParent();
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (isDead) return;

    double deathScale = 1.0;
    double deathAlpha = 1.0;
    if (_dying) {
      final t = (_deathTimer / _deathDuration).clamp(0.0, 1.0);
      deathScale = 1.0 - t * 0.5;
      deathAlpha = 1.0 - t;
    }

    canvas.save();
    if (_dying) {
      canvas.translate(size.x / 2, size.y / 2);
      canvas.scale(deathScale, deathScale);
      canvas.translate(-size.x / 2, -size.y / 2);
    }

    final paint = ui.Paint()
      ..color = _color.withValues(alpha: deathAlpha);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(0, 0, size.x, size.y),
        const ui.Radius.circular(4),
      ),
      paint,
    );

    final letter = enemyData.archetype.name[0].toUpperCase();
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: ui.Color.fromARGB(
            (255 * deathAlpha).toInt(),
            255,
            255,
            255,
          ),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      ui.Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );

    // HP bar
    if (!_dying) {
      const barHeight = 4.0;
      const barY = -8.0;
      canvas.drawRect(
        ui.Rect.fromLTWH(0, barY, size.x, barHeight),
        ui.Paint()..color = const ui.Color(0xFF333333),
      );
      final hpColor = ui.Color.lerp(
        const ui.Color(0xFFFF0000),
        const ui.Color(0xFF00FF00),
        hpPercent,
      )!;
      canvas.drawRect(
        ui.Rect.fromLTWH(0, barY, size.x * hpPercent, barHeight),
        ui.Paint()..color = hpColor,
      );
    }

    canvas.restore();
  }
}
