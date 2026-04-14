import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

/// Dünya teması renk paleti
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

  /// Dünyaya göre tema seç
  static WorldTheme forWorld(int worldId) {
    return switch (worldId) {
      1 => _world1, // Kayın Vadisi
      2 => _world2, // Kör Mağaralar
      3 => _world3, // Sarıkum Denizi
      4 => _world4, // Ayaz Doruk
      5 => _world5, // Andar Ocakları
      _ => _world1,
    };
  }

  // Dünya 1 — Kayın Vadisi: Alacakaranlık orman, mavi-mor gökyüzü
  static const _world1 = WorldTheme(
    skyTop: ui.Color(0xFF1A1240),       // Koyu mor-lacivert
    skyMid: ui.Color(0xFF2D1B5E),       // Orta mor
    skyBottom: ui.Color(0xFF4A2C3A),    // Bordo-mor, ufuk
    mountainColor: ui.Color(0xFF1E2D1E), // Koyu yeşil dağ silueti
    treeFarColor: ui.Color(0xFF1A2E1A),  // Uzak kayın (koyu)
    treeNearColor: ui.Color(0xFF0F1A0F), // Yakın kayın (en koyu)
    groundColor: ui.Color(0xFF0D1A0D),   // Koyu yosunlu zemin
    groundLineColor: ui.Color(0xFF1E3A1E), // Zemin çizgisi
    particleColor: ui.Color(0xFFD4A843), // Altın yaprak/tohum
    fogColor: ui.Color(0x22A0B4C8),      // Mavi-gri sis
    lightRayColor: ui.Color(0x15FFD700), // Altın ışık huzmesi
  );

  // Dünya 2 — Kör Mağaralar: Koyu, kırmızı-turuncu kristal ışıkları
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

  // Dünya 3 — Sarıkum Denizi: Sarı-turuncu çöl, gün batımı
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

  // Dünya 4 — Ayaz Doruk: Buz mavisi, kar beyazı
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

  // Dünya 5 — Andar Ocakları: Kor kırmızı, siyah duman
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

/// Parallax arka plan — 3 katman + parçacık sistemi
class BackgroundComponent extends PositionComponent {
  BackgroundComponent({
    required this.gameSize,
    required this.worldId,
  }) : super(size: gameSize, position: Vector2.zero());

  final Vector2 gameSize;
  final int worldId;

  late WorldTheme _theme;

  // Parallax offsetleri
  double _farOffset = 0;
  double _midOffset = 0;
  double _nearOffset = 0;

  // Parçacıklar (yaprak/tohum/kar/kor)
  static const _particleCount = 25;
  final List<_Particle> _particles = [];

  // Işık huzmeleri
  final List<_LightRay> _lightRays = [];

  // Paint cache
  final _skyPaint = ui.Paint();
  final _mountainPaint = ui.Paint();
  final _treeFarPaint = ui.Paint();
  final _treeNearPaint = ui.Paint();
  final _groundPaint = ui.Paint();
  final _groundLinePaint = ui.Paint()..strokeWidth = 2;
  final _particlePaint = ui.Paint();
  final _fogPaint = ui.Paint();
  final _lightRayPaint = ui.Paint();

  final _rng = math.Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _theme = WorldTheme.forWorld(worldId);
    _initPaints();
    _initParticles();
    _initLightRays();
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
    // 3 ışık huzmesi: soldan sağa eğimli
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
    // Parallax kaydırma (farklı hızlar)
    _farOffset = (_farOffset + dt * 8) % gameSize.x;
    _midOffset = (_midOffset + dt * 20) % gameSize.x;
    _nearOffset = (_nearOffset + dt * 45) % gameSize.x;

    // Parçacık güncelle
    for (final p in _particles) {
      p.y += p.speed * dt;
      p.x += p.drift * dt;
      p.rotation += p.rotSpeed * dt;

      // Ekrandan çıkınca yukarıdan tekrar
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
    final w = gameSize.x;
    final h = gameSize.y;

    // --- Katman 1: Gökyüzü gradient ---
    _skyPaint.shader = ui.Gradient.linear(
      ui.Offset(w / 2, 0),
      ui.Offset(w / 2, h * 0.75),
      [_theme.skyTop, _theme.skyMid, _theme.skyBottom],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, h), _skyPaint);

