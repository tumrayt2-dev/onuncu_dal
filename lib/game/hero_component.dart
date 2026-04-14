import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/stats.dart';
import '../services/combat_service.dart';

// ── Sprite konfigürasyon ─────────────────────────────────────────────────────

class _HeroAnimDef {
  const _HeroAnimDef(
    this.file, {
    required this.frameW,
    required this.frameH,
    required this.totalFrames,  // sheet'teki toplam frame
    this.frameStep = 1,         // her N. frame'i al (1=hepsi, 5=atlayarak)
    this.cols,                  // null = tek yatay strip
    this.stepTime = 0.1,
    this.loop = true,
    this.syncToAttack = false,  // true → stepTime = attackInterval / örnekSayısı
  });
  final String file;
  final double frameW;
  final double frameH;
  final int totalFrames;
  final int frameStep;
  final int? cols;
  final double stepTime;
  final bool loop;
  final bool syncToAttack;
}

class _HeroSpriteConfig {
  const _HeroSpriteConfig({
    required this.folder,
    required this.idle,
    this.attack,
    this.hit,
    this.flipX = false,
  });
  final String folder;
  final _HeroAnimDef idle;
  final _HeroAnimDef? attack;
  final _HeroAnimDef? hit;
  final bool flipX;
}

const _kHeroSpriteConfigs = <HeroClass, _HeroSpriteConfig>{
  // Berserker: barbarian (grid 10×6, 128×128)
  HeroClass.kurtBoru: _HeroSpriteConfig(
    folder: 'heroes/barbarian',
    flipX: true,
    idle: _HeroAnimDef('idle',
        cols: 10, frameW: 128, frameH: 128,
        totalFrames: 60, frameStep: 4, stepTime: 0.08),
    attack: _HeroAnimDef('attack',
        cols: 10, frameW: 128, frameH: 128,
        totalFrames: 100, frameStep: 7,
        loop: false, syncToAttack: true),
    hit: _HeroAnimDef('hit',
        cols: 10, frameW: 128, frameH: 128,
        totalFrames: 51, frameStep: 4, stepTime: 0.06, loop: false),
  ),
  // Kalkan+kılıç: black_knight
  HeroClass.kalkanEr: _HeroSpriteConfig(
    folder: 'heroes/black_knight',
    flipX: false,
    idle: _HeroAnimDef('idle',
        cols: 5, frameW: 112, frameH: 96,
        totalFrames: 21, frameStep: 1, stepTime: 0.083),
    attack: _HeroAnimDef('attack',
        frameW: 128, frameH: 128,
        totalFrames: 71, frameStep: 5,
        loop: false, syncToAttack: true),
  ),
};

// ── Animasyon durumu ─────────────────────────────────────────────────────────

enum _HeroAnimState { idle, attacking, hit }

// ── Renk paleti ─────────────────────────────────────────────────────────────

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
            armor: ui.Color(0xFF2A4A8A),
            armorDark: ui.Color(0xFF1A2E5A),
            weapon: ui.Color(0xFFC0C8D8),
            accent: ui.Color(0xFFFFD700),
            eyes: ui.Color(0xFF4090FF),
          ),
        HeroClass.kurtBoru => const _HeroPalette(
            skin: ui.Color(0xFFD4956A),
            armor: ui.Color(0xFF7A1A1A),
            armorDark: ui.Color(0xFF4A0A0A),
            weapon: ui.Color(0xFFB04020),
            accent: ui.Color(0xFFFF4422),
            eyes: ui.Color(0xFFFF2200),
          ),
        HeroClass.kam => const _HeroPalette(
            skin: ui.Color(0xFFD4956A),
            armor: ui.Color(0xFF4A2080),
            armorDark: ui.Color(0xFF2A0E50),
            weapon: ui.Color(0xFF8040C0),
            accent: ui.Color(0xFFAA60FF),
            eyes: ui.Color(0xFFCC88FF),
          ),
        HeroClass.yayCi => const _HeroPalette(
            skin: ui.Color(0xFFD4956A),
            armor: ui.Color(0xFF2A5A20),
            armorDark: ui.Color(0xFF1A3A10),
            weapon: ui.Color(0xFF8B5A2B),
            accent: ui.Color(0xFF88CC44),
            eyes: ui.Color(0xFF44BB22),
          ),
        HeroClass.golgeBek => const _HeroPalette(
            skin: ui.Color(0xFFB07850),
            armor: ui.Color(0xFF1A1A2A),
            armorDark: ui.Color(0xFF0A0A14),
            weapon: ui.Color(0xFF607070),
            accent: ui.Color(0xFF8888CC),
            eyes: ui.Color(0xFF6666CC),
          ),
      };
}

