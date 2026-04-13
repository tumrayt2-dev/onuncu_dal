/// Item affix tipleri
enum AffixType {
  atkPercent,
  hpFlat,
  critPercent,
  critDmgPercent,
  lifestealPercent,
  spdFlat,
  goldFindPercent,
  magicFindPercent,
  dodgePercent,
  resistPercent,
  hpRegenFlat,
  elementDmgPercent,
}

/// Bir item üzerindeki tek bir affix
class Affix {
  const Affix({
    required this.id,
    required this.type,
    required this.value,
    required this.isPercent,
  });

  final String id;
  final AffixType type;
  final double value;
  final bool isPercent;

  Affix copyWith({
    String? id,
    AffixType? type,
    double? value,
    bool? isPercent,
  }) {
    return Affix(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      isPercent: isPercent ?? this.isPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'value': value,
      'isPercent': isPercent,
    };
  }

  factory Affix.fromJson(Map<String, dynamic> json) {
    return Affix(
      id: json['id'] as String,
      type: AffixType.values.byName(json['type'] as String),
      value: (json['value'] as num).toDouble(),
      isPercent: json['isPercent'] as bool,
    );
  }

  @override
  String toString() => 'Affix($type: $value${isPercent ? '%' : ''})';
}
