import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';
import '../data/json_loader.dart';
import '../models/enums.dart';
import '../models/item.dart';
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

  // Lane info (Flame canvas icinde gosteriliyor)

  // AFK AI toggle
  bool _afkEnabled = false;

  // Savas boyunca biriken oduller (henuz verilmedi, savaş sonunda toplu verilir)
  int _earnedXp = 0;
  int _earnedGold = 0;
  final List<Item> _earnedItems = [];

  // Side damage flash
  double _topFlash = 0;
  double _bottomFlash = 0;

  // Combo
  int _combo = 0;
  Color _comboColor = Colors.white;
  int _comboTier = 0;

  // Resource
  double _resCurrent = 0;
  double _resMax = 100;
  bool _specialReady = false;
  bool _specialActive = false;

  // Special ability flash
  String? _specialFlashName;
  double _specialFlashTimer = 0;

  // Loot popup
  String? _lootItemName;
  Color _lootColor = Colors.grey;
  bool _lootIsRarePlus = false;

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
    final heroId = switch (hero?.heroClass) {
      HeroClass.kalkanEr => 'kalkan_er',
      HeroClass.kurtBoru => 'kurt_boru',
      HeroClass.kam => 'kam',
      HeroClass.yayCi => 'yay_ci',
      HeroClass.golgeBek => 'golge_bek',
      null => 'kalkan_er',
    };
    final perLevel = JsonLoader.instance.getHeroPerLevel(heroId);
    final stats = hero?.effectiveStats(perLevel) ?? const Stats(hp: 200, atk: 18, def: 15, spd: 0.8);

    _heroMaxHp = stats.hp;
    _heroHp = _heroMaxHp;

    _game = BattleGame(
      heroClass: hero?.heroClass ?? HeroClass.kalkanEr,
      heroStats: stats,
      stageId: hero?.currentStage ?? 1,
      worldId: hero?.currentWorldId ?? 1,
    );
    _game.afkEnabled = _afkEnabled;
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
    _game.onRewardPopup = (xp, gold) {
      // Biriktir — savaş sonunda toplu verilecek
      _earnedXp += xp;
      _earnedGold += gold;
    };
    _game.onStageComplete = (xp, gold, hpPercent, time) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onStageComplete(xp, gold, hpPercent, time);
      });
    };
    // Lane info artik Flame canvas icinde gosteriliyor
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
    _game.onComboChanged = (combo, color, tier) {
      _safeSetState(() {
        _combo = combo;
        _comboColor = Color(color.toARGB32());
        _comboTier = tier;
      });
    };
    _game.onResourceChanged = (current, max, specialReady, specialActive) {
      _safeSetState(() {
        _resCurrent = current;
        _resMax = max;
        _specialReady = specialReady;
        _specialActive = specialActive;
      });
    };
    _game.onItemDropped = (item) {
      // Biriktir — savaş sonunda toplu verilecek
      _earnedItems.add(item);
      final isRarePlus = item.rarity.index >= Rarity.rare.index;
      _safeSetState(() {
        _lootItemName = item.nameKey;
        _lootColor = Color(item.rarity.colorHex);
        _lootIsRarePlus = isRarePlus;
      });
      Future.delayed(Duration(milliseconds: isRarePlus ? 2500 : 1500), () {
        if (mounted) {
          setState(() {
            _lootItemName = null;
          });
        }
      });
    };
    _game.onSpecialActivated = (name) {
      _safeSetState(() {
        _specialFlashName = name;
        _specialFlashTimer = 1.5;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _specialFlashName = null;
            _specialFlashTimer = 0;
          });
        }
      });
    };
  }

  void _onStageComplete(int xp, int gold, double hpPercent, double time) {
    int stars = 1;
    if (hpPercent >= 0.5) stars = 2;
    if (hpPercent >= 0.8) stars = 3;

    // Birikmiş ödülleri toplu ver
    _grantRewards(xpPercent: 1.0, goldPercent: 1.0, giveItems: true);

    final updatedHero = ref.read(playerProvider);
    final currentStage = updatedHero?.currentStage ?? 1;
    ref.read(playerProvider.notifier).updateStage(
      currentStage + 1,
      updatedHero?.currentWorldId ?? 1,
    );

    setState(() {
      _stageComplete = true;
      _rewardXp = _earnedXp;
      _rewardGold = _earnedGold;
      _stars = stars;
      _leveledUp = false;
      _newLevel = updatedHero?.level ?? 1;
    });
  }

  void _togglePause() {
    _game.togglePause();
    setState(() => _isPaused = _game.isPaused);
  }

  /// Birikmiş ödülleri oyuncuya ver
  void _grantRewards({
    required double xpPercent,
    required double goldPercent,
    required bool giveItems,
  }) {
    final xpToGive = (_earnedXp * xpPercent).round();
    final goldToGive = (_earnedGold * goldPercent).round();
    if (xpToGive > 0) {
      ref.read(playerProvider.notifier).addXp(xpToGive);
    }
    if (goldToGive > 0) {
      ref.read(playerProvider.notifier).addGold(goldToGive);
    }
    if (giveItems) {
      for (final item in _earnedItems) {
        ref.read(playerProvider.notifier).addItem(item);
      }
    }
  }

  void _restartBattle() {
    setState(() {
      _isDefeated = false;
      _stageComplete = false;
      _isPaused = false;
      _currentWave = 1;
      _currentLane = Lane.middle;
      _leveledUp = false;
      _earnedXp = 0;
      _earnedGold = 0;
      _earnedItems.clear();
      _combo = 0;
      _comboColor = Colors.white;
      _comboTier = 0;
      _resCurrent = 0;
      _resMax = 100;
      _specialReady = false;
      _specialActive = false;
      _specialFlashName = null;
      _specialFlashTimer = 0;
      _lootItemName = null;
      _lootColor = Colors.grey;
      _lootIsRarePlus = false;
      _initGame();
    });
  }

  void _showExitConfirmation(BuildContext context, AppLocalizations l10n) {
    final keptGold = (_earnedGold * 0.5).round();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          l10n.exitBattleTitle,
          style: const TextStyle(color: AppColors.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.exitBattlePenalty,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.exitBattleReward('$_earnedXp', '$keptGold'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Tam XP, %50 gold, item yok
              _grantRewards(xpPercent: 1.0, goldPercent: 0.5, giveItems: false);
              context.go('/game');
            },
            child: Text(
              l10n.leaveBattle,
              style: const TextStyle(color: Color(0xFFFF4444)),
            ),
          ),
        ],
      ),
    );
  }

  String _specialL10n(AppLocalizations l10n, String key) => switch (key) {
        'demirKalkan' => l10n.specialDemirKalkan,
        'kurtFormu' => l10n.specialKurtFormu,
        'ruhFirtinasi' => l10n.specialRuhFirtinasi,
        'kartalGoz' => l10n.specialKartalGoz,
        'golgeBicagi' => l10n.specialGolgeBicagi,
        _ => key,
      };

  String _itemL10n(AppLocalizations l10n, String key) => switch (key) {
        'itemSwordCommon' => l10n.itemSwordCommon,
        'itemSwordUncommon' => l10n.itemSwordUncommon,
        'itemSwordRare' => l10n.itemSwordRare,
        'itemHelmCommon' => l10n.itemHelmCommon,
        'itemHelmUncommon' => l10n.itemHelmUncommon,
        'itemHelmRare' => l10n.itemHelmRare,
        'itemChestCommon' => l10n.itemChestCommon,
        'itemChestUncommon' => l10n.itemChestUncommon,
        'itemChestRare' => l10n.itemChestRare,
        'itemGlovesCommon' => l10n.itemGlovesCommon,
        'itemGlovesUncommon' => l10n.itemGlovesUncommon,
        'itemGlovesRare' => l10n.itemGlovesRare,
        'itemPantsCommon' => l10n.itemPantsCommon,
        'itemPantsUncommon' => l10n.itemPantsUncommon,
        'itemPantsRare' => l10n.itemPantsRare,
        'itemBootsCommon' => l10n.itemBootsCommon,
        'itemBootsUncommon' => l10n.itemBootsUncommon,
        'itemBootsRare' => l10n.itemBootsRare,
        'itemRingCommon' => l10n.itemRingCommon,
        'itemRingUncommon' => l10n.itemRingUncommon,
        'itemRingRare' => l10n.itemRingRare,
        'itemRing2Common' => l10n.itemRing2Common,
        'itemRing2Uncommon' => l10n.itemRing2Uncommon,
        'itemRing2Rare' => l10n.itemRing2Rare,
        'itemAmuletCommon' => l10n.itemAmuletCommon,
        'itemAmuletUncommon' => l10n.itemAmuletUncommon,
        'itemAmuletRare' => l10n.itemAmuletRare,
        _ => key,
      };

  String _comboLabel(AppLocalizations l10n, int tier) => switch (tier) {
        4 => '+%20 ${l10n.comboDmg} +%15 ${l10n.comboXp} +%10 ${l10n.comboGold}',
        3 => '+%15 ${l10n.comboDmg} +%10 ${l10n.comboXp} +%5 ${l10n.comboGold}',
        2 => '+%10 ${l10n.comboDmg} +%5 ${l10n.comboXp}',
        1 => '+%5 ${l10n.comboDmg}',
        _ => '',
      };

  String _resourceL10n(AppLocalizations l10n, String key) => switch (key) {
        'irade' => l10n.resourceIrade,
        'ofke' => l10n.resourceOfke,
        'ruh' => l10n.resourceRuh,
        'soluk' => l10n.resourceSoluk,
        'sir' => l10n.resourceSir,
        _ => key,
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
                              l10n.autoMode,
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
                          '${l10n.stage} ${hero.currentStage}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF64B5F6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF64B5F6).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            '${l10n.level} ${hero.level}',
                            style: const TextStyle(
                              color: Color(0xFF64B5F6),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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
                    const SizedBox(height: 6),
                    // Kaynak bari
                    Row(
                      children: [
                        SizedBox(
                          width: 42,
                          child: Text(
                            _resourceL10n(l10n, _game.resourceService.resourceKey).toUpperCase(),
                            style: TextStyle(
                              color: Color(_game.resourceService.barColor.toARGB32()),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: const Color(0xFF222222),
                              border: Border.all(
                                color: _specialReady
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : _specialActive
                                        ? Colors.amber.withValues(alpha: 0.6)
                                        : const Color(0xFF444444),
                                width: _specialReady ? 1.5 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _resMax > 0 ? (_resCurrent / _resMax).clamp(0, 1).toDouble() : 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color(_game.resourceService.barColor.toARGB32()),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_resCurrent.toInt()}/${_resMax.toInt()}',
                          style: TextStyle(
                            color: _specialReady
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: _specialReady ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (_specialActive)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.bolt, color: Colors.amber, size: 16),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Alt UI — skill butonlari
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

          // Combo gostergesi — baloncuklarin solunda
          if (_combo > 0)
            Positioned(
              right: 52,
              top: MediaQuery.of(context).size.height * 0.15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_combo',
                    style: TextStyle(
                      color: _comboColor,
                      fontSize: _combo >= 50 ? 40 : _combo >= 20 ? 34 : 26,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: _comboColor.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.combo,
                    style: TextStyle(
                      color: _comboColor.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_comboTier > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _comboColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _comboLabel(l10n, _comboTier),
                        style: TextStyle(
                          color: _comboColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Special ability flash
          if (_specialFlashName != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    _specialL10n(l10n, _specialFlashName!),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: _specialFlashTimer > 0 ? 1.0 : 0.0),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.amber, blurRadius: 20),
                        Shadow(color: Colors.amber, blurRadius: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Loot popup
          if (_lootItemName != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _lootColor, width: 2),
                      boxShadow: _lootIsRarePlus
                          ? [
                              BoxShadow(
                                color: _lootColor.withValues(alpha: 0.6),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_lootIsRarePlus)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.auto_awesome,
                                color: _lootColor, size: 18),
                          ),
                        Text(
                          _itemL10n(l10n, _lootItemName!),
                          style: TextStyle(
                            color: _lootColor,
                            fontSize: _lootIsRarePlus ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
                    Text(
                      l10n.paused,
                      style: const TextStyle(
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
                        onPressed: () => _showExitConfirmation(context, l10n),
                        child: Text(l10n.leaveBattle),
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
                    if (_earnedXp > 0 || _earnedGold > 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.defeatRewards,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 60),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _RewardRow(
                              label: l10n.totalXp,
                              value: '+$_earnedXp',
                              color: const Color(0xFF64B5F6),
                            ),
                            const SizedBox(height: 6),
                            _RewardRow(
                              label: l10n.totalGold,
                              value: '+$_earnedGold',
                              color: AppColors.gold,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          // Yenilgide tam ödül ver, sonra yeniden başla
                          _grantRewards(xpPercent: 1.0, goldPercent: 1.0, giveItems: true);
                          _restartBattle();
                        },
                        child: Text(l10n.retry),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton(
                        onPressed: () {
                          // Yenilgide tam ödül ver, sonra menüye dön
                          _grantRewards(xpPercent: 1.0, goldPercent: 1.0, giveItems: true);
                          context.go('/game');
                        },
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
