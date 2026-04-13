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
  final int _totalWaves = 8;

  double _heroHp = 1;
  double _heroMaxHp = 1;
  bool _isDefeated = false;

  @override
  void initState() {
    super.initState();
    final hero = ref.read(playerProvider);
    final stats = hero?.baseStats ?? const Stats(hp: 200, atk: 18, def: 15, spd: 0.8);

    _heroMaxHp = stats.hp;
    _heroHp = _heroMaxHp;

    _game = BattleGame(
      heroClass: hero?.heroClass ?? HeroClass.kalkanEr,
      heroStats: stats,
      stageId: hero?.currentStage ?? 1,
    );
    _game.onLaneChanged = (lane) {
      setState(() => _currentLane = lane);
    };
    _game.onWaveChanged = (wave, total) {
      setState(() => _currentWave = wave);
    };
    _game.onHeroHpChanged = (current, max) {
      setState(() {
        _heroHp = current;
        _heroMaxHp = max;
      });
    };
    _game.onHeroDied = () {
      setState(() => _isDefeated = true);
    };
  }

  void _restartBattle() {
    final hero = ref.read(playerProvider);
    final stats = hero?.baseStats ?? const Stats(hp: 200, atk: 18, def: 15, spd: 0.8);

    setState(() {
      _isDefeated = false;
      _heroHp = stats.hp;
      _heroMaxHp = stats.hp;
      _currentWave = 1;
      _currentLane = Lane.middle;
      _game = BattleGame(
        heroClass: hero?.heroClass ?? HeroClass.kalkanEr,
        heroStats: stats,
        stageId: hero?.currentStage ?? 1,
      );
      _game.onLaneChanged = (lane) {
        setState(() => _currentLane = lane);
      };
      _game.onWaveChanged = (wave, total) {
        setState(() => _currentWave = wave);
      };
      _game.onHeroHpChanged = (current, max) {
        setState(() {
          _heroHp = current;
          _heroMaxHp = max;
        });
      };
      _game.onHeroDied = () {
        setState(() => _isDefeated = true);
      };
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

          // Ust UI — HP bar + Stage bilgisi
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
                    // Ust satir: geri butonu + stage + dalga
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.gold, size: 20),
                          onPressed: () => context.go('/game'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
                    // HP bar
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

          // Alt UI — serit gostergesi + skill butonlari
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
                    // Serit gostergesi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: Lane.values.map((lane) {
                        final isActive = lane == _currentLane;
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
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            _laneName(l10n, lane),
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.gold
                                  : AppColors.textDim,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Skill butonlari (placeholder)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (i) {
                        return Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.textDim,
                            ),
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
        ],
      ),
    );
  }
}
