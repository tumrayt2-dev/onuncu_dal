import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';
import '../data/json_loader.dart';
import '../providers/player_provider.dart';
import '../widgets/bottom_nav.dart';

class StageMapScreen extends ConsumerStatefulWidget {
  const StageMapScreen({super.key});

  @override
  ConsumerState<StageMapScreen> createState() => _StageMapScreenState();
}

class _StageMapScreenState extends ConsumerState<StageMapScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(playerProvider) == null) {
        ref.read(playerProvider.notifier).loadFromSave();
      }
      _scrollToActive();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive() {
    final hero = ref.read(playerProvider);
    if (hero == null) return;
    final activeStage = hero.maxStage.clamp(1, 50);
    // Her item ~90px, aktif stage'i ekranın üst kısmında göster (2 item üstte)
    final offset = ((activeStage - 3) * 90.0).clamp(0.0, double.infinity);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void _showStageDetail(BuildContext context, AppLocalizations l10n, int stage, bool canFight) {
    final isBoss = stage == 50;
    final isMiniBoss = stage % 10 == 0 && stage != 50;

    // JSON'dan stage ödül bilgisi
    final stageData = JsonLoader.instance.stages
        .where((s) => s.stageId == stage)
        .firstOrNull;
    final goldMin = stageData?.rewards.goldMin ?? 0;
    final goldMax = stageData?.rewards.goldMax ?? 0;
    final xp = stageData?.rewards.xp ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isBoss ? '🐉' : isMiniBoss ? '⚔️' : '🗡️',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.stage} $stage',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isBoss
                          ? 'World Boss'
                          : isMiniBoss
                              ? 'Mini Boss'
                              : '${l10n.wave} 1-8',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Gerçek ödül bilgileri
            Row(
              children: [
                if (goldMax > 0) ...[
                  _rewardChip('💰', '$goldMin–$goldMax'),
                  const SizedBox(width: 8),
                ],
                if (xp > 0) ...[
                  _rewardChip('⭐', '$xp XP'),
                  const SizedBox(width: 8),
                ],
                _rewardChip('🎁', 'Item'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canFight
                    ? () {
                        Navigator.of(ctx).pop();
                        // Seçilen stage'i aktif yap, sonra savaşa git
                        ref.read(playerProvider.notifier).setCurrentStage(stage);
                        context.go('/battle');
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.play),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardChip(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textDim),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hero = ref.watch(playerProvider);
    final l10n = AppLocalizations.of(context)!;

    if (hero == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final currentStage = hero.currentStage.clamp(1, 50);
    final maxStage = hero.maxStage.clamp(1, 50);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.gold, size: 20),
          onPressed: () => context.go('/'),
        ),
        title: Row(
          children: [
            // Dünya seçici (şimdilik sadece D1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌲', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'Dünya 1',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Altın göstergesi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('💰', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    _formatGold(hero.gold),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 50,
        itemBuilder: (context, index) {
          final stage = index + 1; // 1'den 50'ye
          final isCompleted = stage < maxStage;
          final isActive = stage == currentStage;
          final isLocked = stage > maxStage;

          final isBoss = stage == 50;
          final isMiniBoss = stage % 10 == 0 && stage != 50;
          final canFight = !isLocked;

          final isMaxStage = stage == maxStage;

          return _StageCard(
            stage: stage,
            isCompleted: isCompleted,
            isActive: isActive,
            isMaxStage: isMaxStage,
            isLocked: isLocked,
            isBoss: isBoss,
            isMiniBoss: isMiniBoss,
            stars: isCompleted ? _stageStars(stage, hero.maxStage) : 0,
            onTap: () => _showStageDetail(context, l10n, stage, canFight),
          );
        },
      ),
      bottomNavigationBar: BottomNav(currentIndex: 0),
    );
  }

  String _formatGold(int gold) {
    if (gold >= 1000000) return '${(gold / 1000000).toStringAsFixed(1)}M';
    if (gold >= 1000) return '${(gold / 1000).toStringAsFixed(1)}K';
    return '$gold';
  }

  // Şimdilik basit — ileride gerçek yıldız verisi save'e eklenecek
  int _stageStars(int stage, int maxStage) {
    if (stage < maxStage - 5) return 3;
    if (stage < maxStage - 2) return 2;
    return 1;
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.isCompleted,
    required this.isActive,
    required this.isMaxStage,
    required this.isLocked,
    required this.isBoss,
    required this.isMiniBoss,
    required this.stars,
    required this.onTap,
  });

  final int stage;
  final bool isCompleted;
  final bool isActive;
  final bool isMaxStage;
  final bool isLocked;
  final bool isBoss;
  final bool isMiniBoss;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? AppColors.gold
        : isCompleted
            ? const Color(0xFF4CAF50).withValues(alpha: 0.6)
            : AppColors.textDim.withValues(alpha: 0.3);

    final bgColor = isActive
        ? AppColors.gold.withValues(alpha: 0.08)
        : isBoss
            ? const Color(0xFF8B0000).withValues(alpha: 0.15)
            : isMiniBoss
                ? const Color(0xFF6A1B9A).withValues(alpha: 0.12)
                : AppColors.surface;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Stage ikon
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLocked
                          ? AppColors.textDim.withValues(alpha: 0.1)
                          : isBoss
                              ? const Color(0xFF8B0000).withValues(alpha: 0.3)
                              : isMiniBoss
                                  ? const Color(0xFF6A1B9A).withValues(alpha: 0.3)
                                  : AppColors.background,
                      border: Border.all(
                        color: isLocked
                            ? AppColors.textDim.withValues(alpha: 0.3)
                            : borderColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isLocked
                            ? '🔒'
                            : isBoss
                                ? '🐉'
                                : isMiniBoss
                                    ? '⚔️'
                                    : isCompleted
                                        ? '✓'
                                        : '🗡️',
                        style: TextStyle(
                          fontSize: isBoss ? 20 : 16,
                          color: isCompleted && !isBoss && !isMiniBoss
                              ? const Color(0xFF4CAF50)
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Aktif göstergesi
                  if (isActive)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Stage bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Stage $stage',
                        style: TextStyle(
                          color: isLocked
                              ? AppColors.textDim
                              : isActive
                                  ? AppColors.gold
                                  : AppColors.textPrimary,
                          fontSize: isBoss ? 16 : 15,
                          fontWeight: isActive || isBoss
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isBoss) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B0000),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BOSS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (isMiniBoss) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A1B9A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ELITE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isActive)
                    const Text(
                      '▶ Seçili',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                      ),
                    )
                  else if (isMaxStage)
                    const Text(
                      '▶ Son',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            // Yıldızlar (tamamlananlar için)
            if (isCompleted)
              Row(
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: AppColors.gold,
                    size: 16,
                  ),
                ),
              )
            else if (isLocked)
              const Icon(Icons.lock, color: AppColors.textDim, size: 18),
          ],
        ),
      ),
    );
  }
}
