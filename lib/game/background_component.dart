import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

// ── PNG Parallax Katman Konfigürasyonları ────────────────────────────────────

class _LayerDef {
  const _LayerDef(this.file, this.scrollSpeed);
  final String file;
  final double scrollSpeed; // piksel/sn (oyun koordinatlarında)
}

class _PngBgConfig {
  const _PngBgConfig({
    required this.folder,
    required this.frameW,
    required this.frameH,
    required this.layers,
  });
  final String folder;
  final double frameW;
  final double frameH;
  final List<_LayerDef> layers;
}

// worldId → PNG konfigürasyonu
const _kPngBgConfigs = <int, _PngBgConfig>{
  1: _PngBgConfig(
    folder: 'backgrounds/world1',
    frameW: 272,
    frameH: 160,
    layers: [
      _LayerDef('0_back_trees.png', 12.0),
      _LayerDef('1_mid_trees.png', 24.0),
      _LayerDef('2_lights.png', 4.0),
      _LayerDef('3_front_trees.png', 48.0),
    ],
  ),
  2: _PngBgConfig(
    folder: 'backgrounds/world2',
    frameW: 384,
    frameH: 216,
    layers: [
      _LayerDef('0.png', 4.0),
      _LayerDef('1.png', 6.0),
      _LayerDef('2.png', 10.0),
      _LayerDef('3.png', 14.0),
      _LayerDef('4.png', 20.0),
      _LayerDef('5.png', 28.0),
      _LayerDef('6.png', 36.0),
      _LayerDef('7.png', 48.0),
    ],
  ),
  4: _PngBgConfig(
    folder: 'backgrounds/world4',
    frameW: 384,
    frameH: 216,
    layers: [
      _LayerDef('0.png', 4.0),
      _LayerDef('1.png', 8.0),
      _LayerDef('2.png', 14.0),
      _LayerDef('3.png', 22.0),
      _LayerDef('4.png', 34.0),
      _LayerDef('5.png', 50.0),
    ],
  ),
};

class _PngLayer {
  _PngLayer({required this.image, required this.scrollSpeed});
  final ui.Image image;
  final double scrollSpeed;
  double offset = 0;
}

// ── Programatik arka plan renk paleti ────────────────────────────────────────

class WorldTheme {
  const WorldTheme({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.mountainColor,
    required this.treeFarColor,
    required this.treeNearColor,
    required this.groundColor,
    required this.groundLineColor,
    required this.particleColor,
    required this.fogColor,
    required this.lightRayColor,
  });

  final ui.Color skyTop;
  final ui.Color skyMid;
  final ui.Color skyBottom;
  final ui.Color mountainColor;
  final ui.Color treeFarColor;
  final ui.Color treeNearColor;
  final ui.Color groundColor;
  final ui.Color groundLineColor;
  final ui.Color particleColor;
  final ui.Color fogColor;
  final ui.Color lightRayColor;

  static WorldTheme forWorld(int worldId) {
    return switch (worldId) {
      1 => _world1,
      2 => _world2,
      3 => _world3,
      4 => _world4,
      5 => _world5,
      _ => _world1,
    };
  }

  // Dünya 1 — Kayın Vadisi
  static const _world1 = WorldTheme(
    skyTop: ui.Color(0xFF1A1240),
    skyMid: ui.Color(0xFF2D1B5E),
    skyBottom: ui.Color(0xFF4A2C3A),
    mountainColor: ui.Color(0xFF1E2D1E),
    treeFarColor: ui.Color(0xFF1A2E1A),
    treeNearColor: ui.Color(0xFF0F1A0F),
    groundColor: ui.Color(0xFF0D1A0D),
    groundLineColor: ui.Color(0xFF1E3A1E),
    particleColor: ui.Color(0xFFD4A843),
    fogColor: ui.Color(0x22A0B4C8),
    lightRayColor: ui.Color(0x15FFD700),
  );

  // Dünya 2 — Kör Mağaralar
  static const _world2 = WorldTheme(
    skyTop: ui.Color(0xFF0A0A0A),
    skyMid: ui.Color(0xFF1A0A08),
    skyBottom: ui.Color(0xFF2A1008),
    mountainColor: ui.Color(0xFF1A0808),
    treeFarColor: ui.Color(0xFF200808),
    treeNearColor: ui.Color(0xFF150505),
    groundColor: ui.Color(0xFF0F0808),
    groundLineColor: ui.Color(0xFF3A1010),
    particleColor: ui.Color(0xFFFF4500),
    fogColor: ui.Color(0x22FF200A),
    lightRayColor: ui.Color(0x15FF6030),
  );

