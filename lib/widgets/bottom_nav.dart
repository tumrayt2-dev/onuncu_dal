import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.textDim.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.map_outlined,
                label: l10n.stage,
                active: currentIndex == 0,
                onTap: () => context.go('/stage-map'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: l10n.character,
                active: currentIndex == 1,
                onTap: () => context.go('/character'),
              ),
              _NavItem(
                icon: Icons.auto_fix_high,
                label: l10n.blacksmith,
                active: currentIndex == 2,
                onTap: () => context.go('/upgrade'),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: l10n.settings,
                active: currentIndex == 3,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? AppColors.gold : AppColors.textDim,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.gold : AppColors.textDim,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
