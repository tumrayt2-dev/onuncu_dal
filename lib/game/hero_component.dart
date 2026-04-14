import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/stats.dart';
import '../services/combat_service.dart';

/// Her sınıfın renk paleti
class _HeroPalette {
  const _HeroPalette({
    required this.skin,
    required this.armor,
    required this.armorDark,
    required this.weapon,
    required this.accent,
    required this.eyes,
  });

  final ui.Color skin;
  final ui.Color armor;
  final ui.Color armorDark;
  final ui.Color weapon;
  final ui.Color accent;
  final ui.Color eyes;

  static _HeroPalette forClass(HeroClass c) => switch (c) {
        HeroClass.kalkanEr => const _HeroPalette(
            skin: ui.Color(0xFFD4956A),
            armor: ui.Color(0xFF2A4A8A),       // Mavi kalkan zırhı
            armorDark: ui.Color(0xFF1A2E5A),
            weapon: ui.Color(0xFFC0C8D8),       // Gümüş kılıç
            accent: ui.Color(0xFFFFD700),        // Altın detay
            eyes: ui.Color(0xFF4090FF),
          ),
        HeroClass.kurtBoru => const _HeroPalette(
            skin: ui.Color(0xFFD4956A),
            armor: ui.Color(0xFF7A1A1A),        // Kan kırmızı
            armorDark: ui.Color(0xFF4A0A0A),
            weapon: ui.Color(0xFFB04020),        // Turuncu pençe
            accent: ui.Color(0xFFFF4422),
            eyes: ui.Color(0xFFFF2200),          // Kızıl göz
          ),
        HeroClass.kam => const _HeroPalette(
            skin: ui.Color(0xFFD4956A),
            armor: ui.Color(0xFF4A2080),        // Mor kaftan
            armorDark: ui.Color(0xFF2A0E50),
            weapon: ui.Color(0xFF8040C0),        // Mor asa
            accent: ui.Color(0xFFAA60FF),
            eyes: ui.Color(0xFFCC88FF),          // Mor göz
          ),
        HeroClass.yayCi => const _HeroPalette(
            skin: ui.Color(0xFFD4956A),
            armor: ui.Color(0xFF2A5A20),        // Orman yeşili
            armorDark: ui.Color(0xFF1A3A10),
            weapon: ui.Color(0xFF8B5A2B),        // Ahşap yay
            accent: ui.Color(0xFF88CC44),
            eyes: ui.Color(0xFF44BB22),          // Yeşil göz
          ),
        HeroClass.golgeBek => const _HeroPalette(
            skin: ui.Color(0xFFB07850),          // Biraz esmer
            armor: ui.Color(0xFF1A1A2A),        // Siyah-lacivert
            armorDark: ui.Color(0xFF0A0A14),
            weapon: ui.Color(0xFF607070),        // Koyu gümüş hançer
            accent: ui.Color(0xFF8888CC),
            eyes: ui.Color(0xFF6666CC),          // Gri-mor göz
          ),
      };
}

/// Nadirlik renginden zırh/silah tonu hesaplar
ui.Color _blendColors(ui.Color base, ui.Color overlay, double t) {
  return Color.lerp(base, overlay, t) ?? base;
}

/// Oyuncunun kahraman componenti — programatik insan silueti
class HeroComponent extends PositionComponent {
  HeroComponent({
    required this.heroClass,
    required this.heroStats,
    required Vector2 position,
    Map<EquipmentSlot, Item>? equipment,
  }) : _equipment = equipment ?? {},
       super(
          position: position,
          size: Vector2(44, 66),
          anchor: Anchor.center,
        ) {
    _maxHp = heroStats.hp;
    _currentHp = _maxHp;
    _attackInterval = CombatService.attackInterval(heroStats.spd);
    _palette = _HeroPalette.forClass(heroClass);
    _weaponRarity = _equipment[EquipmentSlot.weapon]?.rarity;
    _armorRarity = _equipment[EquipmentSlot.chest]?.rarity ??
        _equipment[EquipmentSlot.helmet]?.rarity;
    _initPaints();
  }

