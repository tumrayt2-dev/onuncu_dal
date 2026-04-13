import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';
import '../models/enums.dart';
import '../models/stats.dart';
import '../providers/player_provider.dart';
import '../game/battle_game.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  late BattleGame _game;
  Lane _currentLane = Lane.middle;
  int _currentWave = 1;
  int _totalWaves = 8;

  double _heroHp = 1;
  double _heroMaxHp = 1;
  bool _isDefeated = false;
  bool _isPaused = false;

  // Stage complete
  bool _stageComplete = false;
  int _rewardXp = 0;
  int _rewardGold = 0;
  int _stars = 0;
  bool _leveledUp = false;
  int _newLevel = 0;

  // Lane info
  Map<Lane, int> _laneCounts = {};
  Lane? _bufferLane;

  // AFK AI toggle
  bool _afkEnabled = false;

  // Side damage flash
  double _topFlash = 0;
  double _bottomFlash = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _safeSetState(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  void _initGame() {
    final hero = ref.read(playerProvider);
    final stats = hero?.baseStats ?? const Stats(hp: 200, atk: 18, def: 15, spd: 0.8);

    _heroMaxHp = stats.hp;
    _heroHp = _heroMaxHp;

    _game = BattleGame(
      heroClass: hero?.heroClass ?? HeroClass.kalkanEr,
      heroStats: stats,
      stageId: hero?.currentStage ?? 1,
      worldId: hero?.currentWorldId ?? 1,
    );
    _game.onLaneChanged = (lane) {
      _safeSetState(() => _currentLane = lane);
    };
    _game.onWaveChanged = (wave, total) {
      _safeSetState(() {
        _currentWave = wave;
        _totalWaves = total;
      });
    };
    _game.onHeroHpChanged = (current, max) {
      _safeSetState(() {
        _heroHp = current;
        _heroMaxHp = max;
      });
    };
    _game.onHeroDied = () {
      _safeSetState(() => _isDefeated = true);
    };
    _game.onStageComplete = (xp, gold, hpPercent, time) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onStageComplete(xp, gold, hpPercent, time);
      });
    };
    _game.onLaneInfoChanged = (counts, bufferLane) {
      _safeSetState(() {
        _laneCounts = counts;
        _bufferLane = bufferLane;
      });
    };
    _game.onSideDamageFlash = (lane) {
      _safeSetState(() {
        // Yan serit hasari: hero'nun ustundeki serit top flash, altindaki bottom flash
        final heroLane = _currentLane;
        if (lane.index < heroLane.index) {
          _topFlash = 1.0;
        } else if (lane.index > heroLane.index) {
          _bottomFlash = 1.0;
        }
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            if (lane == Lane.top) _topFlash = 0;
            if (lane == Lane.bottom) _bottomFlash = 0;
          });
        }
      });
    };
  }

  void _onStageComplete(int xp, int gold, double hpPercent, double time) {
    int stars = 1;
    if (hpPercent >= 0.5) stars = 2;
    if (hpPercent >= 0.8) stars = 3;

    final hero = ref.read(playerProvider);
    final oldLevel = hero?.level ?? 1;

    ref.read(playerProvider.notifier).addXp(xp);
    ref.read(playerProvider.notifier).addGold(gold);

    final updatedHero = ref.read(playerProvider);
    final leveled = (updatedHero?.level ?? 1) > oldLevel;

    final currentStage = hero?.currentStage ?? 1;
    ref.read(playerProvider.notifier).updateStage(
      currentStage + 1,
      hero?.currentWorldId ?? 1,
    );

    setState(() {
      _stageComplete = true;
      _rewardXp = xp;
      _rewardGold = gold;
      _stars = stars;
      _leveledUp = leveled;
      _newLevel = updatedHero?.level ?? 1;
    });
  }

  void _togglePause() {
    _game.togglePause();
    setState(() => _isPaused = _game.isPaused);
  }

  void _restartBattle() {
    setState(() {
      _isDefeated = false;
      _stageComplete = false;
      _isPaused = false;
      _currentWave = 1;
      _currentLane = Lane.middle;
      _leveledUp = false;
      _laneCounts = {};
      _bufferLane = null;
      _initGame();
    });
  }

  String _laneName(AppLocalizations l10n, Lane lane) => switch (lane) {
        Lane.top => 'UST',
        Lane.middle => 'ORTA',
        Lane.bottom => 'ALT',
      };

  @override
  Widget build(BuildContext context) {
    final hero = ref.watch(playerProvider);
    final l10n = AppLocalizations.of(context)!;

    if (hero == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Flame oyun
          GameWidget(game: _game),

          // Yan serit hasar flash — ust
          if (_topFlash > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.15,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.red.withValues(alpha: 0.6 * _topFlash),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Yan serit hasar flash — alt
          if (_bottomFlash > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.15,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.red.withValues(alpha: 0.6 * _bottomFlash),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Ust UI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC000000),
                      Color(0x00000000),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Pause butonu
                        IconButton(
                          icon: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          onPressed: _togglePause,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        // AFK toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _afkEnabled = !_afkEnabled;
                              _game.afkEnabled = _afkEnabled;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _afkEnabled
                                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                  : AppColors.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _afkEnabled
                                    ? const Color(0xFF4CAF50)
                                    : AppColors.textDim,
                              ),
                            ),
                            child: Text(
                              'AFK',
                              style: TextStyle(
                                color: _afkEnabled
                                    ? const Color(0xFF4CAF50)
                                    : AppColors.textDim,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stage ${hero.currentStage}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_currentWave/$_totalWaves',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${l10n.hp} ',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_heroHp / _heroMaxHp).clamp(0, 1),
                              minHeight: 10,
                              backgroundColor: const Color(0xFF333333),
                              valueColor: AlwaysStoppedAnimation(
                                Color.lerp(
                                  const Color(0xFFFF0000),
                                  const Color(0xFF4CAF50),
                                  (_heroHp / _heroMaxHp).clamp(0, 1),
                                )!,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_heroHp.toInt()}/${_heroMaxHp.toInt()}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Alt UI — serit gostergesi + mob sayaci + skill
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xCC000000),
                      Color(0x00000000),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Serit gostergesi + mob sayaci
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: Lane.values.map((lane) {
                        final isActive = lane == _currentLane;
                        final mobCount = _laneCounts[lane] ?? 0;
                        final hasBuffer = _bufferLane == lane;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.gold.withValues(alpha: 0.3)
                                : AppColors.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.gold
                                  : hasBuffer
                                      ? const Color(0xFFFF6600)
                                      : Colors.transparent,
                              width: hasBuffer ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasBuffer)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.warning_amber,
                                      color: Color(0xFFFF6600), size: 12),
                                ),
                              Text(
                                _laneName(l10n, lane),
                                style: TextStyle(
                                  color: isActive
                                      ? AppColors.gold
                                      : AppColors.textDim,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (mobCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: mobCount > 3
                                        ? const Color(0xFFFF4444)
                                        : const Color(0xFF666666),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$mobCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (i) {
                        return Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.textDim),
                          ),
                          child: Center(
                            child: Text(
                              'S${i + 1}',
                              style: const TextStyle(
                                color: AppColors.textDim,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pause overlay
          if (_isPaused && !_isDefeated && !_stageComplete)
            Container(
              color: const Color(0xCC000000),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pause_circle_outline,
                        color: AppColors.gold, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'DURAKLADI',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _togglePause,
                        child: Text(l10n.continueText),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton(
                        onPressed: () => context.go('/game'),
                        child: Text(l10n.goBack),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Yenilgi ekrani
          if (_isDefeated)
            Container(
              color: const Color(0xCC000000),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.defeated,
                      style: const TextStyle(
                        color: Color(0xFFFF4444),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _restartBattle,
                        child: Text(l10n.retry),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton(
                        onPressed: () => context.go('/game'),
                        child: Text(l10n.goBack),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Stage tamamlandi ekrani
          if (_stageComplete)
            Container(
              color: const Color(0xCC000000),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.stageComplete,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Icon(
                          i < _stars ? Icons.star : Icons.star_border,
                          color: AppColors.gold,
                          size: 40,
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _RewardRow(
                            label: l10n.totalXp,
                            value: '+$_rewardXp',
                            color: const Color(0xFF64B5F6),
                          ),
                          const SizedBox(height: 8),
                          _RewardRow(
                            label: l10n.totalGold,
                            value: '+$_rewardGold',
                            color: AppColors.gold,
                          ),
                          if (_leveledUp) ...[
                            const SizedBox(height: 12),
                            Text(
                              '${l10n.levelUp} (Lv $_newLevel)',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => context.go('/game'),
                        child: Text(l10n.continueText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