  // Dünya 3 — Sarıkum Denizi
  static const _world3 = WorldTheme(
    skyTop: ui.Color(0xFF1A0A00),
    skyMid: ui.Color(0xFF3D1A00),
    skyBottom: ui.Color(0xFF7A3A00),
    mountainColor: ui.Color(0xFF5A2800),
    treeFarColor: ui.Color(0xFF3D1E00),
    treeNearColor: ui.Color(0xFF2A1400),
    groundColor: ui.Color(0xFF3D2200),
    groundLineColor: ui.Color(0xFF6B3A00),
    particleColor: ui.Color(0xFFFFAA00),
    fogColor: ui.Color(0x22FFB060),
    lightRayColor: ui.Color(0x20FF8800),
  );

  // Dünya 4 — Ayaz Doruk
  static const _world4 = WorldTheme(
    skyTop: ui.Color(0xFF0A1830),
    skyMid: ui.Color(0xFF1A3050),
    skyBottom: ui.Color(0xFF2A4870),
    mountainColor: ui.Color(0xFF2A4060),
    treeFarColor: ui.Color(0xFF1E3850),
    treeNearColor: ui.Color(0xFF152840),
    groundColor: ui.Color(0xFF1E3A5A),
    groundLineColor: ui.Color(0xFF4A7AAA),
    particleColor: ui.Color(0xFFE0F4FF),
    fogColor: ui.Color(0x33C0E0FF),
    lightRayColor: ui.Color(0x15FFFFFF),
  );

  // Dünya 5 — Andar Ocakları
  static const _world5 = WorldTheme(
    skyTop: ui.Color(0xFF0A0000),
    skyMid: ui.Color(0xFF200500),
    skyBottom: ui.Color(0xFF400A00),
    mountainColor: ui.Color(0xFF2A0800),
    treeFarColor: ui.Color(0xFF1A0500),
    treeNearColor: ui.Color(0xFF0F0300),
    groundColor: ui.Color(0xFF1A0500),
    groundLineColor: ui.Color(0xFF8B2000),
    particleColor: ui.Color(0xFFFF3000),
    fogColor: ui.Color(0x22FF1000),
    lightRayColor: ui.Color(0x20FF4400),
  );
}

// ── BackgroundComponent ───────────────────────────────────────────────────────

/// Parallax arka plan — PNG katmanları (1/2/4) veya programatik (3/5)
class BackgroundComponent extends PositionComponent {
  BackgroundComponent({
    required this.gameSize,
    required this.worldId,
  }) : super(size: gameSize, position: Vector2.zero());

  final Vector2 gameSize;
  final int worldId;

  // PNG mod
  final List<_PngLayer> _pngLayers = [];
  bool _usePng = false;

  // Programatik mod
  late WorldTheme _theme;
  double _farOffset = 0;
  double _midOffset = 0;
  double _nearOffset = 0;

  static const _particleCount = 20;
  final List<_Particle> _particles = [];
  final List<_LightRay> _lightRays = [];

  final _skyPaint = ui.Paint();
  final _mountainPaint = ui.Paint();
  final _treeFarPaint = ui.Paint();
  final _treeNearPaint = ui.Paint();
  final _groundPaint = ui.Paint();
  final _groundLinePaint = ui.Paint()..strokeWidth = 2;
  final _particlePaint = ui.Paint();
  final _fogPaint = ui.Paint();
  final _lightRayPaint = ui.Paint();
  final _pngPaint = ui.Paint();

  final _rng = math.Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final pngConfig = _kPngBgConfigs[worldId];
    if (pngConfig != null) {
      await _loadPngLayers(pngConfig);
      _usePng = true;
    }

