import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';
import '../models/affix.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../providers/player_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(playerProvider);
    final l10n = AppLocalizations.of(context)!;

    if (hero == null) return const SizedBox.shrink();

    final items = hero.inventory;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => context.go('/game'),
        ),
        title: Text(
          l10n.inventory,
          style: const TextStyle(color: AppColors.gold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${hero.gold}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                l10n.emptyInventory,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 16,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _InventorySlot(
                  item: item,
                  onTap: () => _showItemDetail(context, ref, item, l10n),
                );
              },
            ),
    );
  }

  void _showItemDetail(
    BuildContext context,
    WidgetRef ref,
    Item item,
    AppLocalizations l10n,
  ) {
    final rarityColor = Color(item.rarity.colorHex);
    final sellPrice = PlayerNotifier.sellPrice(item.rarity);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: item name + rarity
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rarityColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _slotIcon(item.slot),
                      style: TextStyle(color: rarityColor, fontSize: 18),
                    ),
                  ),
                ),
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
                          color: rarityColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_rarityL10n(l10n, item.rarity)} | '
                        '${_slotL10n(l10n, item.slot)} | '
                        '${l10n.iLevel} ${item.iLevel}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Base stats
            _buildStatRows(l10n, item.baseStats),

            // Affixes
            if (item.affixes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(color: AppColors.textDim, height: 1),
              const SizedBox(height: 8),
              ...item.affixes.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${_affixL10n(l10n, a.type)} +${a.value.toStringAsFixed(a.isPercent ? 1 : 0)}${a.isPercent ? '%' : ''}',
                    style: TextStyle(
                      color: rarityColor.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(playerProvider.notifier).equipItem(item, item.slot);
                    },
                    child: Text(l10n.equip),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _confirmSell(context, ref, item, l10n, sellPrice);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                    ),
                    child: Text('${l10n.sell} ($sellPrice G)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmSell(
    BuildContext context,
    WidgetRef ref,
    Item item,
    AppLocalizations l10n,
    int price,
  ) {
    // Rare+ items get a confirmation dialog
    if (item.rarity.index >= Rarity.rare.index) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(
            l10n.sell,
            style: const TextStyle(color: AppColors.gold),
          ),
          content: Text(
            l10n.sellConfirm('$price'),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(playerProvider.notifier).sellItem(item);
              },
              child: Text(
                l10n.confirm,
                style: const TextStyle(color: AppColors.gold),
              ),
            ),
          ],
        ),
      );
    } else {
      ref.read(playerProvider.notifier).sellItem(item);
    }
  }

  Widget _buildStatRows(AppLocalizations l10n, stats) {
    final entries = <MapEntry<String, double>>[];
    if (stats.hp > 0) entries.add(MapEntry(l10n.hp, stats.hp));
    if (stats.atk > 0) entries.add(MapEntry(l10n.atk, stats.atk));
    if (stats.def > 0) entries.add(MapEntry(l10n.def, stats.def));
    if (stats.spd > 0) entries.add(MapEntry(l10n.spd, stats.spd));
    if (stats.crit > 0) entries.add(MapEntry('CRIT', stats.crit));
    if (stats.critDmg > 0) entries.add(MapEntry('CRIT DMG', stats.critDmg));

    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: entries.map((e) {
        return Text(
          '${e.key}: ${e.value.toStringAsFixed(e.value == e.value.roundToDouble() ? 0 : 1)}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        );
      }).toList(),
    );
  }

  String _slotIcon(EquipmentSlot slot) => switch (slot) {
        EquipmentSlot.weapon => 'W',
        EquipmentSlot.helmet => 'H',
        EquipmentSlot.chest => 'C',
        EquipmentSlot.gloves => 'G',
        EquipmentSlot.pants => 'P',
        EquipmentSlot.boots => 'B',
        EquipmentSlot.ring1 => 'R',
        EquipmentSlot.ring2 => 'R',
        EquipmentSlot.amulet => 'A',
      };

  String _slotL10n(AppLocalizations l10n, EquipmentSlot slot) => switch (slot) {
        EquipmentSlot.weapon => l10n.slotWeapon,
        EquipmentSlot.helmet => l10n.slotHelmet,
        EquipmentSlot.chest => l10n.slotChest,
        EquipmentSlot.gloves => l10n.slotGloves,
        EquipmentSlot.pants => l10n.slotPants,
        EquipmentSlot.boots => l10n.slotBoots,
        EquipmentSlot.ring1 => l10n.slotRing1,
        EquipmentSlot.ring2 => l10n.slotRing2,
        EquipmentSlot.amulet => l10n.slotAmulet,
      };

  String _rarityL10n(AppLocalizations l10n, Rarity rarity) => switch (rarity) {
        Rarity.common => l10n.rarityCommon,
        Rarity.uncommon => l10n.rarityUncommon,
        Rarity.rare => l10n.rarityRare,
        Rarity.epic => l10n.rarityEpic,
        Rarity.legendary => l10n.rarityLegendary,
        Rarity.mythic => l10n.rarityMythic,
      };

  String _affixL10n(AppLocalizations l10n, AffixType type) => switch (type) {
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
}

class _InventorySlot extends StatelessWidget {
  const _InventorySlot({required this.item, required this.onTap});

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(item.rarity.colorHex);
    final isRarePlus = item.rarity.index >= Rarity.rare.index;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: rarityColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: rarityColor.withValues(alpha: isRarePlus ? 0.8 : 0.4),
            width: isRarePlus ? 2 : 1,
          ),
          boxShadow: isRarePlus
              ? [
                  BoxShadow(
                    color: rarityColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Slot icon placeholder
            Text(
              _slotLetter(item.slot),
              style: TextStyle(
                color: rarityColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            // Upgrade level
            if (item.upgradeLevel > 0)
              Text(
                '+${item.upgradeLevel}',
                style: TextStyle(
                  color: rarityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _slotLetter(EquipmentSlot slot) => switch (slot) {
        EquipmentSlot.weapon => 'W',
        EquipmentSlot.helmet => 'H',
        EquipmentSlot.chest => 'C',
        EquipmentSlot.gloves => 'G',
        EquipmentSlot.pants => 'P',
        EquipmentSlot.boots => 'B',
        EquipmentSlot.ring1 => 'R',
        EquipmentSlot.ring2 => 'R',
        EquipmentSlot.amulet => 'A',
      };
}
