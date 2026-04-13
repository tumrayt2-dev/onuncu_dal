import 'dart:ui' as ui;

/// Combo meter — kesintisiz hasar combo sayaci
class ComboService {
  int _combo = 0;
  double _timer = 0;
  static const _timeout = 3.0; // 3sn hasar vermezsen sifirlanir

  int get combo => _combo;

  /// Hasar verildiginde cagrilir
  void onHit() {
    _combo++;
    _timer = 0;
  }

  /// Her frame guncelle. Timeout olursa sifirlar.
  void update(double dt) {
    if (_combo == 0) return;
    _timer += dt;
    if (_timer >= _timeout) {
      _combo = 0;
      _timer = 0;
    }
  }

  /// Combo hasar bonusu carpani (1.0 = bonus yok)
  double get damageMultiplier {
    if (_combo >= 50) return 1.20;
    if (_combo >= 20) return 1.15;
    if (_combo >= 10) return 1.10;
    if (_combo >= 5) return 1.05;
    return 1.0;
  }

  /// Combo XP bonusu carpani
  double get xpMultiplier {
    if (_combo >= 50) return 1.15;
    if (_combo >= 20) return 1.10;
    if (_combo >= 10) return 1.05;
    return 1.0;
  }

  /// Combo gold bonusu carpani
  double get goldMultiplier {
    if (_combo >= 50) return 1.10;
    if (_combo >= 20) return 1.05;
    return 1.0;
  }

  /// Combo rengi: beyaz->yesil->mavi->mor->altin
  ui.Color get color {
    if (_combo >= 50) return const ui.Color(0xFFFFD700); // altin
    if (_combo >= 20) return const ui.Color(0xFF9C27B0); // mor
    if (_combo >= 10) return const ui.Color(0xFF2196F3); // mavi
    if (_combo >= 5) return const ui.Color(0xFF4CAF50); // yesil
    return const ui.Color(0xFFFFFFFF); // beyaz
  }

  /// Combo etiket metni
  String get bonusLabel {
    if (_combo >= 50) return '+%20 DMG +%15 XP +%10 G';
    if (_combo >= 20) return '+%15 DMG +%10 XP +%5 G';
    if (_combo >= 10) return '+%10 DMG +%5 XP';
    if (_combo >= 5) return '+%5 DMG';
    return '';
  }

  void reset() {
    _combo = 0;
    _timer = 0;
  }
}
