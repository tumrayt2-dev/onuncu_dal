import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Hasar/heal/miss rakamlari — yukari kayarak soner
class FloatingTextComponent extends PositionComponent {
  FloatingTextComponent({
    required this.text,
    required Vector2 position,
    this.textColor = const ui.Color(0xFFFFFFFF),
    this.fontSize = 16,
    this.duration = 0.8,
  }) : super(position: position, anchor: Anchor.center);

  final String text;
  final ui.Color textColor;
  final double fontSize;
  final double duration;

  double _elapsed = 0;

  /// Oyun hiz carpani — BattleGame tarafindan set edilir
  double gameSpeed = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    final sDt = dt * gameSpeed;
    _elapsed += sDt;
    position.y -= 40 * sDt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final opacity = (1.0 - (_elapsed / duration)).clamp(0.0, 1.0);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor.withValues(alpha: opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: const ui.Color(0xFF000000).withValues(alpha: opacity * 0.8),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      ui.Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}
