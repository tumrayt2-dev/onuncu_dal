import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart';
import '../models/enemy.dart';
import '../models/enums.dart';
import '../services/combat_service.dart';

// ── Sprite konfigürasyon ─────────────────────────────────────────────────────

class _AnimDef {
  const _AnimDef(this.file, this.frames, {this.stepTime = 0.1});
  final String file;
  final int frames;
  final double stepTime;
}

class _SpriteConfig {
  const _SpriteConfig({
    required this.folder,
    required this.frameSize,
    required this.idle,
    this.walk,
    required this.attack,
    required this.hit,
    required this.death,
  });
  final String folder;
  final double frameSize;
  final _AnimDef idle;
  final _AnimDef? walk;
  final _AnimDef attack;
  final _AnimDef hit;
  final _AnimDef death;
}

const _kSpriteConfigs = <String, _SpriteConfig>{
  'goblin': _SpriteConfig(
    folder: 'enemies/world1/goblin', frameSize: 150,
    idle: _AnimDef('idle', 4),
    walk: _AnimDef('run', 8),
    attack: _AnimDef('attack', 8, stepTime: 0.083),
    hit: _AnimDef('hit', 4),
    death: _AnimDef('death', 4, stepTime: 0.12),
  ),
  'mushroom': _SpriteConfig(
    folder: 'enemies/world1/mushroom', frameSize: 150,
    idle: _AnimDef('idle', 4),
    walk: _AnimDef('run', 8),
    attack: _AnimDef('attack', 8, stepTime: 0.083),
    hit: _AnimDef('hit', 4),
    death: _AnimDef('death', 4, stepTime: 0.12),
  ),
  'skeleton': _SpriteConfig(
    folder: 'enemies/world1/skeleton', frameSize: 150,
    idle: _AnimDef('idle', 4),
    walk: _AnimDef('walk', 4),
    attack: _AnimDef('attack', 8, stepTime: 0.083),
    hit: _AnimDef('hit', 4),
    death: _AnimDef('death', 4, stepTime: 0.12),
  ),
  'flying_eye': _SpriteConfig(
    folder: 'enemies/world1/flying_eye', frameSize: 150,
    idle: _AnimDef('flight', 8),
    attack: _AnimDef('attack', 8, stepTime: 0.083),
    hit: _AnimDef('hit', 4),
    death: _AnimDef('death', 4, stepTime: 0.12),
  ),
  'bat': _SpriteConfig(
    folder: 'enemies/world1/bat', frameSize: 64,
    idle: _AnimDef('idle', 9),
    walk: _AnimDef('run', 8),
    attack: _AnimDef('attack', 8, stepTime: 0.083),
    hit: _AnimDef('hit', 5),
    death: _AnimDef('death', 12, stepTime: 0.083),
  ),
};

// ── Animasyon durumu ─────────────────────────────────────────────────────────

enum _AnimState { idle, walking, attacking, hit, dying }

// ── EnemyComponent ───────────────────────────────────────────────────────────

class EnemyComponent extends PositionComponent {
  EnemyComponent({
    required Enemy enemyData,
    required Vector2 position,
    required int stageId,
    required Lane lane,
  }) : super(
          position: position,
          size: Vector2(240, 240),
          anchor: Anchor.center,
        ) {
    _init(enemyData, stageId, lane);
  }

  late Enemy _enemyData;
  late int _stageId;
  late Lane _lane;

  late double _maxHp;
  late double _currentHp;
  late double _atkScaled;
  late double _defScaled;
  late double _attackInterval;
  double _attackTimer = 0;
  bool _isAttacking = false;
  double _attackAnimTimer = 0;

  bool isDead = false;
  bool _dying = false;
  double _deathTimer = 0;
  static const _deathDuration = 0.5;

  double gameSpeed = 1.0;

  Enemy get enemyData => _enemyData;
  int get stageId => _stageId;
  Lane get lane => _lane;