ui.Color _blendColors(ui.Color base, ui.Color overlay, double t) {
  return Color.lerp(base, overlay, t) ?? base;
}

// ── HeroComponent ────────────────────────────────────────────────────────────

class HeroComponent extends PositionComponent {
  HeroComponent({
    required this.heroClass,
    required this.heroStats,
    required Vector2 position,
    Map<EquipmentSlot, Item>? equipment,
  }) : _equipment = equipment ?? {},
       super(
          position: position,
          size: Vector2(160, 160),
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

  // ── Sprite alanları ───────────────────────────────────────────────────────
  bool _spritesLoaded = false;
  _HeroAnimState _animState = _HeroAnimState.idle;
  final Map<_HeroAnimState, SpriteAnimationTicker?> _tickers = {};
  SpriteAnimationTicker? _currentTicker;
  double _hitTimer = 0;
  static const _hitDuration = 0.3;

  // ── Paint cache ───────────────────────────────────────────────────────────
  late final ui.Paint _skinPaint;
  late final ui.Paint _armorPaint;
  late final ui.Paint _armorDarkPaint;
  late final ui.Paint _weaponPaint;
  late final ui.Paint _accentPaint;
  late final ui.Paint _eyePaint;
  late final ui.Paint _eyeWhitePaint;
  late final ui.Paint _outlinePaint;
  final ui.Paint _damagePaint = ui.Paint()..color = const ui.Color(0x66FF0000);

  bool _isDamaged = false;
  double _damageTimer = 0;

  double get hpPercent => _currentHp / _maxHp;
  double get currentHp => _currentHp;
  double get maxHp => _maxHp;

  void _initPaints() {
    _skinPaint = ui.Paint()..color = _palette.skin;

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

  // ── Sprite yükleme ────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final config = _kHeroSpriteConfigs[heroClass];
    if (config == null) return;
    final g = findGame();
    if (g is! FlameGame) return;
    await _loadSprites(config, g.images);
  }

  Future<void> _loadSprites(_HeroSpriteConfig config, Images images) async {
    Future<SpriteAnimationTicker?> load(_HeroAnimDef def) async {
      try {
        final img = await images.load('${config.folder}/${def.file}.png');

        // Her N. frame'in indekslerini topla
        final indices = <int>[];
        for (int i = 0; i < def.totalFrames; i += def.frameStep) {
          indices.add(i);
        }

        // stepTime: saldırı hızına eşitle ya da sabit kullan
        final st = def.syncToAttack
            ? (_attackInterval / indices.length).clamp(0.025, 0.12)
            : def.stepTime;

        // Her indeks için Sprite oluştur
        final frames = indices.map((idx) {
          final Vector2 srcPos;
          if (def.cols != null) {
            // Grid layout: satır/sütun hesapla
            srcPos = Vector2(
              (idx % def.cols!) * def.frameW,
              (idx ~/ def.cols!) * def.frameH,
            );
          } else {
            // Tek yatay strip
            srcPos = Vector2(idx * def.frameW, 0);
          }
          return SpriteAnimationFrame(
            Sprite(img,
                srcPosition: srcPos,
                srcSize: Vector2(def.frameW, def.frameH)),
            st,
          );
        }).toList();

        return SpriteAnimationTicker(
            SpriteAnimation(frames, loop: def.loop));
      } catch (_) {
        return null;
      }
    }

    final idle = await load(config.idle);
    if (idle == null) return;

    _tickers[_HeroAnimState.idle] = idle;
    _tickers[_HeroAnimState.attacking] =
        config.attack != null ? await load(config.attack!) ?? idle : idle;
    _tickers[_HeroAnimState.hit] =
        config.hit != null ? await load(config.hit!) ?? idle : idle;

    _spritesLoaded = true;
    _setHeroAnimState(_HeroAnimState.idle);
  }

  void _setHeroAnimState(_HeroAnimState state) {
    if (_animState == state && _currentTicker != null) return;
    _animState = state;
    final t = _tickers[state];
    t?.reset();
    _currentTicker = t;
  }

  // ── Hasar ve heal ─────────────────────────────────────────────────────────

  void takeDamage(double amount) {
    _currentHp = (_currentHp - amount).clamp(0, _maxHp);
    if (_currentHp <= 0) isDead = true;
    _isDamaged = true;
    _damageTimer = 0.2;
    if (_spritesLoaded && _animState != _HeroAnimState.attacking) {
      _hitTimer = 0;
      _setHeroAnimState(_HeroAnimState.hit);
    }
  }

  void heal(double amount) {
    if (isDead) return;
    _currentHp = (_currentHp + amount).clamp(0, _maxHp);
  }

  bool _attackDamageReady = false;

  /// Saldırı animasyonu son frame'e ulaştığında true döner (tek seferlik).
  /// battle_game bu getter ile damage'ı animasyon sonunda uygular.
  bool consumeAttackHit() {
    if (_attackDamageReady) {
      _attackDamageReady = false;
      return true;
    }
    return false;
  }

  /// Timer'ı ilerletir, animasyonu başlatır; damage consumeAttackHit() ile alınır.
  void updateAttack(double dt) {
    if (isDead) return;
    _attackTimer += dt;
    if (_attackTimer >= _attackInterval) {
      _attackTimer = 0;
      _isAttacking = true;
      _attackAnimTimer = 0;
      if (_spritesLoaded) {
        if (_animState != _HeroAnimState.attacking) {
          _setHeroAnimState(_HeroAnimState.attacking);
        }
        // Damage, animasyon son frame'inde consumeAttackHit() ile ateşlenecek
      } else {
        // Sprite yok — programatik animasyon, damage anında hazır
        _attackDamageReady = true;
      }
    }
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

  // ── Update ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    final sDt = dt * gameSpeed;

    if (isDead) return;

    // Sprite ticker güncelle
    _currentTicker?.update(sDt);

    // Hit animasyonu bitti mi?
    if (_animState == _HeroAnimState.hit) {
      _hitTimer += sDt;
      if (_hitTimer >= _hitDuration ||
          (_currentTicker?.isLastFrame ?? false)) {
        _hitTimer = 0;
        _setHeroAnimState(_HeroAnimState.idle);
      }
    }

    // Saldırı animasyonu son frame → damage ateşle, idle'a geç
    if (_animState == _HeroAnimState.attacking &&
        (_currentTicker?.isLastFrame ?? false)) {
      _attackDamageReady = true;
      _setHeroAnimState(_HeroAnimState.idle);
    }

    if (_isDamaged) {
      _damageTimer -= sDt;
      if (_damageTimer <= 0) _isDamaged = false;
    }

    if (_isAttacking) {
      _attackAnimTimer += sDt;
      if (_spritesLoaded) {
        // Sprite modunda: küçük ileri adım, animasyon kendi bitişini yönetir
        if (_attackAnimTimer < 0.08) {
          position.x = _originX + (_attackAnimTimer / 0.08) * 8;
        } else {
          position.x = _originX;
          _isAttacking = false; // pozisyon kilidi açılır, anim state sprite ile biter
        }
      } else {
        // Programatik mod: tam pozisyon animasyonu
        if (_attackAnimTimer < 0.1) {
          position.x = _originX + (_attackAnimTimer / 0.1) * 22;
        } else if (_attackAnimTimer < 0.2) {
          position.x = _originX + (1 - (_attackAnimTimer - 0.1) / 0.1) * 22;
        } else {
          position.x = _originX;
          _isAttacking = false;
        }
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
      position.y = _baseY + 2 * math.sin(_idleTimer * 2.5);
    }
  }

  // ── Render ────────────────────────────────────────────────────────────────

  @override
  void render(ui.Canvas canvas) {
    if (isDead) return;

    if (_spritesLoaded && _currentTicker != null) {
      _renderSprite(canvas);
    } else {
      _renderProgrammatic(canvas);
    }
  }

  void _renderSprite(ui.Canvas canvas) {
    final config = _kHeroSpriteConfigs[heroClass]!;
    final sprite = _currentTicker!.getSprite();
    final paint = ui.Paint();
    final dst = ui.Rect.fromLTWH(0, 0, size.x, size.y);

    // Hasar flash: saveLayer + multiply → sadece karakter pikselleri tintlenir
    if (_isDamaged) canvas.saveLayer(dst, ui.Paint());

    canvas.save();
    if (config.flipX) {
      canvas.translate(size.x, 0);
      canvas.scale(-1.0, 1.0);
    }
    canvas.drawImageRect(sprite.image, sprite.src, dst, paint);
    canvas.restore();

    if (_isDamaged) {
      canvas.drawRect(
        dst,
        ui.Paint()
          ..color = const ui.Color(0xAAFF3030)
          ..blendMode = ui.BlendMode.srcATop,
      );
      canvas.restore();
    }
  }

  void _renderProgrammatic(ui.Canvas canvas) {
    final attackLean = _isAttacking
        ? math.sin(_attackAnimTimer * math.pi / 0.2) * 0.15
        : 0.0;
    final breathScale = 1.0 + 0.02 * math.sin(_idleTimer * 2.5);

    if (_weaponRarity != null && _weaponRarity.index >= Rarity.rare.index) {
      final shimmer = 0.75 + 0.25 * math.sin(_idleTimer * 4.0);
      final base = ui.Color(_weaponRarity.colorHex);
      _weaponPaint.color = base.withValues(alpha: shimmer);
    }

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    if (attackLean != 0) canvas.rotate(attackLean);
    canvas.translate(-size.x / 2, -size.y / 2);

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

    if (_isDamaged) {
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, size.x, size.y),
        _damagePaint,
      );
    }

    canvas.restore();
  }

