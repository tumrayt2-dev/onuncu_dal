import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';
import '../providers/locale_provider.dart';
import '../providers/player_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _notifEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        children: [
          // Dil
          _SectionTitle(l10n.language),
          _LanguageTile(
            title: l10n.turkish,
            localeCode: 'tr',
            flag: 'TR',
            isSelected: currentLocale == 'tr',
            onTap: () => ref
                .read(localeProvider.notifier)
                .setLocale(const Locale('tr')),
          ),
          _LanguageTile(
            title: l10n.english,
            localeCode: 'en',
            flag: 'EN',
            isSelected: currentLocale == 'en',
            onTap: () => ref
                .read(localeProvider.notifier)
                .setLocale(const Locale('en')),
          ),
          const SizedBox(height: AppSizes.paddingL),
          // Ses / Muzik
          _SectionTitle(l10n.sound),
          SwitchListTile(
            title: Text(l10n.sound,
                style: const TextStyle(color: AppColors.textPrimary)),
            value: _soundEnabled,
            activeTrackColor: AppColors.gold,
            onChanged: (v) => setState(() => _soundEnabled = v),
          ),
          SwitchListTile(
            title: Text(l10n.music,
                style: const TextStyle(color: AppColors.textPrimary)),
            value: _musicEnabled,
            activeTrackColor: AppColors.gold,
            onChanged: (v) => setState(() => _musicEnabled = v),
          ),
          SwitchListTile(
            title: Text(l10n.notifications,
                style: const TextStyle(color: AppColors.textPrimary)),
            value: _notifEnabled,
            activeTrackColor: AppColors.gold,
            onChanged: (v) => setState(() => _notifEnabled = v),
          ),
          // Debug panel — sadece debug modda gorunur
          if (kDebugMode) ...[
            const SizedBox(height: AppSizes.paddingL),
            const _SectionTitle('DEV'),
            _DebugButton(
              label: '+10 Level',
              icon: Icons.trending_up,
              onTap: () {
                final hero = ref.read(playerProvider);
                if (hero == null) return;
                // Her level icin gereken XP'yi topla
                int totalXp = 0;
                for (int i = 0; i < 10; i++) {
                  totalXp += (100 * math.pow(hero.level + i, 1.6)).floor();
                }
                ref.read(playerProvider.notifier).addXp(totalXp);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('+10 Level (Lv ${hero.level + 10})')),
                );
              },
            ),
            _DebugButton(
              label: '+1000 Gold',
              icon: Icons.monetization_on,
              onTap: () {
                ref.read(playerProvider.notifier).addGold(1000);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('+1000 Gold')),
                );
              },
            ),
            _DebugButton(
              label: '+5 Stage',
              icon: Icons.skip_next,
              onTap: () {
                final hero = ref.read(playerProvider);
                if (hero == null) return;
                ref.read(playerProvider.notifier).updateStage(
                  hero.currentStage + 5,
                  hero.currentWorldId,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stage ${hero.currentStage + 5}')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.localeCode,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String localeCode;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.textDim,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          flag,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.gold : AppColors.textSecondary,
          ),
        ),
      ),
      title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.gold)
          : null,
      onTap: onTap,
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange, size: 24),
      title: Text(label,
          style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
      onTap: onTap,
    );
  }
}
