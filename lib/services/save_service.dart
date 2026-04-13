import 'package:hive/hive.dart';
import '../models/enums.dart';
import '../models/hero_character.dart';
import '../data/json_loader.dart';

/// Hive tabanlı kayıt servisi
class SaveService {
  SaveService._();
  static final instance = SaveService._();

  static const _boxName = 'player';
  static const _backupBoxName = 'player_backup';
  static const _heroKey = 'hero';

  Box<dynamic>? _box;
  Box<dynamic>? _backupBox;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _backupBox = await Hive.openBox(_backupBoxName);
  }

  /// Yeni oyuncu oluştur
  Future<HeroCharacter> createNewPlayer(
    HeroClass heroClass,
    String name,
  ) async {
    final heroId = _heroClassToId(heroClass);
    final baseStats = JsonLoader.instance.getHeroBaseStats(heroId);

    final hero = HeroCharacter(
      id: heroId,
      name: name,
      heroClass: heroClass,
      baseStats: baseStats,
      level: 1,
      xp: 0,
      statPoints: 0,
      skillPoints: 0,
      gold: 100, // başlangıç altını
      gems: 0,
    );

    await savePlayer(hero);
    return hero;
  }

  /// Kayıtlı oyuncuyu yükle
  HeroCharacter? loadPlayer() {
    final box = _box;
    if (box == null || !box.containsKey(_heroKey)) return null;

    try {
      final data = box.get(_heroKey);
      if (data is Map) {
        return HeroCharacter.fromJson(
          _castDeep(data),
        );
      }
      return null;
    } catch (_) {
      return _tryLoadBackup();
    }
  }

  /// Oyuncuyu kaydet (auto-save)
  Future<void> savePlayer(HeroCharacter hero) async {
    final json = hero.toJson();
    // Önce backup
    await _backupBox?.put(_heroKey, json);
    // Sonra ana kayıt
    await _box?.put(_heroKey, json);
  }

  /// Kayıtı sil
  Future<void> deletePlayer() async {
    await _box?.delete(_heroKey);
    await _backupBox?.delete(_heroKey);
  }

  /// Kayıt var mı?
  bool hasSave() {
    return _box?.containsKey(_heroKey) ?? false;
  }

  /// Backup'tan kurtarma
  HeroCharacter? _tryLoadBackup() {
    try {
      final data = _backupBox?.get(_heroKey);
      if (data is Map) {
        return HeroCharacter.fromJson(_castDeep(data));
      }
    } catch (_) {
      // Her iki kayıt da bozuk
    }
    return null;
  }

  String _heroClassToId(HeroClass heroClass) {
    return switch (heroClass) {
      HeroClass.kalkanEr => 'kalkan_er',
      HeroClass.kurtBoru => 'kurt_boru',
      HeroClass.kam => 'kam',
      HeroClass.yayCi => 'yay_ci',
      HeroClass.golgeBek => 'golge_bek',
    };
  }

  Map<String, dynamic> _castDeep(Map<dynamic, dynamic> raw) {
    return raw.map((key, value) {
      final k = key.toString();
      if (value is Map) {
        return MapEntry(k, _castDeep(value));
      } else if (value is List) {
        return MapEntry(
          k,
          value.map((e) => e is Map ? _castDeep(e) : e).toList(),
        );
      }
      return MapEntry(k, value);
    });
  }
}
