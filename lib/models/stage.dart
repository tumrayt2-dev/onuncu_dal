/// Bir dalga içindeki mob spawn bilgisi
class WaveEntry {
  const WaveEntry({
    required this.enemyId,
    required this.count,
  });

  final String enemyId;
  final int count;

  Map<String, dynamic> toJson() => {'enemyId': enemyId, 'count': count};

  factory WaveEntry.fromJson(Map<String, dynamic> json) {
    return WaveEntry(
      enemyId: json['enemyId'] as String,
      count: json['count'] as int,
    );
  }
}

/// Stage ödülleri
class StageRewards {
  const StageRewards({
    this.goldMin = 0,
    this.goldMax = 0,
    this.xp = 0,
    this.firstClearGold = 0,
    this.firstClearGems = 0,
  });

  final int goldMin;
  final int goldMax;
  final int xp;
  final int firstClearGold;
  final int firstClearGems;

  Map<String, dynamic> toJson() {
    return {
      'goldMin': goldMin,
      'goldMax': goldMax,
      'xp': xp,
      'firstClearGold': firstClearGold,
      'firstClearGems': firstClearGems,
    };
  }

  factory StageRewards.fromJson(Map<String, dynamic> json) {
    return StageRewards(
      goldMin: json['goldMin'] as int? ?? 0,
      goldMax: json['goldMax'] as int? ?? 0,
      xp: json['xp'] as int? ?? 0,
      firstClearGold: json['firstClearGold'] as int? ?? 0,
      firstClearGems: json['firstClearGems'] as int? ?? 0,
    );
  }
}

/// Bir stage tanımı
class Stage {
  const Stage({
    required this.worldId,
    required this.stageId,
    required this.waves,
    this.bossId,
    required this.rewards,
    this.stars = 0,
  });

  final int worldId;
  final int stageId;
  final List<List<WaveEntry>> waves; // 8 dalga, her dalgada mob listesi
  final String? bossId;
  final StageRewards rewards;
  final int stars; // 0-3

  bool get isBoss =>
      stageId == 10 || stageId == 20 || stageId == 30 ||
      stageId == 40 || stageId == 50;

  Stage copyWith({
    int? worldId,
    int? stageId,
    List<List<WaveEntry>>? waves,
    String? bossId,
    StageRewards? rewards,
    int? stars,
  }) {
    return Stage(
      worldId: worldId ?? this.worldId,
      stageId: stageId ?? this.stageId,
      waves: waves ?? this.waves,
      bossId: bossId ?? this.bossId,
      rewards: rewards ?? this.rewards,
      stars: stars ?? this.stars,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worldId': worldId,
      'stageId': stageId,
      'waves': waves
          .map((wave) => wave.map((e) => e.toJson()).toList())
          .toList(),
      'bossId': bossId,
      'rewards': rewards.toJson(),
      'stars': stars,
    };
  }

  factory Stage.fromJson(Map<String, dynamic> json) {
    return Stage(
      worldId: json['worldId'] as int,
      stageId: json['stageId'] as int,
      waves: (json['waves'] as List<dynamic>)
          .map((wave) => (wave as List<dynamic>)
              .map((e) => WaveEntry.fromJson(e as Map<String, dynamic>))
              .toList())
          .toList(),
      bossId: json['bossId'] as String?,
      rewards:
          StageRewards.fromJson(json['rewards'] as Map<String, dynamic>),
      stars: json['stars'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'Stage(W$worldId-S$stageId${isBoss ? ' [BOSS]' : ''})';
}
