import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../models/enums.dart';
import '../models/stats.dart';
import '../services/combat_service.dart';

/// Oyuncunun kahraman componenti — placeholder renkli dikdortgen
class HeroComponent extends PositionComponent {
  HeroComponent({
    required this.heroClass,
    required this.heroStats,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(40, 60),
          anchor: Anchor.center,
        ) {
    _maxHp = heroStats.hp;
    _currentHp = _maxHp;
    _attackInterval = CombatService.attackInterval(heroStats.spd);
  }

  final HeroClass heroClass;
  final Stats heroStats;

  late final double _maxHp;
  late double _currentHp;
  late final double _attackInterval;
  double _attackTimer = 0;
  bool _isAttacking = false;
  double _attackAnimTimer = 0;
  double _originX = 0;

  double _idleTimer = 0;
  double _baseY = 0;

  double? _targetY;
  static const _laneTransitionSpeed = 600.0;

  bool isDead = false;

  double get hpPercent => _currentHp / _maxHp;
  double get currentHp => _currentHp;
  double get maxHp => _maxHp;

  /// Disaridan hasar al
  void takeDamage(double amount) {
    _currentHp = (_currentHp - amount).clamp(0, _maxHp);
    if (_currentHp <= 0) isDead = true;
  }

  /// Lifesteal ile can yenile
  void heal(double amount) {
    if (isDead) return;
    _currentHp = (_currentHp + amount).clamp(0, _maxHp);
  }

  /// Otomatik saldiri zamanlayicisi — true donerse saldirmali
  bool updateAttack(double dt) {
    if (isDead) return false;
    _attackTimer += dt;
    if (_attackTimer >= _attackInterval) {
      _attackTimer = 0;
      _isAttacking = true;
      _attackAnimTimer = 0;
      return true;
    }
    return false;
  }

  ui.Color get _color => switch (heroClass) {
        HeroClass.kalkanEr => const ui.Color(0xFF1565C0),
        HeroClass.kurtBoru => const ui.Color(0xFFC62828),
        HeroClass.kam => const ui.Color(0xFF6A1B9A),
        HeroClass.yayCi => const ui.Color(0xFF2E7D32),
        HeroClass.golgeBek => const ui.Color(0xFF4A148C),
      };

  @override
  void onMount() {
    super.onMount();
    _baseY = position.y;
    _originX = position.x;
  }

  void moveTo(double targetY) {
    _targetY = targetY;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) return;

    // Saldiri animasyonu
    if (_isAttacking) {
      _attackAnimTimer += dt;
      if (_attackAnimTimer < 0.1) {
        position.x = _originX + (_attackAnimTimer / 0.1) * 20; // ileri atil
      } else if (_attackAnimTimer < 0.2) {
        position.x = _originX + (1 - (_attackAnimTimer - 0.1) / 0.1) * 20; // geri don
      } else {
        position.x = _originX; // tam sifirla — kayma olmaz
        _isAttacking = false;
      }
    }

    if (_targetY != null) {
      final diff = _targetY! - position.y;
      if (diff.abs() < 2) {
        position.y = _targetY!;
        _baseY = _targetY!;
        _targetY = null;
      } else {
        final step = _laneTransitionSpeed * dt;
        position.y += diff.sign * step.clamp(0, diff.abs());
      }
    } else if (!_isAttacking) {
      _idleTimer += dt;
      position.y = _baseY + 3 * math.sin(_idleTimer * 3);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (isDead) return;

    final paint = ui.Paint()..color = _color;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(0, 0, size.x, size.y),
        const ui.Radius.circular(6),
      ),
      paint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: heroClass.name[0].toUpperCase(),
        style: const TextStyle(
          color: ui.Color(0xFFFFFFFF),
          fontSize: 20,
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
  }
}