    // Her durumda parçacıklar aktif (atmosfer için)
    _theme = WorldTheme.forWorld(worldId);
    _initPaints();
    _initParticles();
    if (!_usePng) _initLightRays();
  }

  Future<void> _loadPngLayers(_PngBgConfig config) async {
    final images = (findGame() as FlameGame).images;
    for (final layerDef in config.layers) {
      try {
        final img = await images.load('${config.folder}/${layerDef.file}');
        _pngLayers.add(_PngLayer(
          image: img,
          scrollSpeed: layerDef.scrollSpeed,
        ));
      } catch (_) {
        // Yüklenemezse atla
      }
    }
  }

  void _initPaints() {
    _mountainPaint.color = _theme.mountainColor;
    _treeFarPaint.color = _theme.treeFarColor;
    _treeNearPaint.color = _theme.treeNearColor;
    _groundPaint.color = _theme.groundColor;
    _groundLinePaint.color = _theme.groundLineColor;
    _fogPaint.color = _theme.fogColor;
    _lightRayPaint.color = _theme.lightRayColor;
  }

  void _initParticles() {
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble() * gameSize.x,
        y: _rng.nextDouble() * gameSize.y * 0.85,
        speed: 15 + _rng.nextDouble() * 30,
        drift: (_rng.nextDouble() - 0.5) * 20,
        size: 1.5 + _rng.nextDouble() * 3,
        alpha: 0.3 + _rng.nextDouble() * 0.5,
        rotation: _rng.nextDouble() * math.pi * 2,
        rotSpeed: (_rng.nextDouble() - 0.5) * 2,
      ));
    }
  }

  void _initLightRays() {
    for (int i = 0; i < 3; i++) {
      _lightRays.add(_LightRay(
        x: gameSize.x * (0.2 + i * 0.3),
        width: 20 + _rng.nextDouble() * 40,
        alpha: 0.3 + _rng.nextDouble() * 0.4,
        pulseOffset: _rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  @override
  void update(double dt) {
    if (_usePng) {
      for (final layer in _pngLayers) {
        // Tiled genişliğe göre mod al
        final tileW = layer.image.width.toDouble() *
            (gameSize.y / layer.image.height.toDouble());
        layer.offset = (layer.offset + dt * layer.scrollSpeed) % tileW;
      }
    } else {
      _farOffset = (_farOffset + dt * 8) % gameSize.x;
      _midOffset = (_midOffset + dt * 20) % gameSize.x;
      _nearOffset = (_nearOffset + dt * 45) % gameSize.x;
    }

    // Parçacık güncelle
    for (final p in _particles) {
      p.y += p.speed * dt;
      p.x += p.drift * dt;
      p.rotation += p.rotSpeed * dt;
      if (p.y > gameSize.y * 0.9) {
        p.y = -10;
        p.x = _rng.nextDouble() * gameSize.x;
      }
      if (p.x < -10) p.x = gameSize.x + 10;
      if (p.x > gameSize.x + 10) p.x = -10;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (_usePng) {
      _renderPngBackground(canvas);
    } else {
      _renderProceduralBackground(canvas);
    }

    // Parçacıklar üstte
    _renderParticles(canvas);
  }

  // ── PNG render ──────────────────────────────────────────────────────────────

  void _renderPngBackground(ui.Canvas canvas) {
    final w = gameSize.x;
    final h = gameSize.y;

    // Arka plan rengi (PNG'nin arkasında)
    _skyPaint.shader = ui.Gradient.linear(
      ui.Offset(w / 2, 0),
      ui.Offset(w / 2, h),
      [_theme.skyTop, _theme.skyBottom],
      [0.0, 1.0],
    );
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, h), _skyPaint);

    // PNG katmanları
    for (final layer in _pngLayers) {
      _renderPngLayer(canvas, layer, w, h);
    }
  }

  void _renderPngLayer(
      ui.Canvas canvas, _PngLayer layer, double w, double h) {
    final imgW = layer.image.width.toDouble();
    final imgH = layer.image.height.toDouble();
    final scale = h / imgH;
    final tileW = imgW * scale;

    final srcRect =
        ui.Rect.fromLTWH(0, 0, imgW, imgH);

    double x = -layer.offset;
    while (x < w) {
      final dstRect = ui.Rect.fromLTWH(x, 0, tileW, h);
      canvas.drawImageRect(layer.image, srcRect, dstRect, _pngPaint);
      x += tileW;
    }
  }

  // ── Programatik render ──────────────────────────────────────────────────────

  void _renderProceduralBackground(ui.Canvas canvas) {
    final w = gameSize.x;
    final h = gameSize.y;

    _skyPaint.shader = ui.Gradient.linear(
      ui.Offset(w / 2, 0),
      ui.Offset(w / 2, h * 0.75),
      [_theme.skyTop, _theme.skyMid, _theme.skyBottom],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, h), _skyPaint);

    _renderLightRays(canvas, w, h);
    _renderMountains(canvas, w, h, _farOffset * 0.3);
    _renderTrees(canvas, w, h, _farOffset, _treeFarPaint, 0.45, 0.12, 6);
    _renderTrees(canvas, w, h, _midOffset, _treeNearPaint, 0.62, 0.18, 4);
    _renderFog(canvas, w, h);
    _renderGround(canvas, w, h);
  }

  void _renderLightRays(ui.Canvas canvas, double w, double h) {
    for (final ray in _lightRays) {
      final pulse = 0.7 + 0.3 * math.sin(ray.pulseOffset);
      _lightRayPaint.color = ui.Color.fromARGB(
        (ray.alpha * pulse * 40).toInt().clamp(0, 255),
        (_theme.lightRayColor.r * 255).toInt(),
        (_theme.lightRayColor.g * 255).toInt(),
        (_theme.lightRayColor.b * 255).toInt(),
      );
      final path = ui.Path()
        ..moveTo(ray.x - ray.width * 0.3, 0)
        ..lineTo(ray.x + ray.width * 0.3, 0)
        ..lineTo(ray.x + ray.width * 0.8, h * 0.7)
        ..lineTo(ray.x - ray.width * 0.8, h * 0.7)
        ..close();
      canvas.drawPath(path, _lightRayPaint);
      ray.pulseOffset += 0.008;
    }
  }

  void _renderMountains(
      ui.Canvas canvas, double w, double h, double offset) {
    final baseY = h * 0.42;
    final path = ui.Path();
    path.moveTo(0, h);
    for (int tile = -1; tile <= 2; tile++) {
      final ox = tile * w - offset;
      path.lineTo(ox + w * 0.0, baseY + h * 0.05);
      path.lineTo(ox + w * 0.12, baseY - h * 0.08);
      path.lineTo(ox + w * 0.22, baseY + h * 0.02);
      path.lineTo(ox + w * 0.35, baseY - h * 0.12);
      path.lineTo(ox + w * 0.48, baseY + h * 0.03);
      path.lineTo(ox + w * 0.60, baseY - h * 0.06);
      path.lineTo(ox + w * 0.72, baseY + h * 0.01);
      path.lineTo(ox + w * 0.85, baseY - h * 0.10);
      path.lineTo(ox + w * 1.0, baseY + h * 0.04);
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, _mountainPaint);
  }

  void _renderTrees(
    ui.Canvas canvas,
    double w,
    double h,
    double offset,
    ui.Paint paint,
    double baseYRatio,
    double heightRatio,
    int treeCount,
  ) {
    final baseY = h * baseYRatio;
    final treeH = h * heightRatio;
    final spacing = w / treeCount;
    for (int tile = -1; tile <= 2; tile++) {
      for (int i = 0; i < treeCount; i++) {
        final cx = tile * w + i * spacing + spacing * 0.5 - offset;
        _drawKayinTree(canvas, cx, baseY, treeH, paint);
      }
    }
  }

  void _drawKayinTree(
      ui.Canvas canvas, double cx, double baseY, double h, ui.Paint paint) {
    final trunkW = h * 0.08;
    final crownR = h * 0.45;
    canvas.drawRect(
      ui.Rect.fromLTWH(cx - trunkW / 2, baseY - h * 0.6, trunkW, h * 0.6),
      paint,
    );
    canvas.drawCircle(ui.Offset(cx, baseY - h * 0.65), crownR, paint);
    canvas.drawCircle(
        ui.Offset(cx + crownR * 0.4, baseY - h * 0.55), crownR * 0.6, paint);
  }

  void _renderFog(ui.Canvas canvas, double w, double h) {
    _fogPaint.shader = ui.Gradient.linear(
      ui.Offset(0, h * 0.55),
      ui.Offset(0, h * 0.72),
      [
        ui.Color.fromARGB(0, (_theme.fogColor.r * 255).toInt(),
            (_theme.fogColor.g * 255).toInt(), (_theme.fogColor.b * 255).toInt()),
        _theme.fogColor,
        ui.Color.fromARGB(0, (_theme.fogColor.r * 255).toInt(),
            (_theme.fogColor.g * 255).toInt(), (_theme.fogColor.b * 255).toInt()),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(ui.Rect.fromLTWH(0, h * 0.55, w, h * 0.2), _fogPaint);
  }

  void _renderGround(ui.Canvas canvas, double w, double h) {
    final groundY = h * 0.72;
    _groundPaint.shader = ui.Gradient.linear(
      ui.Offset(0, groundY),
      ui.Offset(0, h),
      [_theme.groundLineColor, _theme.groundColor],
      [0.0, 1.0],
    );
    canvas.drawRect(
        ui.Rect.fromLTWH(0, groundY, w, h - groundY), _groundPaint);
    canvas.drawLine(
      ui.Offset(0, groundY),
      ui.Offset(w, groundY),
      _groundLinePaint,
    );
  }

  void _renderParticles(ui.Canvas canvas) {
    for (final p in _particles) {
      final alpha = (p.alpha * 200).toInt().clamp(0, 255);
      _particlePaint.color = ui.Color.fromARGB(
        alpha,
        (_theme.particleColor.r * 255).toInt(),
        (_theme.particleColor.g * 255).toInt(),
        (_theme.particleColor.b * 255).toInt(),
      );
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      canvas.drawOval(
        ui.Rect.fromCenter(
            center: ui.Offset.zero, width: p.size * 2, height: p.size),
        _particlePaint,
      );
      canvas.restore();
    }
  }
}

// ── Yardımcı sınıflar ────────────────────────────────────────────────────────

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.drift,
    required this.size,
    required this.alpha,
    required this.rotation,
    required this.rotSpeed,
  });
  double x, y, speed, drift, size, alpha, rotation, rotSpeed;
}

class _LightRay {
  _LightRay({
    required this.x,
    required this.width,
    required this.alpha,
    required this.pulseOffset,
  });
  double x, width, alpha, pulseOffset;
}
