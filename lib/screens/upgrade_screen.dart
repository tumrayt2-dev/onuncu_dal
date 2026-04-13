import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';
import '../models/affix.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../providers/player_provider.dart';
import '../widgets/bottom_nav.dart';

/// Demirci Kübey — Item upgrade + enchant ekranı
class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen>
    with SingleTickerProviderStateMixin {
  Item? _selectedItem;
  Item? _selectedFodder;
  String? _resultMessage;
  Color? _resultColor;
  bool _isAnimating = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 8).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(playerProvider) == null) {
        ref.read(playerProvider.notifier).loadFromSave();
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
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

    // Item listesi (equipment + inventory)
    final allItems = <Item>[
      ...hero.equipment.values,
      ...hero.inventory,
    ];

    // Secili item hala mevcut mu kontrol
    if (_selectedItem != null &&
        !allItems.any((i) => i.id == _selectedItem!.id)) {
      _selectedItem = null;
      _selectedFodder = null;
    }

    // Fodder adaylari: envanterdeki ayni rarity itemler (secili item haric)
    final fodderCandidates = _selectedItem != null
        ? hero.inventory
            .where((i) =>
                i.rarity == _selectedItem!.rarity &&
                i.id != _selectedItem!.id)
            .toList()
        : <Item>[];

    // Secili fodder hala mevcut mu
    if (_selectedFodder != null &&
        !fodderCandidates.any((i) => i.id == _selectedFodder!.id)) {
      _selectedFodder = null;
    }

    final cost =
        _selectedItem != null ? PlayerNotifier.upgradeCost(_selectedItem!) : 0;
    final rate = _selectedItem != null
        ? PlayerNotifier.upgradeSuccessRate(_selectedItem!.upgradeLevel)
        : 1.0;
    final canUpgrade = _selectedItem != null &&
        _selectedFodder != null &&
        hero.gold >= cost &&
        _selectedItem!.upgradeLevel < 20 &&
        !_isAnimating;

    final enchantCost = _selectedItem != null
        ? PlayerNotifier.enchantCost(_selectedItem!)
        : 0;
    final canEnchant = _selectedItem != null &&
        _selectedItem!.affixes.length < _selectedItem!.rarity.affixCount &&
        hero.gold >= enchantCost &&
        !_isAnimating;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => context.go('/game'),
        ),
        title: Text(l10n.blacksmith,
            style: const TextStyle(color: AppColors.gold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text('${hero.gold}',
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- İksir ---
            _buildPotionSection(context, hero),
            const SizedBox(height: 16),
            // --- Item Sec ---
            Text(l10n.selectItem,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final item = allItems[i];
                  final selected = _selectedItem?.id == item.id;
                  final color = Color(item.rarity.colorHex);
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedItem = item;
                      _selectedFodder = null;
                      _resultMessage = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.3)
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? color : color.withValues(alpha: 0.3),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_slotEmoji(item.slot),
                              style: const TextStyle(fontSize: 18)),
                          if (item.upgradeLevel > 0)
                            Text('+${item.upgradeLevel}',
                                style: TextStyle(
                                    color: color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // --- Secili Item Detay ---
            if (_selectedItem != null) ...[
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (ctx, child) {
                  return Transform.translate(
                    offset: Offset(
                        _shakeCtrl.isAnimating
                            ? _shakeAnim.value *
                                ((_shakeCtrl.value * 10).floor().isOdd
                                    ? 1
                                    : -1)
                            : 0,
                        0),
                    child: child,
                  );
                },
                child: _buildItemCard(l10n, _selectedItem!),
              ),
              const SizedBox(height: 12),

              // Upgrade bolumu
              _buildUpgradeSection(
                  l10n, cost, rate, canUpgrade, fodderCandidates),
              const SizedBox(height: 12),

              // Enchant bolumu
              _buildEnchantSection(l10n, enchantCost, canEnchant),

              // Sonuc mesaji
              if (_resultMessage != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _resultMessage!,
                    style: TextStyle(
                      color: _resultColor ?? AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(l10n.selectItem,
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(AppLocalizations l10n, Item item) {
    final color = Color(item.rarity.colorHex);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Text(_slotEmoji(item.slot), style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _itemNameL10n(l10n, item.nameKey) +
                      (item.upgradeLevel > 0
                          ? ' +${item.upgradeLevel}'
                          : ''),
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_rarityL10n(l10n, item.rarity)} | ${l10n.iLevel} ${item.iLevel}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
                if (item.affixes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: item.affixes.map((a) {
                      return Text(
                        '${_affixL10n(l10n, a.type)} +${a.value.toStringAsFixed(a.isPercent ? 1 : 0)}${a.isPercent ? '%' : ''}',
                        style: TextStyle(
                            color: color.withValues(alpha: 0.7),
                            fontSize: 10),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeSection(AppLocalizations l10n, int cost, double rate,
      bool canUpgrade, List<Item> fodderCandidates) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.upgradeItem,
              style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),

          // Maliyet + basari orani
          Row(
            children: [
              const Icon(Icons.monetization_on,
                  color: AppColors.gold, size: 14),
              const SizedBox(width: 4),
              Text('$cost',
                  style:
                      const TextStyle(color: AppColors.gold, fontSize: 12)),
              const SizedBox(width: 16),
              Text('${l10n.successRate}: ${(rate * 100).toInt()}%',
                  style: TextStyle(
                    color: rate >= 1.0
                        ? const Color(0xFF4CAF50)
                        : (rate >= 0.7
                            ? AppColors.gold
                            : const Color(0xFFFF4444)),
                    fontSize: 12,
                  )),
            ],
          ),
          const SizedBox(height: 6),

          // Fodder sec
          Text(l10n.selectFodder,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          if (fodderCandidates.isEmpty)
            Text(l10n.noFodder,
                style:
                    const TextStyle(color: AppColors.textDim, fontSize: 11))
          else
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fodderCandidates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (_, i) {
                  final f = fodderCandidates[i];
                  final selected = _selectedFodder?.id == f.id;
                  final color = Color(f.rarity.colorHex);
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedFodder = f),
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.3)
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: selected
                              ? color
                              : color.withValues(alpha: 0.3),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(_slotEmoji(f.slot),
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),

          // Upgrade butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canUpgrade ? _doUpgrade : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
              ),
              child: Text(
                _selectedItem != null && _selectedItem!.upgradeLevel >= 20
                    ? l10n.maxUpgrade
                    : l10n.upgradeItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnchantSection(
      AppLocalizations l10n, int cost, bool canEnchant) {
    final item = _selectedItem!;
    final currentAffixes = item.affixes.length;
    final maxAffixes = item.rarity.affixCount;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.enchantItem,
                  style: const TextStyle(
                      color: Color(0xFF9C27B0),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('$currentAffixes / $maxAffixes',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.monetization_on,
                  color: AppColors.gold, size: 14),
              const SizedBox(width: 4),
              Text('$cost',
                  style:
                      const TextStyle(color: AppColors.gold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),

          // Mevcut affix'ler + reroll
          if (item.affixes.isNotEmpty) ...[
            ...item.affixes.asMap().entries.map((entry) {
              final a = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_affixL10n(l10n, a.type)} +${a.value.toStringAsFixed(a.isPercent ? 1 : 0)}${a.isPercent ? '%' : ''}',
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isAnimating
                          ? null
                          : () => _doReroll(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFF9C27B0)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Text(l10n.rerollAffix,
                            style: const TextStyle(
                                color: Color(0xFF9C27B0), fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
          ],

          // Enchant butonu
          if (currentAffixes < maxAffixes)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: canEnchant ? _doEnchant : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9C27B0),
                ),
                child: Text(l10n.enchantItem),
              ),
            )
          else
            Center(
              child: Text(l10n.enchantFull,
                  style: const TextStyle(
                      color: AppColors.textDim, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Future<void> _doUpgrade() async {
    if (_selectedItem == null || _selectedFodder == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isAnimating = true);

    final success = await ref
        .read(playerProvider.notifier)
        .upgradeItem(_selectedItem!, _selectedFodder!);

    if (success) {
      // Basari — yesil flash
      setState(() {
        _resultMessage = l10n.upgradeSuccess(
            '${_selectedItem!.upgradeLevel + 1}');
        _resultColor = const Color(0xFF4CAF50);
      });
      // Secili item'i guncelle (artik +1)
      _refreshSelectedItem();
    } else {
      // Basarisizlik — kirmizi titreme
      _shakeCtrl.forward(from: 0);
      setState(() {
        _resultMessage = l10n.upgradeFail;
        _resultColor = const Color(0xFFFF4444);
      });
    }

    _selectedFodder = null;

    setState(() => _isAnimating = false);
    // Mesaji 2sn sonra temizle
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _resultMessage = null);
    });
  }

  Future<void> _doEnchant() async {
    if (_selectedItem == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isAnimating = true);

    final affix = await ref
        .read(playerProvider.notifier)
        .enchantItem(_selectedItem!);

    if (affix != null) {
      setState(() {
        _resultMessage = l10n.affixAdded;
        _resultColor = const Color(0xFF9C27B0);
      });
      _refreshSelectedItem();
    }

    setState(() => _isAnimating = false);
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _resultMessage = null);
    });
  }

  Future<void> _doReroll(int affixIndex) async {
    if (_selectedItem == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isAnimating = true);

    final affix = await ref
        .read(playerProvider.notifier)
        .rerollAffix(_selectedItem!, affixIndex);

    if (affix != null) {
      setState(() {
        _resultMessage = l10n.affixRerolled;
        _resultColor = const Color(0xFF9C27B0);
      });
      _refreshSelectedItem();
    }

    setState(() => _isAnimating = false);
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _resultMessage = null);
    });
  }

  /// Secili item state'ten yeniden bul (upgrade/enchant sonrasi ID ayni kalir)
  void _refreshSelectedItem() {
    final hero = ref.read(playerProvider);
    if (hero == null || _selectedItem == null) return;

    // Equipment'ta ara
    for (final item in hero.equipment.values) {
      if (item.id == _selectedItem!.id) {
        _selectedItem = item;
        return;
      }
    }
    // Envanterde ara
    for (final item in hero.inventory) {
      if (item.id == _selectedItem!.id) {
        _selectedItem = item;
        return;
      }
    }
    _selectedItem = null;
  }

  // --- L10n helpers ---
  String _slotEmoji(EquipmentSlot slot) => switch (slot) {
    EquipmentSlot.weapon => '\u{2694}',
    EquipmentSlot.helmet => '\u{26D1}',
    EquipmentSlot.chest => '\u{1F6E1}',
    EquipmentSlot.gloves => '\u{1F9E4}',
    EquipmentSlot.pants => '\u{1FA73}',
    EquipmentSlot.boots => '\u{1F462}',
    EquipmentSlot.ring1 => '\u{1F48D}',
    EquipmentSlot.ring2 => '\u{1F48D}',
    EquipmentSlot.amulet => '\u{1F4FF}',
  };

  String _rarityL10n(AppLocalizations l10n, Rarity r) => switch (r) {
    Rarity.common => l10n.rarityCommon,
    Rarity.uncommon => l10n.rarityUncommon,
    Rarity.rare => l10n.rarityRare,
    Rarity.epic => l10n.rarityEpic,
    Rarity.legendary => l10n.rarityLegendary,
    Rarity.mythic => l10n.rarityMythic,
  };

  String _affixL10n(AppLocalizations l10n, AffixType t) => switch (t) {
    AffixType.atkPercent => l10n.affixAtkPercent,
    AffixType.hpFlat => l10n.affixHpFlat,
    AffixType.critPercent => l10n.affixCritPercent,
    AffixType.critDmgPercent => l10n.affixCritDmgPercent,
    AffixType.lifestealPercent => l10n.affixLifestealPercent,
    AffixType.spdFlat => l10n.affixSpdFlat,
    AffixType.goldFindPercent => l10n.affixGoldFindPercent,
    AffixType.magicFindPercent => l10n.affixMagicFindPercent,
    AffixType.dodgePercent => l10n.affixDodgePercent,
    AffixType.resistPercent => l10n.affixResistPercent,
    AffixType.hpRegenFlat => l10n.affixHpRegenFlat,
    AffixType.elementDmgPercent => l10n.affixElementDmgPercent,
  };

  String _itemNameL10n(AppLocalizations l10n, String key) => switch (key) {
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

  Widget _buildPotionSection(BuildContext context, dynamic hero) {
    final potions = hero.potions as int;
    final gold = hero.gold as int;
    final canBuy = potions < 3 && gold >= PlayerNotifier.potionCost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧪', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Text(
                'İksir',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Stok göstergesi
              Row(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      i < potions ? Icons.circle : Icons.circle_outlined,
                      color: i < potions
                          ? const Color(0xFF4CAF50)
                          : AppColors.textDim,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'HP\'nin %${PlayerNotifier.potionHealPercent}\'ini iyileştirir  •  ${PlayerNotifier.potionCost} 💰',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: ElevatedButton(
                  onPressed: canBuy
                      ? () async {
                          final ok = await ref
                              .read(playerProvider.notifier)
                              .buyPotion();
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('İksir satın alındı!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(
                    potions >= 3 ? 'Dolu' : 'Al',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