    // --- Işık huzmeleri ---
    _renderLightRays(canvas, w, h);

    // --- Katman 2: Uzak dağ silueti (en yavaş) ---
    _renderMountains(canvas, w, h, _farOffset * 0.3);

    // --- Katman 3: Uzak ağaçlar ---
    _renderTrees(canvas, w, h, _farOffset, _treeFarPaint, 0.45, 0.12, 6);

    // --- Katman 4: Yakın ağaçlar ---
    _renderTrees(canvas, w, h, _midOffset, _treeNearPaint, 0.62, 0.18, 4);

    // --- Sis katmanı ---
    _renderFog(canvas, w, h);

    // --- Zemin ---
    _renderGround(canvas, w, h);

    // --- Parçacıklar ---
    _renderParticles(canvas);
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

      // Pulse offset zamanla değişsin
      ray.pulseOffset += 0.008;
    }
  }

  void _renderMountains(ui.Canvas canvas, double w, double h, double offset) {
    final baseY = h * 0.42;
    final path = ui.Path();
    path.moveTo(0, h);

    // Tiled dağ silueti
    for (int tile = -1; tile <= 2; tile++) {
      final ox = tile * w - offset;
      // Dağ 1
      path.lineTo(ox + w * 0.0, baseY + h * 0.05);
      path.lineTo(ox + w * 0.12, baseY - h * 0.08);
      path.lineTo(ox + w * 0.22, baseY + h * 0.02);
      // Dağ 2
      path.lineTo(ox + w * 0.35, baseY - h * 0.12);
      path.lineTo(ox + w * 0.48, baseY + h * 0.03);
      // Dağ 3
      path.lineTo(ox + w * 0.60, baseY - h * 0.06);
      path.lineTo(ox + w * 0.72, baseY + h * 0.01);
      // Dağ 4
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

  /// Kayın ağacı: beyaz ince gövde + yuvarlak tepe
  void _drawKayinTree(
    ui.Canvas canvas,
    double cx,
    double baseY,
    double h,
    ui.Paint paint,
  ) {
    final trunkW = h * 0.08;
    final crownR = h * 0.45;

    // Gövde
    canvas.drawRect(
      ui.Rect.fromLTWH(cx - trunkW / 2, baseY - h * 0.6, trunkW, h * 0.6),
      paint,
    );

    // Taç (yuvarlak)
    canvas.drawCircle(ui.Offset(cx, baseY - h * 0.65), crownR, paint);

    // Kayın'a özgü: ikinci küçük tepe
    canvas.drawCircle(
        ui.Offset(cx + crownR * 0.4, baseY - h * 0.55), crownR * 0.6, paint);
  }

  void _renderFog(ui.Canvas canvas, double w, double h) {
    // Alt kısımda sis gradyanı
    _fogPaint.shader = ui.Gradient.linear(
      ui.Offset(0, h * 0.55),
      ui.Offset(0, h * 0.72),
      [
        ui.Color.fromARGB(0, (_theme.fogColor.r * 255).toInt(), (_theme.fogColor.g * 255).toInt(), (_theme.fogColor.b * 255).toInt()),
        _theme.fogColor,
        ui.Color.fromARGB(0, (_theme.fogColor.r * 255).toInt(), (_theme.fogColor.g * 255).toInt(), (_theme.fogColor.b * 255).toInt()),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(ui.Rect.fromLTWH(0, h * 0.55, w, h * 0.2), _fogPaint);
  }

  void _renderGround(ui.Canvas canvas, double w, double h) {
    final groundY = h * 0.72;

    // Zemin gradyanı
    _groundPaint.shader = ui.Gradient.linear(
      ui.Offset(0, groundY),
      ui.Offset(0, h),
      [_theme.groundLineColor, _theme.groundColor],
      [0.0, 1.0],
    );
    canvas.drawRect(ui.Rect.fromLTWH(0, groundY, w, h - groundY), _groundPaint);

    // Zemin üst çizgisi
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

      // Yaprak: küçük elips
      canvas.drawOval(
        ui.Rect.fromCenter(
          center: ui.Offset.zero,
          width: p.size * 2,
          height: p.size,
        ),
        _particlePaint,
      );

      canvas.restore();
    }
  }
}

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