  final HeroClass heroClass;
  final Stats heroStats;
  final Map<EquipmentSlot, Item> _equipment;
  late final Rarity? _weaponRarity;
  late final Rarity? _armorRarity;

  late final _HeroPalette _palette;
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

  double gameSpeed = 1.0;
  bool isDead = false;

  // Paint cache
  late final ui.Paint _skinPaint;
  late final ui.Paint _armorPaint;
  late final ui.Paint _armorDarkPaint;
  late final ui.Paint _weaponPaint;
  late final ui.Paint _accentPaint;
  late final ui.Paint _eyePaint;
  late final ui.Paint _eyeWhitePaint;
  late final ui.Paint _outlinePaint;
  final ui.Paint _damagePaint = ui.Paint()
    ..color = const ui.Color(0x44FF0000);

  bool _isDamaged = false;
  double _damageTimer = 0;

  double get hpPercent => _currentHp / _maxHp;
  double get currentHp => _currentHp;
  double get maxHp => _maxHp;

  void _initPaints() {
    _skinPaint = ui.Paint()..color = _palette.skin;

    // Zırh rengi: sınıf rengi + kuşanılan zırh nadirliği karışımı
    final armorBase = _palette.armor;
    final armorDarkBase = _palette.armorDark;
    if (_armorRarity != null) {
      final rarityColor = ui.Color(_armorRarity.colorHex);
      _armorPaint = ui.Paint()
        ..color = _blendColors(armorBase, rarityColor, 0.40);
      _armorDarkPaint = ui.Paint()
        ..color = _blendColors(armorDarkBase, rarityColor, 0.25);
    } else {
      _armorPaint = ui.Paint()..color = armorBase;
      _armorDarkPaint = ui.Paint()..color = armorDarkBase;
    }

    // Silah rengi: doğrudan nadirlik rengi (slota özel, sınıf tarzı korunur)
    if (_weaponRarity != null) {
      _weaponPaint = ui.Paint()..color = ui.Color(_weaponRarity.colorHex);
    } else {
      _weaponPaint = ui.Paint()..color = _palette.weapon;
    }

    _accentPaint = ui.Paint()..color = _palette.accent;
    _eyePaint = ui.Paint()..color = _palette.eyes;
    _eyeWhitePaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    _outlinePaint = ui.Paint()
      ..color = const ui.Color(0x33000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
  }

  void takeDamage(double amount) {
    _currentHp = (_currentHp - amount).clamp(0, _maxHp);
    if (_currentHp <= 0) isDead = true;
    _isDamaged = true;
    _damageTimer = 0.15;
  }

  void heal(double amount) {
    if (isDead) return;
    _currentHp = (_currentHp + amount).clamp(0, _maxHp);
  }

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
    final sDt = dt * gameSpeed;

    if (isDead) return;

    if (_isDamaged) {
      _damageTimer -= sDt;
      if (_damageTimer <= 0) _isDamaged = false;
    }

    if (_isAttacking) {
      _attackAnimTimer += sDt;
      if (_attackAnimTimer < 0.1) {
        position.x = _originX + (_attackAnimTimer / 0.1) * 22;
      } else if (_attackAnimTimer < 0.2) {
        position.x = _originX + (1 - (_attackAnimTimer - 0.1) / 0.1) * 22;
      } else {
        position.x = _originX;
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
        final step = _laneTransitionSpeed * sDt;
        position.y += diff.sign * step.clamp(0, diff.abs());
      }
    } else if (!_isAttacking) {
      _idleTimer += sDt;
      // Nefes alma hareketi
      position.y = _baseY + 2 * math.sin(_idleTimer * 2.5);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (isDead) return;

    // Saldırı animasyonu sırasında hafif eğim
    final attackLean = _isAttacking
        ? math.sin(_attackAnimTimer * math.pi / 0.2) * 0.15
        : 0.0;

    // Nefes alma: gövde hafif büyür
    final breathScale = 1.0 + 0.02 * math.sin(_idleTimer * 2.5);

    // Rare+ silahlar için parlayan renk efekti (shimmer)
    if (_weaponRarity != null && _weaponRarity.index >= Rarity.rare.index) {
      final shimmer = 0.75 + 0.25 * math.sin(_idleTimer * 4.0);
      final base = ui.Color(_weaponRarity.colorHex);
      _weaponPaint.color = base.withValues(alpha: shimmer);
    }

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    if (attackLean != 0) canvas.rotate(attackLean);
    canvas.translate(-size.x / 2, -size.y / 2);

    // Sınıfa özel render
    switch (heroClass) {
      case HeroClass.kalkanEr:
        _renderKalkanEr(canvas, breathScale);
      case HeroClass.kurtBoru:
        _renderKurtBoru(canvas, breathScale);
      case HeroClass.kam:
        _renderKam(canvas, breathScale);
      case HeroClass.yayCi:
        _renderYayCi(canvas, breathScale);
      case HeroClass.golgeBek:
        _renderGolgeBek(canvas, breathScale);
    }

    // Hasar flash
    if (_isDamaged) {
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, size.x, size.y),
        _damagePaint,
      );
    }

