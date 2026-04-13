import 'dart:math';

import '../data/json_loader.dart';
import '../models/enemy.dart';
import '../models/enums.dart';
import '../models/stage.dart';

/// Dalga yonetim servisi — stage JSON'dan mob spawn sirasi olusturur
class WaveService {
  WaveService({required this.stageId, required this.worldId});

  final int stageId;
  final int worldId;

  static final _rng = Random();

  Stage? _stage;
  int _currentWave = 0;
  int _spawnIndex = 0;
  double _spawnTimer = 0;
  double _waveBreakTimer = 0;
  bool _waitingForClear = false;
  bool _waveBreak = false;
  bool _allWavesDone = false;

  int get currentWave => _currentWave + 1; // 1-indexed
  int get totalWaves => _stage?.waves.length ?? 8;
  bool get allWavesDone => _allWavesDone;
  bool get waitingForClear => _waitingForClear;
  StageRewards get rewards => _stage?.rewards ?? const StageRewards();

  List<_SpawnEntry> _currentSpawnList = [];

  void init() {
    final loader = JsonLoader.instance;
    // ignore: avoid_print
    print('WaveService.init: stageId=$stageId, worldId=$worldId, stages=${loader.stages.length}');
    if (loader.stages.isEmpty) {
      // ignore: avoid_print
      print('WaveService: No stages loaded!');
      _allWavesDone = true;
      return;
    }
    _stage = loader.stages.firstWhere(
      (s) => s.stageId == stageId && s.worldId == worldId,
      orElse: () => loader.stages.first,
    );
    // ignore: avoid_print
    print('WaveService: Found stage ${_stage!.stageId} with ${_stage!.waves.length} waves');
    _prepareWave(0);
  }

  void _prepareWave(int index) {
    _currentWave = index;
    _spawnIndex = 0;
    _spawnTimer = 0;
    _waitingForClear = false;
    _waveBreak = false;

    final stage = _stage;
    if (stage == null || index >= stage.waves.length) {
      _allWavesDone = true;
      return;
    }

    // Dalga icerigini spawn listesine cevir
    _currentSpawnList = [];
    final waveEntries = stage.waves[index];
    for (final entry in waveEntries) {
      final enemy = _findEnemy(entry.enemyId);
      if (enemy != null) {
        for (var i = 0; i < entry.count; i++) {
          _currentSpawnList.add(_SpawnEntry(enemy: enemy));
        }
      }
    }
    // Karıştır
    _currentSpawnList.shuffle(_rng);
  }

  Enemy? _findEnemy(String id) {
    final loader = JsonLoader.instance;
    try {
      return loader.enemies.firstWhere((e) => e.id == id);
    } catch (_) {
      try {
        return loader.bosses.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  /// Her frame cagrilir. Spawn edilecek enemy varsa dondurur.
  /// [aliveCount]: sahndeki canli dusman sayisi
  Enemy? update(double dt, int aliveCount) {
    if (_allWavesDone || _stage == null) return null;

    // Dalgalar arasi bekleme
    if (_waveBreak) {
      _waveBreakTimer += dt;
      if (_waveBreakTimer >= 2.0) {
        _prepareWave(_currentWave + 1);
      }
      return null;
    }

    // Tum moblar spawnlandiysa dalga temizlenmesini bekle
    if (_spawnIndex >= _currentSpawnList.length) {
      _waitingForClear = true;
      if (aliveCount == 0) {
        // Dalga temizlendi
        _waveBreak = true;
        _waveBreakTimer = 0;
      }
      return null;
    }

    // Spawn zamanlayici (0.5-1sn arasi)
    _spawnTimer += dt;
    final spawnDelay = _spawnIndex == 0 ? 0.0 : 0.5 + _rng.nextDouble() * 0.5;
    if (_spawnTimer >= spawnDelay) {
      _spawnTimer = 0;
      final entry = _currentSpawnList[_spawnIndex];
      _spawnIndex++;
      return entry.enemy;
    }

    return null;
  }

  /// Rastgele serit sec
  Lane randomLane() {
    return Lane.values[_rng.nextInt(Lane.values.length)];
  }
}

class _SpawnEntry {
  const _SpawnEntry({required this.enemy});
  final Enemy enemy;
}
