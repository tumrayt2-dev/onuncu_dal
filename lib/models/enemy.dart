import 'enums.dart';
import 'stats.dart';

/// Düşman arketipi
enum EnemyArchetype {
  melee,
  caster,
  fast,
  pack,
  tank,
  charger,
  buffer,
  flying,
  miniBoss,
  worldBoss,
}

/// Loot tablosu girdisi
class LootEntry {
  const LootEntry({
    required this.itemId,
    required this.chance,
    this.minStage = 1,
  });

  final String itemId;
  final double chance; // 0.0 - 1.0
  final int minStage;

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'chance': chance,
      'minStage': minStage,
    };
  }

  factory LootEntry.fromJson(Map<String, dynamic> json) {
    return LootEntry(
      itemId: json['itemId'] as String,
      chance: (json['chance'] as num).toDouble(),
      minStage: json['minStage'] as int? ?? 1,
    );
  }
}

/// Loot tablosu
class LootTable {
  const LootTable({
    required this.goldMin,
    required this.goldMax,
    required this.xp,
    this.itemDropChance = 0.1,
    this.specialDrops = const [],
  });

  final int goldMin;
  final int goldMax;
  final int xp;
  final double itemDropChance;
  final List<LootEntry> specialDrops;

  Map<String, dynamic> toJson() {
    return {
      'goldMin': goldMin,
      'goldMax': goldMax,
      'xp': xp,
      'itemDropChance': itemDropChance,
      'specialDrops': specialDrops.map((e) => e.toJson()).toList(),
    };
  }

  factory LootTable.fromJson(Map<String, dynamic> json) {
    return LootTable(
      goldMin: json['goldMin'] as int,
      goldMax: json['goldMax'] as int,
      xp: json['xp'] as int,
      itemDropChance: (json['itemDropChance'] as num?)?.toDouble() ?? 0.1,
      specialDrops: (json['specialDrops'] as List<dynamic>?)
              ?.map((e) => LootEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Bir düşman tanımı
class Enemy {
  const Enemy({
    required this.id,
    required this.nameKey,
    required this.archetype,
    required this.worldId,
    required this.baseStats,
    required this.lootTable,
    this.lane = Lane.middle,
    this.specialAbility,
  });

  final String id;
  final String nameKey;
  final EnemyArchetype archetype;
  final int worldId;
  final Stats baseStats;
  final LootTable lootTable;
  final Lane lane;
  final String? specialAbility;

  Enemy copyWith({
    String? id,
    String? nameKey,
    EnemyArchetype? archetype,
    int? worldId,
    Stats? baseStats,
    LootTable? lootTable,
    Lane? lane,
    String? specialAbility,
  }) {
    return Enemy(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      archetype: archetype ?? this.archetype,
      worldId: worldId ?? this.worldId,
      baseStats: baseStats ?? this.baseStats,
      lootTable: lootTable ?? this.lootTable,
      lane: lane ?? this.lane,
      specialAbility: specialAbility ?? this.specialAbility,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKey': nameKey,
      'archetype': archetype.name,
      'worldId': worldId,
      'baseStats': baseStats.toJson(),
      'lootTable': lootTable.toJson(),
      'lane': lane.name,
      'specialAbility': specialAbility,
    };
  }

  factory Enemy.fromJson(Map<String, dynamic> json) {
    return Enemy(
      id: json['id'] as String,
      nameKey: json['nameKey'] as String,
      archetype: EnemyArchetype.values.byName(json['archetype'] as String),
      worldId: json['worldId'] as int,
      baseStats: Stats.fromJson(json['baseStats'] as Map<String, dynamic>),
      lootTable: LootTable.fromJson(json['lootTable'] as Map<String, dynamic>),
      lane: Lane.values.byName(json['lane'] as String? ?? 'middle'),
      specialAbility: json['specialAbility'] as String?,
    );
  }

  @override
  String toString() => 'Enemy($nameKey, ${archetype.name}, world$worldId)';
}