  // ─── KalkanEr ─────────────────────────────────────────────────────────────

  void _renderKalkanEr(ui.Canvas canvas, double breathScale) {
    final w = size.x;
    final h = size.y;

    _drawLeg(canvas, w * 0.3, h * 0.68, w * 0.18, h * 0.30, false);
    _drawLeg(canvas, w * 0.7, h * 0.68, w * 0.18, h * 0.30, false);

    final bodyRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(w * 0.12, h * 0.32, w * 0.76, h * 0.38 * breathScale),
      const ui.Radius.circular(5),
    );
    canvas.drawRRect(bodyRect, _armorPaint);
    canvas.drawRRect(bodyRect, _outlinePaint);

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(w * 0.22, h * 0.34, w * 0.56, h * 0.20),
        const ui.Radius.circular(3),
      ),
      _armorDarkPaint,
    );

    _drawShoulderPlate(canvas, w * 0.05, h * 0.30, true);
    _drawShoulderPlate(canvas, w * 0.70, h * 0.30, false);

    _drawArm(canvas, w * 0.08, h * 0.35, w * 0.12, h * 0.60, _armorPaint);

    final swordExtend = _isAttacking ? h * 0.08 : 0.0;
    _drawArm(canvas, w * 0.82, h * 0.35, w * 0.88, h * 0.58 + swordExtend,
        _armorPaint);

    _drawHead(canvas, w * 0.5, h * 0.20, h * 0.22);

    canvas.drawArc(
      ui.Rect.fromCenter(
          center: ui.Offset(w * 0.5, h * 0.18),
          width: h * 0.26,
          height: h * 0.20),
      math.pi, math.pi, false, _armorPaint,
    );

    _drawShield(canvas, w * 0.00, h * 0.38);
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
    canvas.drawLine(
      ui.Offset(x + 12, y + 4),
      ui.Offset(x + 12, y + 18),
      _accentPaint..strokeWidth = 1.5,
    );
  }

  void _drawSword(ui.Canvas canvas, double x, double y) {
    canvas.drawRect(ui.Rect.fromLTWH(x, y, 4, 18), _weaponPaint);
    canvas.drawRect(
        ui.Rect.fromLTWH(x - 3, y + 18, 10, 3), _accentPaint);
  }

  // ─── KurtBoru ─────────────────────────────────────────────────────────────

  void _renderKurtBoru(ui.Canvas canvas, double breathScale) {
    final w = size.x;
    final h = size.y;

    _drawLeg(canvas, w * 0.28, h * 0.65, w * 0.17, h * 0.32, true);
    _drawLeg(canvas, w * 0.68, h * 0.65, w * 0.17, h * 0.32, true);

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(0.12);
    canvas.translate(-w * 0.5, -h * 0.5);

    final bodyRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(w * 0.18, h * 0.30, w * 0.64, h * 0.36 * breathScale),
      const ui.Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, _armorPaint);
    _drawHead(canvas, w * 0.5, h * 0.18, h * 0.21);
    canvas.restore();

    final clawExtend = _isAttacking ? h * 0.10 : 0.0;
    _drawArm(canvas, w * 0.10, h * 0.32, w * 0.02, h * 0.55 + clawExtend,
        _armorPaint);
    _drawArm(canvas, w * 0.90, h * 0.32, w * 0.98, h * 0.55 + clawExtend,
        _armorPaint);
    _drawClaw(canvas, w * 0.00, h * 0.55 + clawExtend);
    _drawClaw(canvas, w * 0.84, h * 0.55 + clawExtend);
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

  // ─── Kam ──────────────────────────────────────────────────────────────────

  void _renderKam(ui.Canvas canvas, double breathScale) {
    final w = size.x;
    final h = size.y;

    final robe = ui.Path()
      ..moveTo(w * 0.18, h * 0.35)
      ..lineTo(w * 0.82, h * 0.35)
      ..lineTo(w * 0.90, h * 0.92)
      ..lineTo(w * 0.10, h * 0.92)
      ..close();
    canvas.drawPath(robe, _armorPaint);
    canvas.drawPath(robe, _outlinePaint);

    canvas.drawLine(
      ui.Offset(w * 0.5, h * 0.35),
      ui.Offset(w * 0.5, h * 0.88),
      _accentPaint..strokeWidth = 1.5,
    );

    final armY = h * 0.42 + 3 * math.sin(_idleTimer * 2.5);
    final magicExtend = _isAttacking ? -h * 0.06 : 0.0;
    _drawArm(canvas, w * 0.18, h * 0.36, w * 0.02, armY + magicExtend,
        _armorDarkPaint);
    _drawArm(canvas, w * 0.82, h * 0.36, w * 0.98, armY + magicExtend,
        _armorDarkPaint);

    _drawHead(canvas, w * 0.5, h * 0.20, h * 0.21);

    final hat = ui.Path()
      ..moveTo(w * 0.28, h * 0.10)
      ..lineTo(w * 0.72, h * 0.10)
      ..lineTo(w * 0.60, h * 0.00)
      ..lineTo(w * 0.40, h * 0.00)
      ..close();
    canvas.drawPath(hat, _armorDarkPaint);

    _drawStaff(canvas, w * 0.88, h * 0.30);

    if (_isAttacking) {
      _accentPaint.color = _palette.accent.withAlpha(200);
      canvas.drawCircle(
          ui.Offset(w * 0.02, h * 0.42 + magicExtend), 6, _accentPaint);
      canvas.drawCircle(
          ui.Offset(w * 0.98, h * 0.42 + magicExtend), 6, _accentPaint);
    }
  }

  void _drawStaff(ui.Canvas canvas, double x, double y) {
    canvas.drawRect(ui.Rect.fromLTWH(x, y, 3.5, 34), _weaponPaint);
    final crystal = ui.Path()
      ..moveTo(x + 1.75, y - 10)
      ..lineTo(x + 6, y - 2)
      ..lineTo(x + 1.75, y + 2)
      ..lineTo(x - 2.5, y - 2)
      ..close();
    canvas.drawPath(crystal, _accentPaint);
  }

  // ─── YayCı ────────────────────────────────────────────────────────────────

  void _renderYayCi(ui.Canvas canvas, double breathScale) {
    final w = size.x;
    final h = size.y;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.scale(0.88, 1.0);
    canvas.translate(-w * 0.5, -h * 0.5);

    _drawLeg(canvas, w * 0.35, h * 0.66, w * 0.18, h * 0.30, false);
    _drawLeg(canvas, w * 0.65, h * 0.66, w * 0.18, h * 0.30, false);

    final bodyRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(w * 0.20, h * 0.30, w * 0.60, h * 0.36 * breathScale),
      const ui.Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, _armorPaint);

    final drawExtend = _isAttacking ? h * 0.06 : 0.0;
    _drawArm(canvas, w * 0.20, h * 0.34, w * 0.05, h * 0.52 + drawExtend,
        _armorPaint);
    _drawArm(canvas, w * 0.80, h * 0.34, w * 0.95, h * 0.46, _armorPaint);

    _drawHead(canvas, w * 0.5, h * 0.18, h * 0.21);
    canvas.restore();

    _drawBow(canvas, w * 0.06, h * 0.28, _isAttacking);
    if (!_isAttacking) {
      canvas.drawRect(
          ui.Rect.fromLTWH(w * 0.10, h * 0.46, 16, 2), _weaponPaint);
    }
  }

  void _drawBow(ui.Canvas canvas, double x, double y, bool drawn) {
    final tension = drawn ? 6.0 : 0.0;
    final path = ui.Path()
      ..moveTo(x + 4, y)
      ..quadraticBezierTo(x - 4 + tension, y + 14, x + 4, y + 28);
    canvas.drawPath(path,
        _weaponPaint..strokeWidth = 2.5..style = ui.PaintingStyle.stroke);
    canvas.drawLine(ui.Offset(x + 4, y),
        ui.Offset(x + 4 - tension, y + 14), _accentPaint..strokeWidth = 1);
    canvas.drawLine(ui.Offset(x + 4 - tension, y + 14),
        ui.Offset(x + 4, y + 28), _accentPaint..strokeWidth = 1);
    _weaponPaint.style = ui.PaintingStyle.fill;
  }

  // ─── GölgeBek ─────────────────────────────────────────────────────────────

  void _renderGolgeBek(ui.Canvas canvas, double breathScale) {
    final w = size.x;
    final h = size.y;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.55);
    canvas.scale(1.0, 0.88);
    canvas.translate(-w * 0.5, -h * 0.55);

    _drawLeg(canvas, w * 0.25, h * 0.60, w * 0.18, h * 0.30, false);
    _drawLeg(canvas, w * 0.75, h * 0.60, w * 0.18, h * 0.30, false);

    final bodyRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(w * 0.20, h * 0.30, w * 0.60, h * 0.32 * breathScale),
      const ui.Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, _armorPaint);

    final hood = ui.Path()
      ..moveTo(w * 0.14, h * 0.18)
      ..lineTo(w * 0.86, h * 0.18)
      ..lineTo(w * 0.80, h * 0.42)
      ..lineTo(w * 0.20, h * 0.42)
      ..close();
    canvas.drawPath(hood, _armorDarkPaint);

    final dashExtend = _isAttacking ? h * 0.08 : 0.0;
    _drawArm(canvas, w * 0.20, h * 0.33, w * 0.04, h * 0.54 + dashExtend,
        _armorPaint);
    _drawArm(canvas, w * 0.80, h * 0.33, w * 0.96, h * 0.54 + dashExtend,
        _armorPaint);

    _drawHead(canvas, w * 0.5, h * 0.18, h * 0.19);
    canvas.restore();

    final daggerExtend = _isAttacking ? h * 0.08 : 0.0;
    _drawDagger(canvas, w * 0.00, h * 0.52 + daggerExtend, true);
    _drawDagger(canvas, w * 0.82, h * 0.52 + daggerExtend, false);
  }

  void _drawDagger(ui.Canvas canvas, double x, double y, bool left) {
    final dir = left ? 1.0 : -1.0;
    final blade = ui.Path()
      ..moveTo(x + dir * 2, y)
      ..lineTo(x + dir * 8, y + 3)
      ..lineTo(x + dir * 2, y + 14)
      ..close();
    canvas.drawPath(blade, _weaponPaint);
    canvas.drawRect(ui.Rect.fromLTWH(x + dir * 0, y + 12, 5, 4), _accentPaint);
  }

  // ─── Ortak yardımcılar ────────────────────────────────────────────────────

  void _drawHead(ui.Canvas canvas, double cx, double cy, double size) {
    canvas.drawOval(
      ui.Rect.fromCenter(
          center: ui.Offset(cx, cy), width: size * 0.80, height: size),
      _skinPaint,
    );
    canvas.drawOval(
      ui.Rect.fromCenter(
          center: ui.Offset(cx, cy), width: size * 0.80, height: size),
      _outlinePaint,
    );

    canvas.drawOval(
      ui.Rect.fromCenter(
          center: ui.Offset(cx - size * 0.16, cy - size * 0.04),
          width: size * 0.14,
          height: size * 0.10),
      _eyeWhitePaint,
    );
    canvas.drawCircle(
        ui.Offset(cx - size * 0.15, cy - size * 0.04), size * 0.04, _eyePaint);

    canvas.drawOval(
      ui.Rect.fromCenter(
          center: ui.Offset(cx + size * 0.16, cy - size * 0.04),
          width: size * 0.14,
          height: size * 0.10),
      _eyeWhitePaint,
    );
    canvas.drawCircle(
        ui.Offset(cx + size * 0.15, cy - size * 0.04), size * 0.04, _eyePaint);
  }

  void _drawArm(ui.Canvas canvas, double x1, double y1, double x2, double y2,
      ui.Paint paint) {
    canvas.drawLine(
      ui.Offset(x1, y1),
      ui.Offset(x2, y2),
      paint
        ..strokeWidth = 6
        ..style = ui.PaintingStyle.stroke,
    );
    paint.style = ui.PaintingStyle.fill;
  }

  void _drawLeg(ui.Canvas canvas, double cx, double topY, double w, double h,
      bool bent) {
    canvas.drawRect(
        ui.Rect.fromLTWH(cx - w / 2, topY, w, h * 0.5), _armorDarkPaint);
    final offset = bent ? w * 0.15 : 0.0;
    canvas.drawRect(
        ui.Rect.fromLTWH(cx - w / 2 + offset, topY + h * 0.5, w * 0.85, h * 0.5),
        _armorDarkPaint);
    canvas.drawRect(
        ui.Rect.fromLTWH(
            cx - w / 2 + offset - 1, topY + h - 2, w + 2, 4),
        _armorPaint);
  }
}
