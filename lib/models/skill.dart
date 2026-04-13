import 'enums.dart';

/// Skill tipi
enum SkillType { active, passive }

/// Bir kahraman skill'i
class Skill {
  const Skill({
    required this.id,
    required this.nameKey,
    required this.heroClass,
    required this.type,
    this.level = 0,
    this.maxLevel = 5,
    this.cooldown = 0,
    required this.descriptionKey,
  });

  final String id;
  final String nameKey;       // ARB key
  final HeroClass heroClass;
  final SkillType type;
  final int level;
  final int maxLevel;
  final double cooldown;      // saniye
  final String descriptionKey; // ARB key

  Skill copyWith({
    String? id,
    String? nameKey,
    HeroClass? heroClass,
    SkillType? type,
    int? level,
    int? maxLevel,
    double? cooldown,
    String? descriptionKey,
  }) {
    return Skill(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      heroClass: heroClass ?? this.heroClass,
      type: type ?? this.type,
      level: level ?? this.level,
      maxLevel: maxLevel ?? this.maxLevel,
      cooldown: cooldown ?? this.cooldown,
      descriptionKey: descriptionKey ?? this.descriptionKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKey': nameKey,
      'heroClass': heroClass.name,
      'type': type.name,
      'level': level,
      'maxLevel': maxLevel,
      'cooldown': cooldown,
      'descriptionKey': descriptionKey,
    };
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      nameKey: json['nameKey'] as String,
      heroClass: HeroClass.values.byName(json['heroClass'] as String),
      type: SkillType.values.byName(json['type'] as String),
      level: json['level'] as int? ?? 0,
      maxLevel: json['maxLevel'] as int? ?? 5,
      cooldown: (json['cooldown'] as num?)?.toDouble() ?? 0,
      descriptionKey: json['descriptionKey'] as String,
    );
  }

  @override
  String toString() => 'Skill($nameKey, lv$level/$maxLevel)';
}
