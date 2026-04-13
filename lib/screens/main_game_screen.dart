import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';
import '../data/json_loader.dart';
import '../models/enums.dart';
import '../providers/player_provider.dart';

/// Gecici ana oyun ekrani - ileride stage map olacak
class MainGameScreen extends ConsumerWidget {
  const MainGameScreen({super.key});

  String _heroClassName(AppLocalizations l10n, HeroClass cls) => switch (cls) {
        HeroClass.kalkanEr => l10n.heroKalkanEr,
        HeroClass.kurtBoru => l10n.heroKurtBoru,
        HeroClass.kam => l10n.heroKam,
        HeroClass.yayCi => l10n.heroYayCi,
        HeroClass.golgeBek => l10n.heroGolgeBek,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(playerProvider);
    final l10n = AppLocalizations.of(context)!;

    if (hero == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home, color: AppColors.gold),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.welcomeHero(hero.name),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Level ${hero.level} | ${_heroClassName(l10n, hero.heroClass)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final heroId = switch (hero.heroClass) {
                HeroClass.kalkanEr => 'kalkan_er',
                HeroClass.kurtBoru => 'kurt_boru',
                HeroClass.kam => 'kam',
                HeroClass.yayCi => 'yay_ci',
                HeroClass.golgeBek => 'golge_bek',
              };
              final perLevel = JsonLoader.instance.getHeroPerLevel(heroId);
              final stats = hero.effectiveStats(perLevel);
              return Text(
                '${l10n.hp}: ${stats.hp.toInt()} | '
                '${l10n.atk}: ${stats.atk.toInt()} | '
                '${l10n.def}: ${stats.def.toInt()}',
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 14,
                ),
              );
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => context.go('/battle'),
                child: Text('Stage ${hero.currentStage}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
