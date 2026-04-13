import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/enemy.dart';
import '../models/stage.dart';
import '../models/stats.dart';

/// Tüm JSON veri dosyalarını parse eden servis.
class JsonLoader {
  JsonLoader._();

  static final instance = JsonLoader._();

  // Parsed data
  List<Map<String, dynamic>> heroes = [];
  List<Enemy> enemies = [];
  List<Enemy> bosses = [];
  List<Stage> stages = [];
  List<Map<String, dynamic>> skills = [];
  List<Map<String, dynamic>> itemsBase = [];
  List<Map<String, dynamic>> affixes = [];

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> loadAll() async {
    if (_loaded) return;

    final results = await Future.wait([
      _loadJson('assets/data/heroes.json'),
      _loadJson('assets/data/enemies_world1.json'),
      _loadJson('assets/data/bosses_world1.json'),
      _loadJson('assets/data/stages_world1.json'),
      _loadJson('assets/data/skills.json'),
      _loadJson('assets/data/items_base.json'),
      _loadJson('assets/data/affixes.json'),
    ]);

    heroes = List<Map<String, dynamic>>.from(results[0] as List);

    enemies = (results[1] as List)
        .map((e) => Enemy.fromJson(e as Map<String, dynamic>))
        .toList();

    bosses = (results[2] as List)
        .map((e) => Enemy.fromJson(_normalizeBoss(e as Map<String, dynamic>)))
        .toList();

    stages = (results[3] as List)
        .map((e) => Stage.fromJson(e as Map<String, dynamic>))
        .toList();

    skills = List<Map<String, dynamic>>.from(results[4] as List);

    itemsBase = List<Map<String, dynamic>>.from(results[5] as List);

    affixes = List<Map<String, dynamic>>.from(results[6] as List);

    _loaded = true;

    // ignore: avoid_print
    print(
      'Loaded ${heroes.length} heroes, '
      '${enemies.length} enemies, '
      '${bosses.length} bosses, '
      '${stages.length} stages, '
      '${skills.length} skills, '
      '${itemsBase.length} items, '
      '${affixes.length} affixes',
    );
  }

  /// Boss JSON'ları Enemy modeline uygun hale getir
  Map<String, dynamic> _normalizeBoss(Map<String, dynamic> raw) {
    // Boss JSON'larında baseStats içinde sadece hp/atk/def/spd olabilir
    final stats = raw['baseStats'] as Map<String, dynamic>;
    return {
      'id': raw['id'],
      'nameKey': raw['nameKey'],
      'archetype': raw['archetype'],
      'worldId': raw['worldId'],
      'lane': raw['lane'] ?? 'middle',
      'baseStats': stats,
      'lootTable': raw['lootTable'],
      'specialAbility': raw['specialAbility'],
    };
  }

  /// Hero base stats'ı Stats objesine çevir
  Stats getHeroBaseStats(String heroId) {
    if (heroes.isEmpty) return const Stats(hp: 100, atk: 10, def: 5, spd: 1.0);
    final hero = heroes.firstWhere(
      (h) => h['id'] == heroId,
      orElse: () => heroes.first,
    );
    return Stats.fromJson(hero['baseStats'] as Map<String, dynamic>);
  }

  /// Hero level-up artış oranları
  Stats getHeroPerLevel(String heroId) {
    if (heroes.isEmpty) return const Stats(hp: 10, atk: 2, def: 1, spd: 0.01);
    final hero = heroes.firstWhere(
      (h) => h['id'] == heroId,
      orElse: () => heroes.first,
    );
    return Stats.fromJson(hero['perLevel'] as Map<String, dynamic>);
  }

  Future<dynamic> _loadJson(String path) async {
    final jsonStr = await rootBundle.loadString(path);
    return json.decode(jsonStr);
  }
}
