/// Bir dünya tanımı
class WorldData {
  const WorldData({
    required this.id,
    required this.nameKey,
    required this.theme,
    this.worldEffect,
    this.bossId,
  });

  final int id;
  final String nameKey;    // ARB key
  final String theme;
  final String? worldEffect;
  final String? bossId;

  WorldData copyWith({
    int? id,
    String? nameKey,
    String? theme,
    String? worldEffect,
    String? bossId,
  }) {
    return WorldData(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      theme: theme ?? this.theme,
      worldEffect: worldEffect ?? this.worldEffect,
      bossId: bossId ?? this.bossId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKey': nameKey,
      'theme': theme,
      'worldEffect': worldEffect,
      'bossId': bossId,
    };
  }

  factory WorldData.fromJson(Map<String, dynamic> json) {
    return WorldData(
      id: json['id'] as int,
      nameKey: json['nameKey'] as String,
      theme: json['theme'] as String,
      worldEffect: json['worldEffect'] as String?,
      bossId: json['bossId'] as String?,
    );
  }

  @override
  String toString() => 'WorldData($nameKey, id:$id)';
}
