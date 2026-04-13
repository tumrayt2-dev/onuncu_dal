/// Tüm karakter/item stat değerlerini tutan immutable sınıf.
class Stats {
  const Stats({
    this.hp = 0,
    this.mp = 0,
    this.atk = 0,
    this.def = 0,
    this.spd = 0,
    this.crit = 0,
    this.critDmg = 0,
    this.dodge = 0,
    this.block = 0,
    this.lifesteal = 0,
    this.hpRegen = 0,
    this.accuracy = 0,
    this.resist = 0,
    this.magicFind = 0,
  });

  final double hp;
  final double mp;
  final double atk;
  final double def;
  final double spd;
  final double crit;      // % — max 75
  final double critDmg;   // % — max 500
  final double dodge;     // % — max 40
  final double block;     // % — max 60 (sadece Kalkan-Er)
  final double lifesteal; // % — max 25
  final double hpRegen;
  final double accuracy;
  final double resist;    // % — max 50
  final double magicFind; // % — max 300

  Stats copyWith({
    double? hp,
    double? mp,
    double? atk,
    double? def,
    double? spd,
    double? crit,
    double? critDmg,
    double? dodge,
    double? block,
    double? lifesteal,
    double? hpRegen,
    double? accuracy,
    double? resist,
    double? magicFind,
  }) {
    return Stats(
      hp: hp ?? this.hp,
      mp: mp ?? this.mp,
      atk: atk ?? this.atk,
      def: def ?? this.def,
      spd: spd ?? this.spd,
      crit: crit ?? this.crit,
      critDmg: critDmg ?? this.critDmg,
      dodge: dodge ?? this.dodge,
      block: block ?? this.block,
      lifesteal: lifesteal ?? this.lifesteal,
      hpRegen: hpRegen ?? this.hpRegen,
      accuracy: accuracy ?? this.accuracy,
      resist: resist ?? this.resist,
      magicFind: magicFind ?? this.magicFind,
    );
  }

  /// İki stat'ı toplar (ekipman bonusu vb.)
  Stats operator +(Stats other) {
    return Stats(
      hp: hp + other.hp,
      mp: mp + other.mp,
      atk: atk + other.atk,
      def: def + other.def,
      spd: spd + other.spd,
      crit: crit + other.crit,
      critDmg: critDmg + other.critDmg,
      dodge: dodge + other.dodge,
      block: block + other.block,
      lifesteal: lifesteal + other.lifesteal,
      hpRegen: hpRegen + other.hpRegen,
      accuracy: accuracy + other.accuracy,
      resist: resist + other.resist,
      magicFind: magicFind + other.magicFind,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hp': hp,
      'mp': mp,
      'atk': atk,
      'def': def,
      'spd': spd,
      'crit': crit,
      'critDmg': critDmg,
      'dodge': dodge,
      'block': block,
      'lifesteal': lifesteal,
      'hpRegen': hpRegen,
      'accuracy': accuracy,
      'resist': resist,
      'magicFind': magicFind,
    };
  }

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      hp: (json['hp'] as num?)?.toDouble() ?? 0,
      mp: (json['mp'] as num?)?.toDouble() ?? 0,
      atk: (json['atk'] as num?)?.toDouble() ?? 0,
      def: (json['def'] as num?)?.toDouble() ?? 0,
      spd: (json['spd'] as num?)?.toDouble() ?? 0,
      crit: (json['crit'] as num?)?.toDouble() ?? 0,
      critDmg: (json['critDmg'] as num?)?.toDouble() ?? 0,
      dodge: (json['dodge'] as num?)?.toDouble() ?? 0,
      block: (json['block'] as num?)?.toDouble() ?? 0,
      lifesteal: (json['lifesteal'] as num?)?.toDouble() ?? 0,
      hpRegen: (json['hpRegen'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      resist: (json['resist'] as num?)?.toDouble() ?? 0,
      magicFind: (json['magicFind'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  String toString() =>
      'Stats(hp:$hp, atk:$atk, def:$def, spd:$spd, crit:$crit%)';
}