    canvas.restore();
  }

  // ─── KalkanEr: Geniş omuzlu tank, kalkan + kısa kılıç ───

  void _renderKalkanEr(ui.Canvas canvas, double breathScale) {
    final w = size.x;
    final h = size.y;

    // Bacaklar
    _drawLeg(canvas, w * 0.3, h * 0.68, w * 0.18, h * 0.30, false);
    _drawLeg(canvas, w * 0.7, h * 0.68, w * 0.18, h * 0.30, false);

    // Gövde (zırh — geniş)
    final bodyRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(w * 0.12, h * 0.32, w * 0.76, h * 0.38 * breathScale),
      const ui.Radius.circular(5),
    );
    canvas.drawRRect(bodyRect, _armorPaint);
    canvas.drawRRect(bodyRect, _outlinePaint);

    // Göğüs plakası
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(w * 0.22, h * 0.34, w * 0.56, h * 0.20),
        const ui.Radius.circular(3),
      ),
      _armorDarkPaint,
    );

    // Omuz plakaları
    _drawShoulderPlate(canvas, w * 0.05, h * 0.30, true);
    _drawShoulderPlate(canvas, w * 0.70, h * 0.30, false);

    // Sol kol: kalkan tutuyor
    _drawArm(canvas, w * 0.08, h * 0.35, w * 0.12, h * 0.60, _armorPaint);

    // Sağ kol: kılıç tutuyor (saldırıda öne uzar)
    final swordExtend = _isAttacking ? h * 0.08 : 0.0;
    _drawArm(canvas, w * 0.82, h * 0.35, w * 0.88, h * 0.58 + swordExtend, _armorPaint);

    // Kafa
    _drawHead(canvas, w * 0.5, h * 0.20, h * 0.22);

    // Miğfer
    canvas.drawArc(
      ui.Rect.fromCenter(center: ui.Offset(w * 0.5, h * 0.18), width: h * 0.26, height: h * 0.20),
      math.pi, math.pi, false, _armorPaint,
    );

    // Kalkan (sol)
    _drawShield(canvas, w * 0.00, h * 0.38);

    // Kılıç (sağ)
    _drawSword(canvas, w * 0.84, h * 0.40 + swordExtend * 0.5);
  }

  void _drawShoulderPlate(ui.Canvas canvas, double x, double y, bool left) {
    final path = ui.Path()
      ..moveTo(x, y)
      ..lineTo(x + (left ? 18 : -18), y)
      ..lineTo(x + (left ? 14 : -14), y + 12)
      ..lineTo(x + (left ? 2 : -2), y + 12)
      ..close();
    canvas.drawPath(path, _accentPaint);
    canvas.drawPath(path, _outlinePaint);
  }

  void _drawShield(ui.Canvas canvas, double x, double y) {
    final path = ui.Path()
      ..moveTo(x + 6, y)
      ..lineTo(x + 18, y)
      ..lineTo(x + 18, y + 20)
      ..quadraticBezierTo(x + 12, y + 28, x + 6, y + 20)
      ..close();
    canvas.drawPath(path, _armorDarkPaint);
    canvas.drawPath(path, _outlinePaint);
    // Kalkan üstü accent çizgi
    canvas.drawLine(
      ui.Offset(x + 12, y + 4),
      ui.Offset(x + 12, y + 18),
      _accentPaint..strokeWidth = 1.5,
    );
  }

  void _drawSword(ui.Canvas canvas, double x, double y) {
    // Namlu
    canvas.drawRect(
      ui.Rect.fromLTWH(x, y, 4, 18),
      _weaponPaint,
    );
    // Koruyucu
    canvas.drawRect(
      ui.Rect.fromLTWH(x - 3, y + 18, 10, 3),
      _accentPaint,
    );
  }

  // ─── KurtBoru: Öne eğik, agresif duruş, pençeler ───

  void _renderKurtBoru(ui.Canvas canvas, double breathScale) {
    final w = size.x;
    final h = size.y;

    // Bacaklar (hafif öne eğimli)
    _drawLeg(canvas, w * 0.28, h * 0.65, w * 0.17, h * 0.32, true);
    _drawLeg(canvas, w * 0.68, h * 0.65, w * 0.17, h * 0.32, true);

    // Gövde
    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(0.12); // Öne eğik
    canvas.translate(-w * 0.5, -h * 0.5);

    final bodyRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(w * 0.18, h * 0.30, w * 0.64, h * 0.36 * breathScale),
      const ui.Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, _armorPaint);

    // Kafa
    _drawHead(canvas, w * 0.5, h * 0.18, h * 0.21);

    canvas.restore();

    // Kollar (pençe pozisyonu — öne uzanmış)
    final clawExtend = _isAttacking ? h * 0.10 : 0.0;
    _drawArm(canvas, w * 0.10, h * 0.32, w * 0.02, h * 0.55 + clawExtend, _armorPaint);
    _drawArm(canvas, w * 0.90, h * 0.32, w * 0.98, h * 0.55 + clawExtend, _armorPaint);

    // Pençeler
    _drawClaw(canvas, w * 0.00, h * 0.55 + clawExtend);
    _drawClaw(canvas, w * 0.84, h * 0.55 + clawExtend);

    // Gözler kırmızı
    _eyePaint.color = _palette.eyes;
  }

  void _drawClaw(ui.Canvas canvas, double x, double y) {
    for (int i = 0; i < 3; i++) {
      final cx = x + i * 5.0 + 2;
      canvas.drawLine(
        ui.Offset(cx, y),
        ui.Offset(cx - 2, y + 8),
        _weaponPaint..strokeWidth = 2,
      );
    }
  }

  // ─── Kam: Uzun kaftan, asa, büyü pozu ───

  void _renderKam(ui.Canvas canvas, double breathScale) {
    final w = size.x;
    final h = size.y;

    // Uzun kaftan (etek)
    final robe = ui.Path()
      ..moveTo(w * 0.18, h * 0.35)
      ..lineTo(w * 0.82, h * 0.35)
      ..lineTo(w * 0.90, h * 0.92)
      ..lineTo(w * 0.10, h * 0.92)
      ..close();
    canvas.drawPath(robe, _armorPaint);
    canvas.drawPath(robe, _outlinePaint);

    // Kaftan detay (orta çizgi)
    canvas.drawLine(
      ui.Offset(w * 0.5, h * 0.35),
      ui.Offset(w * 0.5, h * 0.88),
      _accentPaint..strokeWidth = 1.5,
    );

    // Kollar (açık — büyü pozu)
    final armY = h * 0.42 + 3 * math.sin(_idleTimer * 2.5);
    final magicExtend = _isAttacking ? -h * 0.06 : 0.0;
    _drawArm(canvas, w * 0.18, h * 0.36, w * 0.02, armY + magicExtend, _armorDarkPaint);
    _drawArm(canvas, w * 0.82, h * 0.36, w * 0.98, armY + magicExtend, _armorDarkPaint);

    // Kafa
    _drawHead(canvas, w * 0.5, h * 0.20, h * 0.21);

    // Başlık / şapka
    final hat = ui.Path()
      ..moveTo(w * 0.28, h * 0.10)
      ..lineTo(w * 0.72, h * 0.10)
      ..lineTo(w * 0.60, h * 0.00)
      ..lineTo(w * 0.40, h * 0.00)
      ..close();
    canvas.drawPath(hat, _armorDarkPaint);

    // Asa (sağ el)
    _drawStaff(canvas, w * 0.88, h * 0.30);

    // Saldırıda orb efekti
    if (_isAttacking) {
      _accentPaint.color = _palette.accent.withAlpha(200);
      canvas.drawCircle(ui.Offset(w * 0.02, h * 0.42 + magicExtend), 6, _accentPaint);
      canvas.drawCircle(ui.Offset(w * 0.98, h * 0.42 + magicExtend), 6, _accentPaint);
    }
  }

  void _drawStaff(ui.Canvas canvas, double x, double y) {
    // Sopa
    canvas.drawRect(
      ui.Rect.fromLTWH(x, y, 3.5, 34),
      _weaponPaint,
    );
    // Kristal baş
    final crystal = ui.Path()
      ..moveTo(x + 1.75, y - 10)
      ..lineTo(x + 6, y - 2)
      ..lineTo(x + 1.75, y + 2)
      ..lineTo(x - 2.5, y - 2)
      ..close();
    canvas.drawPath(crystal, _accentPaint);
  }

  // ─── YayCı: Yan duruş, yay geren pozisyon ───

  void _renderYayCi(ui.Canvas canvas, double breathScale) {
    final w = size.x;
    final h = size.y;

    // Yan duruş için hafif döndür
    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.scale(0.88, 1.0); // Yan görünüm için daralt
    canvas.translate(-w * 0.5, -h * 0.5);

    // Bacaklar
    _drawLeg(canvas, w * 0.35, h * 0.66, w * 0.18, h * 0.30, false);
    _drawLeg(canvas, w * 0.65, h * 0.66, w * 0.18, h * 0.30, false);

    // Gövde
    final bodyRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(w * 0.20, h * 0.30, w * 0.60, h * 0.36 * breathScale),
      const ui.Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, _armorPaint);

    // Kollar
    final drawExtend = _isAttacking ? h * 0.06 : 0.0;
    _drawArm(canvas, w * 0.20, h * 0.34, w * 0.05, h * 0.52 + drawExtend, _armorPaint);
    _drawArm(canvas, w * 0.80, h * 0.34, w * 0.95, h * 0.46, _armorPaint);

    // Kafa
    _drawHead(canvas, w * 0.5, h * 0.18, h * 0.21);

    canvas.restore();

    // Yay
    _drawBow(canvas, w * 0.06, h * 0.28, _isAttacking);

    // Ok (saldırıda fırlıyor)
    if (!_isAttacking) {
      canvas.drawRect(
        ui.Rect.fromLTWH(w * 0.10, h * 0.46, 16, 2),
        _weaponPaint,
      );
    }
  }

  void _drawBow(ui.Canvas canvas, double x, double y, bool drawn) {
    final tension = drawn ? 6.0 : 0.0;
    final path = ui.Path()
      ..moveTo(x + 4, y)
      ..quadraticBezierTo(x - 4 + tension, y + 14, x + 4, y + 28);
    canvas.drawPath(path, _weaponPaint..strokeWidth = 2.5..style = ui.PaintingStyle.stroke);
    // Kirişi
    canvas.drawLine(ui.Offset(x + 4, y), ui.Offset(x + 4 - tension, y + 14), _accentPaint..strokeWidth = 1);
    canvas.drawLine(ui.Offset(x + 4 - tension, y + 14), ui.Offset(x + 4, y + 28), _accentPaint..strokeWidth = 1);
    _weaponPaint.style = ui.PaintingStyle.fill;
  }

  // ─── GölgeBek: Çömük, iki hançer ───

  void _renderGolgeBek(ui.Canvas canvas, double breathScale) {
    final w = size.x;
    final h = size.y;

    // Çömük duruş — biraz aşağı
    canvas.save();
    canvas.translate(w * 0.5, h * 0.55);
    canvas.scale(1.0, 0.88);
    canvas.translate(-w * 0.5, -h * 0.55);

    // Bacaklar (çömük açık)
    _drawLeg(canvas, w * 0.25, h * 0.60, w * 0.18, h * 0.30, false);
    _drawLeg(canvas, w * 0.75, h * 0.60, w * 0.18, h * 0.30, false);

    // Gövde
    final bodyRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(w * 0.20, h * 0.30, w * 0.60, h * 0.32 * breathScale),
      const ui.Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, _armorPaint);

    // Kapüşon / pelerin
    final hood = ui.Path()
      ..moveTo(w * 0.14, h * 0.18)
      ..lineTo(w * 0.86, h * 0.18)
      ..lineTo(w * 0.80, h * 0.42)
      ..lineTo(w * 0.20, h * 0.42)
      ..close();
    canvas.drawPath(hood, _armorDarkPaint);

    // Kollar (öne uzanmış)
    final dashExtend = _isAttacking ? h * 0.08 : 0.0;
    _drawArm(canvas, w * 0.20, h * 0.33, w * 0.04, h * 0.54 + dashExtend, _armorPaint);
    _drawArm(canvas, w * 0.80, h * 0.33, w * 0.96, h * 0.54 + dashExtend, _armorPaint);

    // Kafa (kapüşon altında)
    _drawHead(canvas, w * 0.5, h * 0.18, h * 0.19);

    canvas.restore();

    // Hançerler
    final daggerExtend = _isAttacking ? h * 0.08 : 0.0;
    _drawDagger(canvas, w * 0.00, h * 0.52 + daggerExtend, true);
    _drawDagger(canvas, w * 0.82, h * 0.52 + daggerExtend, false);
  }

  void _drawDagger(ui.Canvas canvas, double x, double y, bool left) {
    final dir = left ? 1.0 : -1.0;
    // Namlu
    final blade = ui.Path()
      ..moveTo(x + dir * 2, y)
      ..lineTo(x + dir * 8, y + 3)
      ..lineTo(x + dir * 2, y + 14)
      ..close();
    canvas.drawPath(blade, _weaponPaint);
    // Sapı
    canvas.drawRect(
      ui.Rect.fromLTWH(x + dir * 0, y + 12, 5, 4),
      _accentPaint,
    );
  }

  // ─── Ortak yardımcı çizimler ───

  void _drawHead(ui.Canvas canvas, double cx, double cy, double size) {
    // Kafa oval
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(cx, cy),
        width: size * 0.80,
        height: size,
      ),
      _skinPaint,
    );
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(cx, cy),
        width: size * 0.80,
        height: size,
      ),
      _outlinePaint,
    );

    // Gözler
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(cx - size * 0.16, cy - size * 0.04),
        width: size * 0.14,
        height: size * 0.10,
      ),
      _eyeWhitePaint,
    );
    canvas.drawCircle(
      ui.Offset(cx - size * 0.15, cy - size * 0.04),
      size * 0.04,
      _eyePaint,
    );

    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(cx + size * 0.16, cy - size * 0.04),
        width: size * 0.14,
        height: size * 0.10,
      ),
      _eyeWhitePaint,
    );
    canvas.drawCircle(
      ui.Offset(cx + size * 0.15, cy - size * 0.04),
      size * 0.04,
      _eyePaint,
    );
  }

  void _drawArm(ui.Canvas canvas, double x1, double y1, double x2, double y2, ui.Paint paint) {
    canvas.drawLine(
      ui.Offset(x1, y1),
      ui.Offset(x2, y2),
      paint
        ..strokeWidth = 6
        ..style = ui.PaintingStyle.stroke,
    );
    paint.style = ui.PaintingStyle.fill;
  }

  void _drawLeg(ui.Canvas canvas, double cx, double topY, double w, double h, bool bent) {
    // Uyluk
    canvas.drawRect(
      ui.Rect.fromLTWH(cx - w / 2, topY, w, h * 0.5),
      _armorDarkPaint,
    );
    // Baldır (hafif offset ile daha doğal)
    final offset = bent ? w * 0.15 : 0.0;
    canvas.drawRect(
      ui.Rect.fromLTWH(cx - w / 2 + offset, topY + h * 0.5, w * 0.85, h * 0.5),
      _armorDarkPaint,
    );
    // Ayak
    canvas.drawRect(
      ui.Rect.fromLTWH(cx - w / 2 + offset - 1, topY + h - 2, w + 2, 4),
      _armorPaint,
    );
  }
}
