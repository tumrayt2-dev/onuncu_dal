import 'dart:ui' as ui;

import '../models/enums.dart';

/// Sinifa ozel kaynak yonetimi
class ResourceService {
  ResourceService({required this.heroClass}) {
    _init();
  }

  final HeroClass heroClass;

  late double _current;
  late double _max;
  late ResourceType _type;
  bool _specialReady = false;
  bool _specialActive = false;
  double _specialTimer = 0;
  double _specialDuration = 0;

  double get current => _current;
  double get max => _max;
  double get percent => _current / _max;
  ResourceType get type => _type;
  bool get specialReady => _specialReady;
  bool get specialActive => _specialActive;
  double get specialTimer => _specialTimer;
  double get specialDuration => _specialDuration;

  void _init() {
    switch (heroClass) {
      case HeroClass.kalkanEr:
        _type = ResourceType.irade;
        _max = 100;
        _current = 0; // zamanla dolar (+1/sn)
      case HeroClass.kurtBoru:
        _type = ResourceType.ofke;
        _max = 100;
        _current = 0; // hasar al/ver ile dolar
      case HeroClass.kam:
        _type = ResourceType.ruh;
        _max = 150;
        _current = 0; // zamanla dolar (+3/sn)
      case HeroClass.yayCi:
        _type = ResourceType.soluk;
        _max = 80;
        _current = 0; // zamanla dolar (+2/sn)
      case HeroClass.golgeBek:
        _type = ResourceType.sir;
        _max = 5;
        _current = 0; // her vuruşta +1
    }
  }

  /// Her frame guncelle — zamanla kaynak dolumu
  void update(double dt) {
    // Special ability suresi
    if (_specialActive) {
      _specialTimer -= dt;
      if (_specialTimer <= 0) {
        _specialActive = false;
        _specialTimer = 0;
      }
    }

    // Zamanla kaynak dolumu
    switch (heroClass) {
      case HeroClass.kalkanEr:
        _current = (_current + 1 * dt).clamp(0, _max); // +1/sn
      case HeroClass.kurtBoru:
        break; // Ofke zamanla dolmaz
      case HeroClass.kam:
        _current = (_current + 3 * dt).clamp(0, _max); // +3/sn
      case HeroClass.yayCi:
        _current = (_current + 2 * dt).clamp(0, _max); // +2/sn
      case HeroClass.golgeBek:
        break; // Sir zamanla dolmaz
    }

    _checkSpecialReady();
  }

  /// Blok basarili oldu (Kalkan-Er)
  void onBlock() {
    if (heroClass == HeroClass.kalkanEr) {
      _current = (_current + 10).clamp(0, _max);
      _checkSpecialReady();
    }
  }

  /// Hasar verildi
  void onDealDamage() {
    switch (heroClass) {
      case HeroClass.kurtBoru:
        _current = (_current + 5).clamp(0, _max);
      case HeroClass.golgeBek:
        _current = (_current + 1).clamp(0, _max);
      default:
        break;
    }
    _checkSpecialReady();
  }

  /// Hasar alindi
  void onTakeDamage() {
    if (heroClass == HeroClass.kurtBoru) {
      _current = (_current + 8).clamp(0, _max);
      _checkSpecialReady();
    }
  }

  void _checkSpecialReady() {
    _specialReady = _current >= _max && !_specialActive;
  }

  /// Special ability tetikle. True donerse basarili.
  bool triggerSpecial() {
    if (!_specialReady) return false;

    _specialActive = true;
    _specialReady = false;

    switch (heroClass) {
      case HeroClass.kalkanEr:
        // 5sn hasar azaltma
        _specialDuration = 5.0;
        _specialTimer = 5.0;
        _current = 0;
      case HeroClass.kurtBoru:
        // 10sn ATK+%40
        _specialDuration = 10.0;
        _specialTimer = 10.0;
        _current = 0;
      case HeroClass.kam:
        // AoE hasar (anlik, suresi yok ama kisa flash)
        _specialDuration = 0.5;
        _specialTimer = 0.5;
        _current = 0;
      case HeroClass.yayCi:
        // Garanti CRIT (tek vurus)
        _specialDuration = 0.1;
        _specialTimer = 0.1;
        _current = 0;
      case HeroClass.golgeBek:
        // Backstab %300 hasar (tek vurus)
        _specialDuration = 0.1;
        _specialTimer = 0.1;
        _current = 0;
    }

    return true;
  }

  /// Kalkan-Er: Hasar azaltma carpani (special aktifken 0.5)
  double get damageReduction {
    if (heroClass == HeroClass.kalkanEr && _specialActive) return 0.5;
    return 1.0;
  }

  /// Kurt-Boru: ATK carpani (special aktifken 1.4)
  double get atkMultiplier {
    if (heroClass == HeroClass.kurtBoru && _specialActive) return 1.4;
    return 1.0;
  }

  /// Yay-Ci: Garanti crit mi?
  bool get guaranteedCrit {
    return heroClass == HeroClass.yayCi && _specialActive;
  }

  /// Golge-Bek: Backstab carpani
  double get backstabMultiplier {
    if (heroClass == HeroClass.golgeBek && _specialActive) return 3.0;
    return 1.0;
  }

  /// Kam: AoE hasar tetiklemeli mi?
  bool get shouldAoE {
    return heroClass == HeroClass.kam && _specialActive && _specialTimer > 0.4;
  }

  /// Kaynak rengi
  ui.Color get barColor => switch (heroClass) {
        HeroClass.kalkanEr => const ui.Color(0xFF1565C0), // mavi
        HeroClass.kurtBoru => const ui.Color(0xFFC62828), // kirmizi
        HeroClass.kam => const ui.Color(0xFF7E57C2), // mor
        HeroClass.yayCi => const ui.Color(0xFF2E7D32), // yesil
        HeroClass.golgeBek => const ui.Color(0xFF4A148C), // koyu mor
      };

  /// Kaynak key'i — UI tarafinda l10n ile cevirilir
  String get resourceKey => switch (_type) {
        ResourceType.irade => 'irade',
        ResourceType.ofke => 'ofke',
        ResourceType.ruh => 'ruh',
        ResourceType.soluk => 'soluk',
        ResourceType.sir => 'sir',
      };

  /// Special ability key'i — UI tarafinda l10n ile cevirilir
  String get specialKey => switch (heroClass) {
        HeroClass.kalkanEr => 'demirKalkan',
        HeroClass.kurtBoru => 'kurtFormu',
        HeroClass.kam => 'ruhFirtinasi',
        HeroClass.yayCi => 'kartalGoz',
        HeroClass.golgeBek => 'golgeBicagi',
      };

  void reset() {
    _init();
    _specialReady = false;
    _specialActive = false;
    _specialTimer = 0;
  }
}
