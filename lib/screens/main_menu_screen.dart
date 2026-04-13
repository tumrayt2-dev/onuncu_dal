import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';
import '../providers/player_provider.dart';
import '../services/save_service.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    // Kayıtlı oyuncuyu yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProvider.notifier).loadFromSave();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hero = ref.watch(playerProvider);
    final hasSave = SaveService.instance.hasSave();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A3E),
              AppColors.background,
              Color(0xFF0A0A12),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingXL,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Title
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: AppColors.gold,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.gold,
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                if (hasSave && hero != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${hero.name} - Lv.${hero.level}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
                const Spacer(flex: 3),
                // Buttons
                if (hasSave) ...[
                  _MenuButton(
                    label: l10n.continueGame,
                    onPressed: () => context.go('/game'),
                    isPrimary: true,
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  _MenuButton(
                    label: l10n.newGame,
                    onPressed: () => _confirmNewGame(context, l10n),
                  ),
                ] else ...[
                  _MenuButton(
                    label: l10n.play,
                    onPressed: () => context.go('/select'),
                    isPrimary: true,
                  ),
                ],
                const SizedBox(height: AppSizes.paddingM),
                _MenuButton(
                  label: l10n.settings,
                  onPressed: () => context.go('/settings'),
                ),
                const SizedBox(height: AppSizes.paddingM),
                _MenuButton(
                  label: l10n.exit,
                  onPressed: () => SystemNavigator.pop(),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmNewGame(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.deleteWarningTitle,
          style: const TextStyle(color: AppColors.gold),
        ),
        content: Text(
          l10n.deleteWarningBody,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(playerProvider.notifier).deleteSave();
              if (ctx.mounted) ctx.go('/select');
            },
            child: Text(l10n.confirm,
                style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