  // ── Sprite state ───────────────────────────────────────────────────────────
  bool _spritesLoaded = false;
  _AnimState _animState = _AnimState.idle;
  final Map<_AnimState, SpriteAnimationTicker?> _tickers = {};
  SpriteAnimationTicker? _currentTicker;

  double _hitTimer = 0;
  static const _hitDuration = 0.25;

  void _init(Enemy enemy, int stage, Lane l) {
    _enemyData = enemy;
    _stageId = stage;
    _lane = l;
    _maxHp = _calculateHp();
    _currentHp = _maxHp;
    _atkScaled = enemy.baseStats.atk * math.pow(1.06, stage - 1);
    _defScaled = enemy.baseStats.def * math.pow(1.04, stage - 1);
    _attackInterval = CombatService.attackInterval(enemy.baseStats.spd);
    _attackTimer = 0;
    _isAttacking = false;
    _attackAnimTimer = 0;
    isDead = false;
    _dying = false;
    _deathTimer = 0;
  }

  void _resetAnim() {
    _hitTimer = 0;
    _animState = _AnimState.walking; // force switch
    _setAnimState(_AnimState.idle);
  }

  void reset({
    required Enemy enemyData,
    required Vector2 pos,
    required int stageId,
    required Lane lane,
  }) {
    final oldSpriteId = _enemyData.spriteId;
    position.setFrom(pos);
    _init(enemyData, stageId, lane);
    _resetAnim();

    final newSpriteId = _enemyData.spriteId;
    if (newSpriteId != oldSpriteId) {
      _spritesLoaded = false;
      _tickers.clear();
      _currentTicker = null;
      if (newSpriteId != null) {
        final g = findGame();
        if (g is FlameGame) _loadSprites(newSpriteId, g.images);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final spriteId = _enemyData.spriteId;
    if (spriteId == null) return;
    final g = findGame();
    if (g is! FlameGame) return;
    await _loadSprites(spriteId, g.images);
  }

  Future<void> _loadSprites(String spriteId, Images images) async {
    final config = _kSpriteConfigs[spriteId];
    if (config == null) return;

    Future<SpriteAnimationTicker?> load(_AnimDef def,
        {bool loop = true}) async {
      try {
        final img = await images.load('${config.folder}/${def.file}.png');
        final anim = SpriteAnimation.fromFrameData(
          img,
          SpriteAnimationData.sequenced(
            amount: def.frames,
            stepTime: def.stepTime,
            textureSize: Vector2.all(config.frameSize),
            loop: loop,
          ),
        );
        return SpriteAnimationTicker(anim);
      } catch (_) {
        return null;
      }
    }

    final idle = await load(config.idle);
    if (idle == null) return;

    _tickers[_AnimState.idle] = idle;
    _tickers[_AnimState.walking] =
        config.walk != null ? await load(config.walk!) ?? idle : idle;
    _tickers[_AnimState.attacking] =
        await load(config.attack, loop: false) ?? idle;
    _tickers[_AnimState.hit] = await load(config.hit, loop: false) ?? idle;
    _tickers[_AnimState.dying] =
        await load(config.death, loop: false) ?? idle;

    _spritesLoaded = true;
    _animState = _AnimState.walking;
    _currentTicker = null;
    _setAnimState(_AnimState.idle);
  }

  void _setAnimState(_AnimState state) {
    if (_animState == state && _currentTicker != null) return;
    _animState = state;
    final t = _tickers[state];
    t?.reset();
    _currentTicker = t;
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  static const _moveSpeed = 60.0;
  static const _attackRange = 100.0;

  double get hpPercent => _currentHp / _maxHp;
  double get currentHp => _currentHp;
  double get scaledAtk => _atkScaled;
  double get scaledDef => _defScaled;

  double _calculateHp() =>
      enemyData.baseStats.hp * math.pow(1.08, stageId - 1);

  bool get isBufferOrHealer =>
      enemyData.archetype == EnemyArchetype.buffer ||
      enemyData.archetype == EnemyArchetype.caster;

  // ── Hasar ─────────────────────────────────────────────────────────────────

  void takeDamage(double amount) {
    _currentHp = (_currentHp - amount).clamp(0, _maxHp);
    if (_spritesLoaded && _animState != _AnimState.dying) {
      _hitTimer = 0;
      _setAnimState(_AnimState.hit);
    }
    if (_currentHp <= 0 && !_dying) {
      _dying = true;
      _deathTimer = 0;
      if (_spritesLoaded) {
        _animState = _AnimState.idle; // force
        _setAnimState(_AnimState.dying);
      }
    }
  }

  // ── AI ────────────────────────────────────────────────────────────────────

  bool updateAI(double dt, double heroX, Lane heroLane) {
    if (isDead || _dying) return false;

    final dist = position.x - heroX;
    if (dist > _attackRange) {
      position.x -= _moveSpeed * dt;
      if (position.x < heroX + _attackRange * 0.5) {
        position.x = heroX + _attackRange * 0.5;
      }
      if (_spritesLoaded &&
          _animState != _AnimState.attacking &&
          _animState != _AnimState.hit) {
        _setAnimState(_AnimState.walking);
      }
      return false;
    }

    if (position.x < heroX) position.x = heroX + _attackRange * 0.5;

    if (_spritesLoaded && _animState == _AnimState.walking) {
      _setAnimState(_AnimState.idle);
    }

    if (_isAttacking) return false;
    _attackTimer += dt;
    if (_attackTimer >= _attackInterval) {
      _attackTimer = 0;
      _isAttacking = true;
      _attackAnimTimer = 0;
      if (_spritesLoaded) _setAnimState(_AnimState.attacking);
      return true;
    }
    return false;
  }

  // ── Update ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    final sDt = dt * gameSpeed;

    _currentTicker?.update(sDt);

    // Hit animasyonu
    if (_animState == _AnimState.hit) {
      _hitTimer += sDt;
      if (_hitTimer >= _hitDuration ||
          (_currentTicker?.isLastFrame ?? false)) {
        _hitTimer = 0;
        if (!_dying) {
          _animState = _AnimState.walking;
          _setAnimState(_AnimState.idle);
        }
      }
    }

    // Saldırı animasyonu bitti mi?
    if (_animState == _AnimState.attacking &&
        (_currentTicker?.isLastFrame ?? false)) {
      _isAttacking = false;
      if (!_dying) {
        _animState = _AnimState.walking;
        _setAnimState(_AnimState.idle);
      }
    }

    // Saldırı pozisyon animasyonu
    if (_isAttacking) {
      _attackAnimTimer += sDt;
      if (_attackAnimTimer < 0.1) {
        position.x -= 150 * sDt;
      } else if (_attackAnimTimer < 0.2) {
        position.x += 150 * sDt;
      } else {
        _isAttacking = false;
        if (_spritesLoaded && !_dying) {
          _animState = _AnimState.walking;
          _setAnimState(_AnimState.idle);
        }
      }
    }

    // Ölüm
    if (_dying) {
      _deathTimer += sDt;
      if (_spritesLoaded && _animState != _AnimState.dying) {
        _animState = _AnimState.idle;
        _setAnimState(_AnimState.dying);
      }
      if (_deathTimer >= _deathDuration) isDead = true;
    }
  }

  // ── Render ────────────────────────────────────────────────────────────────

  @override
  void render(ui.Canvas canvas) {
    if (isDead) return;

    if (_spritesLoaded && _currentTicker != null) {
      _renderSprite(canvas);
    } else {
      _renderFallback(canvas);
    }

    if (!_dying) _renderHpBar(canvas);
  }

  void _renderSprite(ui.Canvas canvas) {
    final sprite = _currentTicker!.getSprite();
    final dst = ui.Rect.fromLTWH(0, 0, size.x, size.y);

    // Ölüm fade-out
    double alpha = 1.0;
    if (_dying) {
      alpha = (1.0 - _deathTimer / _deathDuration).clamp(0.0, 1.0);
    }

    final isHit = _animState == _AnimState.hit;

    // Hit flash için offscreen layer: sadece opak pikseller tintlenir,
    // şeffaf alan kırmızı kareye dönüşmez
    if (isHit) canvas.saveLayer(dst, ui.Paint());

    final paint = ui.Paint();
    if (alpha < 1.0) {
      paint.color = ui.Color.fromARGB((alpha * 255).toInt(), 255, 255, 255);
    }

    // Yatay flip (düşmanlar sola doğru yürür)
    canvas.save();
    canvas.translate(size.x, 0);
    canvas.scale(-1.0, 1.0);
    canvas.drawImageRect(sprite.image, sprite.src, dst, paint);
    canvas.restore();

    if (isHit) {
      // multiply: siyah/şeffaf pikseller etkilenmez, karakter kırmızı tintlenir
      final t = (_hitTimer / _hitDuration).clamp(0.0, 1.0);
      final flashA = ((1.0 - t) * 160).toInt();
      canvas.drawRect(
        dst,
        ui.Paint()
          ..color = ui.Color.fromARGB(flashA, 255, 50, 50)
          ..blendMode = ui.BlendMode.srcATop,
      );
      canvas.restore(); // saveLayer'ı kapat
    }
  }

  void _renderFallback(ui.Canvas canvas) {
    // Sprite'sız düşmanlar: bileşen boyutunun ~1/3'ü kadar ortalanmış şekil
    const charW = 72.0;
    const charH = 96.0;
    final ox = (size.x - charW) / 2;
    final oy = (size.y - charH) / 2;

    double scale = 1.0;
    double alpha = 1.0;
    if (_dying) {
      final t = (_deathTimer / _deathDuration).clamp(0.0, 1.0);
      scale = 1.0 - t * 0.5;
      alpha = 1.0 - t;
    }

    canvas.save();
    if (_dying) {
      canvas.translate(size.x / 2, size.y / 2);
      canvas.scale(scale, scale);
      canvas.translate(-size.x / 2, -size.y / 2);
    }

    // Gövde
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(ox, oy + charH * 0.25, charW, charH * 0.75),
        const ui.Radius.circular(5),
      ),
      ui.Paint()..color = _archetypeColor.withValues(alpha: alpha),
    );

    // Kafa
    canvas.drawCircle(
      ui.Offset(ox + charW / 2, oy + charH * 0.15),
      charW * 0.22,
      ui.Paint()
        ..color = _archetypeColor.withValues(alpha: alpha * 0.8),
    );

    // Baş harf
    final textPainter = TextPainter(
      text: TextSpan(
        text: enemyData.archetype.name[0].toUpperCase(),
        style: TextStyle(
          color: ui.Color.fromARGB((255 * alpha).toInt(), 255, 255, 255),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      ui.Offset(
        ox + (charW - textPainter.width) / 2,
        oy + charH * 0.35 + (charH * 0.65 - textPainter.height) / 2,
      ),
    );

    canvas.restore();
  }

  void _renderHpBar(ui.Canvas canvas) {
    const barW = 80.0;
    const barH = 6.0;
    final barX = (size.x - barW) / 2;
    final barY = size.y - 12.0;

    // Arka plan
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(barX, barY, barW, barH),
        const ui.Radius.circular(3),
      ),
      ui.Paint()..color = const ui.Color(0xAA222222),
    );
    // Dolum
    final fillW = (barW * hpPercent).clamp(0.0, barW);
    if (fillW > 0) {
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(barX, barY, fillW, barH),
          const ui.Radius.circular(3),
        ),
        ui.Paint()
          ..color = ui.Color.lerp(
            const ui.Color(0xFFFF2222),
            const ui.Color(0xFF44FF44),
            hpPercent,
          )!,
      );
    }
  }

  ui.Color get _archetypeColor => switch (enemyData.archetype) {
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
}
