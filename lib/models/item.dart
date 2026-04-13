import 'affix.dart';
import 'enums.dart';
import 'stats.dart';

/// Oyundaki bir ekipman/item
class Item {
  const Item({
    required this.id,
    required this.nameKey,
    required this.slot,
    required this.rarity,
    required this.iLevel,
    required this.baseStats,
    this.affixes = const [],
    this.upgradeLevel = 0,
    this.sockets = 0,
    this.gems = const [],
  });

  final String id;
  final String nameKey; // ARB key
  final EquipmentSlot slot;
  final Rarity rarity;
  final int iLevel;
  final Stats baseStats;
  final List<Affix> affixes;
  final int upgradeLevel;
  final int sockets;
  final List<String> gems; // gem id'leri

  Item copyWith({
    String? id,
    String? nameKey,
    EquipmentSlot? slot,
    Rarity? rarity,
    int? iLevel,
    Stats? baseStats,
    List<Affix>? affixes,
    int? upgradeLevel,
    int? sockets,
    List<String>? gems,
  }) {
    return Item(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      slot: slot ?? this.slot,
      rarity: rarity ?? this.rarity,
      iLevel: iLevel ?? this.iLevel,
      baseStats: baseStats ?? this.baseStats,
      affixes: affixes ?? this.affixes,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      sockets: sockets ?? this.sockets,
      gems: gems ?? this.gems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKey': nameKey,
      'slot': slot.name,
      'rarity': rarity.name,
      'iLevel': iLevel,
      'baseStats': baseStats.toJson(),
      'affixes': affixes.map((a) => a.toJson()).toList(),
      'upgradeLevel': upgradeLevel,
      'sockets': sockets,
      'gems': gems,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      nameKey: json['nameKey'] as String,
      slot: EquipmentSlot.values.byName(json['slot'] as String),
      rarity: Rarity.values.byName(json['rarity'] as String),
      iLevel: json['iLevel'] as int,
      baseStats: Stats.fromJson(json['baseStats'] as Map<String, dynamic>),
      affixes: (json['affixes'] as List<dynamic>?)
              ?.map((a) => Affix.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      upgradeLevel: json['upgradeLevel'] as int? ?? 0,
      sockets: json['sockets'] as int? ?? 0,
      gems: (json['gems'] as List<dynamic>?)
              ?.map((g) => g as String)
              .toList() ??
          const [],
    );
  }

  @override
  String toString() => 'Item($nameKey, ${rarity.name}, +$upgradeLevel, iLv$iLevel)';
}
