import 'dart:math' as math;

import 'enums.dart';
import 'item.dart';
import 'skill.dart';
import 'stats.dart';

/// Oyuncunun kahraman karakteri
class HeroCharacter {
  const HeroCharacter({
    required this.id,
    required this.name,
    required this.heroClass,
    this.level = 1,
    this.xp = 0,
    this.statPoints = 0,
    this.skillPoints = 0,
    required this.baseStats,
    this.equipment = const {},
    this.inventory = const [],
    this.skills = const [],
    this.gold = 0,
    this.gems = 0,
    this.soulStones = 0,
    this.essences = 0,
    this.currentStage = 1,
    this.maxStage = 1,
    this.currentWorldId = 1,
  });

  final String id;
  final String name;
  final HeroClass heroClass;
  final int level;
  final int xp;
  final int statPoints;
  final int skillPoints;
  final Stats baseStats;
  final Map<EquipmentSlot, Item> equipment;
  final List<Item> inventory;
  final List<Skill> skills;
  final int gold;
  final int gems;
  final int soulStones;
  final int essences;
  final int currentStage;
  final int maxStage;
  final int currentWorldId;

  /// Sonraki level icin gereken XP: floor(100 * pow(level, 1.6))
  int get xpToNextLevel => (100 * math.pow(level, 1.6)).floor();

  /// Level bazli efektif statlar: baseStats + (level-1) * perLevel
  /// perLevel verisi JsonLoader'dan alinir
  Stats effectiveStats(Stats perLevel) {
    final lvl = level - 1; // level 1'de bonus yok
    return Stats(
      hp: baseStats.hp + perLevel.hp * lvl,
      mp: baseStats.mp + perLevel.mp * lvl,
      atk: baseStats.atk + perLevel.atk * lvl,
      def: baseStats.def + perLevel.def * lvl,
      spd: baseStats.spd + perLevel.spd * lvl,
      crit: baseStats.crit + perLevel.crit * lvl,
      critDmg: baseStats.critDmg + perLevel.critDmg * lvl,
      dodge: baseStats.dodge + perLevel.dodge * lvl,
      block: baseStats.block + perLevel.block * lvl,
      lifesteal: baseStats.lifesteal + perLevel.lifesteal * lvl,
      hpRegen: baseStats.hpRegen + perLevel.hpRegen * lvl,
      accuracy: baseStats.accuracy + perLevel.accuracy * lvl,
      resist: baseStats.resist + perLevel.resist * lvl,
      magicFind: baseStats.magicFind + perLevel.magicFind * lvl,
    );
  }

  HeroCharacter copyWith({
    String? id,
    String? name,
    HeroClass? heroClass,
    int? level,
    int? xp,
    int? statPoints,
    int? skillPoints,
    Stats? baseStats,
    Map<EquipmentSlot, Item>? equipment,
    List<Item>? inventory,
    List<Skill>? skills,
    int? gold,
    int? gems,
    int? soulStones,
    int? essences,
    int? currentStage,
    int? maxStage,
    int? currentWorldId,
  }) {
    return HeroCharacter(
      id: id ?? this.id,
      name: name ?? this.name,
      heroClass: heroClass ?? this.heroClass,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      statPoints: statPoints ?? this.statPoints,
      skillPoints: skillPoints ?? this.skillPoints,
      baseStats: baseStats ?? this.baseStats,
      equipment: equipment ?? this.equipment,
      inventory: inventory ?? this.inventory,
      skills: skills ?? this.skills,
      gold: gold ?? this.gold,
      gems: gems ?? this.gems,
      soulStones: soulStones ?? this.soulStones,
      essences: essences ?? this.essences,
      currentStage: currentStage ?? this.currentStage,
      maxStage: maxStage ?? this.maxStage,
      currentWorldId: currentWorldId ?? this.currentWorldId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'heroClass': heroClass.name,
      'level': level,
      'xp': xp,
      'statPoints': statPoints,
      'skillPoints': skillPoints,
      'baseStats': baseStats.toJson(),
      'equipment': equipment.map(
        (k, v) => MapEntry(k.name, v.toJson()),
      ),
      'inventory': inventory.map((i) => i.toJson()).toList(),
      'skills': skills.map((s) => s.toJson()).toList(),
      'gold': gold,
      'gems': gems,
      'soulStones': soulStones,
      'essences': essences,
      'currentStage': currentStage,
      'maxStage': maxStage,
      'currentWorldId': currentWorldId,
    };
  }

  factory HeroCharacter.fromJson(Map<String, dynamic> json) {
    final equipMap = <EquipmentSlot, Item>{};
    if (json['equipment'] != null) {
      (json['equipment'] as Map<String, dynamic>).forEach((key, value) {
        equipMap[EquipmentSlot.values.byName(key)] =
            Item.fromJson(value as Map<String, dynamic>);
      });
    }

    return HeroCharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      heroClass: HeroClass.values.byName(json['heroClass'] as String),
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      statPoints: json['statPoints'] as int? ?? 0,
      skillPoints: json['skillPoints'] as int? ?? 0,
      baseStats: Stats.fromJson(json['baseStats'] as Map<String, dynamic>),
      equipment: equipMap,
      inventory: (json['inventory'] as List<dynamic>?)
              ?.map((i) => Item.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      skills: (json['skills'] as List<dynamic>?)
              ?.map((s) => Skill.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      gold: json['gold'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      soulStones: json['soulStones'] as int? ?? 0,
      essences: json['essences'] as int? ?? 0,
      currentStage: json['currentStage'] as int? ?? 1,
      maxStage: json['maxStage'] as int? ?? 1,
      currentWorldId: json['currentWorldId'] as int? ?? 1,
    );
  }

  @override
  String toString() =>
      'HeroCharacter($name, ${heroClass.name}, lv$level)';
}
