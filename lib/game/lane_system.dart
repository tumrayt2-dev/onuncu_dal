import '../models/enums.dart';

/// 3 serit pozisyon yonetimi
class LaneSystem {
  LaneSystem({required this.gameHeight});

  final double gameHeight;

  /// Her seridin Y pozisyonu (ekranin ust, orta, alt bolgesi)
  double laneY(Lane lane) {
    final usable = gameHeight * 0.7; // ekranin %70'i oyun alani
    final topOffset = gameHeight * 0.1; // ustten %10 bosluk
    return switch (lane) {
      Lane.top => topOffset + usable * 0.15,
      Lane.middle => topOffset + usable * 0.50,
      Lane.bottom => topOffset + usable * 0.85,
    };
  }

  /// Dokunulan Y pozisyonuna en yakin serit
  Lane laneFromY(double y) {
    final topY = laneY(Lane.top);
    final midY = laneY(Lane.middle);
    final botY = laneY(Lane.bottom);

    final dTop = (y - topY).abs();
    final dMid = (y - midY).abs();
    final dBot = (y - botY).abs();

    if (dTop <= dMid && dTop <= dBot) return Lane.top;
    if (dMid <= dBot) return Lane.middle;
    return Lane.bottom;
  }
}
