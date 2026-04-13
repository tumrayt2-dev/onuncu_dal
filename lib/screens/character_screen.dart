import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';
import '../models/affix.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/stats.dart';
import '../providers/player_provider.dart';
import '../services/stat_calculator.dart';

/// Slot emoji helper (top-level, tum widget'lar kullanabilir)
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

/// Birlesik karakter ekrani: Ekipman + Statlar + Envanter
class CharacterScreen extends ConsumerStatefulWidget {
  const CharacterScreen({super.key});

  @override
  ConsumerState<CharacterScreen> createState() => _CharacterScreenState();
}

enum _SortMode { rarity, iLevel }

class _CharacterScreenState extends ConsumerState<CharacterScreen> {
  // Stat dagitim
  final Map<String, int> _pending = {
    'hp': 0, 'atk': 0, 'def': 0, 'spd': 0, 'crit': 0,
  };
  int get _pendingTotal => _pending.values.fold(0, (a, b) => a + b);

  _SortMode _sortMode = _SortMode.rarity;

  void _inc(String k, int avail) {
    if (_pendingTotal >= avail) return;
    setState(() => _pending[k] = _pending[k]! + 1);
  }

  void _dec(String k) {
    if (_pending[k]! <= 0) return;
    setState(() => _pending[k] = _pending[k]! - 1);
  }

  void _resetPending() {
    setState(() {
      for (final k in _pending.keys) {
        _pending[k] = 0;
      }
    });
  }

  void _apply() {
    if (_pendingTotal <= 0) return;
    ref.read(playerProvider.notifier).distributeStatPoints(Map.from(_pending));
    _resetPending();
  }

  void _auto() {
    ref.read(playerProvider.notifier).autoDistributeStats();
    _resetPending();
  }

  void _resetAll() {
    ref.read(playerProvider.notifier).resetStatPoints();
    _resetPending();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(playerProvider) == null) {
        ref.read(playerProvider.notifier).loadFromSave();
      }
    });
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

    final totalStats = StatCalculator.totalStats(hero);
    final available = hero.statPoints - _pendingTotal;

    // Envanteri sirala
    final inventory = List<Item>.from(hero.inventory);
    switch (_sortMode) {
      case _SortMode.rarity:
        inventory.sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
      case _SortMode.iLevel:
        inventory.sort((a, b) => b.iLevel.compareTo(a.iLevel));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => context.go('/game'),
        ),
        title: Text(hero.name, style: const TextStyle(color: AppColors.gold)),
        actions: [
          // Gold
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${hero.gold}',
                  style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ust kisim: Ekipman + Statlar (sabit, scroll etmez)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero bilgi satiri
                Center(
                  child: Text(
                    'Lv ${hero.level} | ${_heroClassL10n(l10n, hero.heroClass)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),

                // Ekipman grid (3x3 kompakt)
                _buildEquipmentGrid(l10n),
                const SizedBox(height: 8),

                // Kompakt statlar (tek satirda)
                _buildCompactStats(l10n, totalStats),

                // Stat dagitim (varsa)
                if (hero.statPoints > 0 || _pendingTotal > 0) ...[
                  const SizedBox(height: 8),
                  _buildStatDistribution(l10n, available, hero),
                ],

                const SizedBox(height: 8),

                // Envanter baslik + siralama
                Row(
                  children: [
                    Text(
                      '${l10n.inventory} (${inventory.length})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Siralama toggle
                    GestureDetector(
                      onTap: () => setState(() {
                        _sortMode = _sortMode == _SortMode.rarity
                            ? _SortMode.iLevel
                            : _SortMode.rarity;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort, color: AppColors.textDim, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _sortMode == _SortMode.rarity ? l10n.sortByRarity : l10n.sortByLevel,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          // Alt kisim: Envanter grid (scrollable)
          Expanded(
            child: inventory.isEmpty
                ? Center(
                    child: Text(
                      l10n.emptyInventory,
                      style: const TextStyle(color: AppColors.textDim, fontSize: 14),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: inventory.length,
                    itemBuilder: (context, index) {
                      final item = inventory[index];
                      return _InventorySlot(
                        item: item,
                        onTap: () => _showItemDetail(context, l10n, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Ekipman Grid (3x3 kompakt) ---
  Widget _buildEquipmentGrid(AppLocalizations l10n) {
    final hero = ref.watch(playerProvider)!;
    final slots = EquipmentSlot.values;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.6,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final item = hero.equipment[slot];
        return _buildSlotTile(l10n, slot, item);
      },
    );
  }

  Widget _buildSlotTile(AppLocalizations l10n, EquipmentSlot slot, Item? item) {
    final hasItem = item != null;
    final rarityColor = hasItem ? Color(item.rarity.colorHex) : AppColors.textDim;

    return GestureDetector(
      onTap: () => _showEquipmentAction(context, l10n, slot, item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: hasItem ? rarityColor.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasItem ? rarityColor.withValues(alpha: 0.6) : AppColors.textDim.withValues(alpha: 0.3),
            width: hasItem ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _slotIcon(slot),
              style: TextStyle(
                color: hasItem ? rarityColor : AppColors.textDim,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              hasItem ? _slotL10n(l10n, slot) : l10n.emptySlot,
              style: TextStyle(
                color: hasItem ? AppColors.textPrimary : AppColors.textDim,
                fontSize: 8,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- Kompakt stat satiri ---
  Widget _buildCompactStats(AppLocalizations l10n, Stats totalStats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 2,
        children: [
          _miniStat(l10n.hp, totalStats.hp.toInt().toString()),
          _miniStat(l10n.atk, totalStats.atk.toInt().toString()),
          _miniStat(l10n.def, totalStats.def.toInt().toString()),
          _miniStat(l10n.spd, totalStats.spd.toStringAsFixed(2)),
          _miniStat(l10n.critShort, '${totalStats.crit.toStringAsFixed(1)}%'),
          if (totalStats.critDmg > 0)
            _miniStat(l10n.critDmgShort, '${totalStats.critDmg.toInt()}%'),
          if (totalStats.dodge > 0)
            _miniStat(l10n.dodgeShort, '${totalStats.dodge.toStringAsFixed(1)}%'),
          if (totalStats.lifesteal > 0)
            _miniStat(l10n.lifestealShort, '${totalStats.lifesteal.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
        const SizedBox(width: 3),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- Stat Dagitim (kompakt) ---
  Widget _buildStatDistribution(AppLocalizations l10n, int available, hero) {
    final hasDistributed = hero.distributedStats.hp > 0 ||
        hero.distributedStats.atk > 0 || hero.distributedStats.def > 0 ||
        hero.distributedStats.spd > 0 || hero.distributedStats.crit > 0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                l10n.statPoints,
                style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Text(
                '($available)',
                style: const TextStyle(color: AppColors.gold, fontSize: 12),
              ),
              const Spacer(),
              _miniBtn(l10n.distribute, _pendingTotal > 0 ? _apply : null, AppColors.gold),
              const SizedBox(width: 4),
              _miniBtn(l10n.autoDistribute, hero.statPoints > 0 ? _auto : null, AppColors.textSecondary),
              const SizedBox(width: 4),
              _miniBtn(l10n.resetPoints, hasDistributed ? _resetAll : null, const Color(0xFFFF4444)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _distChip(l10n.hp, '+10', _pending['hp']!, () => _inc('hp', available), () => _dec('hp')),
              _distChip(l10n.atk, '+2', _pending['atk']!, () => _inc('atk', available), () => _dec('atk')),
              _distChip(l10n.def, '+2', _pending['def']!, () => _inc('def', available), () => _dec('def')),
              _distChip(l10n.spd, '+.01', _pending['spd']!, () => _inc('spd', available), () => _dec('spd')),
              _distChip(l10n.critShort, '+.5%', _pending['crit']!, () => _inc('crit', available), () => _dec('crit')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(String label, VoidCallback? onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: onTap != null ? color : AppColors.textDim.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap != null ? color : AppColors.textDim,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _distChip(String label, String bonus, int val, VoidCallback onAdd, VoidCallback onDec) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 9)),
          Text(bonus, style: const TextStyle(color: AppColors.textDim, fontSize: 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: val > 0 ? onDec : null,
                child: Icon(Icons.remove, size: 16, color: val > 0 ? AppColors.gold : AppColors.textDim),
              ),
              SizedBox(
                width: 20,
                child: Text(
                  '$val',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: val > 0 ? AppColors.gold : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onAdd,
                child: const Icon(Icons.add, size: 16, color: AppColors.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Item Detail Bottom Sheet (yan yana kiyaslama) ---
  void _showItemDetail(BuildContext context, AppLocalizations l10n, Item item) {
    final hero = ref.read(playerProvider)!;
    final rarityColor = Color(item.rarity.colorHex);
    final sellPrice = PlayerNotifier.sellPrice(item.rarity);
    final equipped = hero.equipment[item.slot];

    // Karsilastirilacak stat satirlari
    final statKeys = <String>['hp', 'atk', 'def', 'spd', 'crit', 'critDmg'];
    final statLabels = <String, String>{
      'hp': l10n.hp, 'atk': l10n.atk, 'def': l10n.def,
      'spd': l10n.spd, 'crit': l10n.critShort, 'critDmg': l10n.critDmgShort,
    };

    double getStat(Stats s, String key) => switch (key) {
      'hp' => s.hp, 'atk' => s.atk, 'def' => s.def,
      'spd' => s.spd, 'crit' => s.crit, 'critDmg' => s.critDmg,
      _ => 0,
    };

    // Yeni item ile tam stat (StatCalculator)
    final currentTotal = StatCalculator.totalStats(hero);
    final equipMap = Map<EquipmentSlot, Item>.from(hero.equipment);
    equipMap[item.slot] = item;
    final newTotal = StatCalculator.totalStats(hero.copyWith(equipment: equipMap));

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Baslik: Yeni item ismi
              Text(
                _itemNameL10n(l10n, item.nameKey) +
                    (item.upgradeLevel > 0 ? ' +${item.upgradeLevel}' : ''),
                style: TextStyle(color: rarityColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_rarityL10n(l10n, item.rarity)} | ${_slotL10n(l10n, item.slot)} | ${l10n.iLevel} ${item.iLevel}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 12),

              // Yan yana karsilastirma tablosu
              if (equipped != null) ...[
                // Header: Giyili vs Yeni
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _itemNameL10n(l10n, equipped.nameKey),
                        style: TextStyle(
                          color: Color(equipped.rarity.colorHex),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 60),
                    Expanded(
                      child: Text(
                        _itemNameL10n(l10n, item.nameKey),
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stat satirlari
                ...statKeys.map((key) {
                  final oldVal = getStat(currentTotal, key);
                  final newVal = getStat(newTotal, key);
                  final diff = newVal - oldVal;
                  final isBetter = diff > 0;
                  final isWorse = diff < 0;
                  final decimals = (key == 'spd' || key == 'crit' || key == 'critDmg') ? 1 : 0;
                  // Her iki deger de 0 ise gosterme
                  if (oldVal == 0 && newVal == 0) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        // Sol: mevcut deger
                        Expanded(
                          child: Text(
                            oldVal.toStringAsFixed(decimals),
                            style: TextStyle(
                              color: isWorse ? const Color(0xFF4CAF50) : (isBetter ? const Color(0xFFFF4444) : AppColors.textPrimary),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Orta: stat ismi
                        SizedBox(
                          width: 60,
                          child: Text(
                            statLabels[key]!,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Sag: yeni deger + fark
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                newVal.toStringAsFixed(decimals),
                                style: TextStyle(
                                  color: isBetter ? const Color(0xFF4CAF50) : (isWorse ? const Color(0xFFFF4444) : AppColors.textPrimary),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (diff != 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${isBetter ? '+' : ''}${diff.toStringAsFixed(decimals)}',
                                  style: TextStyle(
                                    color: isBetter ? const Color(0xFF4CAF50) : const Color(0xFFFF4444),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                // Giyili item yok — sadece yeni itemin statlarini goster
                _buildItemStatRows(l10n, item.baseStats),
                if (item.affixes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Divider(color: AppColors.textDim, height: 1),
                  const SizedBox(height: 6),
                  ...item.affixes.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${_affixL10n(l10n, a.type)} +${a.value.toStringAsFixed(a.isPercent ? 1 : 0)}${a.isPercent ? '%' : ''}',
                        style: TextStyle(color: rarityColor.withValues(alpha: 0.8), fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              // Butonlar
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
                        _confirmSell(context, item, l10n, sellPrice);
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.gold),
                      child: Text('${l10n.sell} ($sellPrice G)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // --- Equipment slot action (giyili item detay / degistir) ---
  void _showEquipmentAction(
    BuildContext context, AppLocalizations l10n, EquipmentSlot slot, Item? equipped,
  ) {
    final hero = ref.read(playerProvider)!;
    final candidates = hero.inventory.where((i) => i.slot == slot).toList()
      ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));

    if (equipped == null && candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noItemForSlot), backgroundColor: AppColors.surface),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _slotL10n(l10n, slot),
                style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Giyili item
              if (equipped != null) ...[
                _buildEquipListTile(ctx, l10n, equipped, null, isEquipped: true),
                if (candidates.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Divider(color: AppColors.textDim),
                  const SizedBox(height: 4),
                  Text(l10n.change, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                ],
              ],

              // Aday itemler
              ...candidates.map((item) {
                final diff = StatCalculator.compareItems(hero, item, equipped);
                return _buildEquipListTile(ctx, l10n, item, diff);
              }),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipListTile(BuildContext ctx, AppLocalizations l10n, Item item, Stats? diff, {bool isEquipped = false}) {
    final rarityColor = Color(item.rarity.colorHex);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: rarityColor),
            ),
            child: Center(
              child: Text(
                _slotIcon(item.slot),
                style: TextStyle(color: rarityColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _itemNameL10n(l10n, item.nameKey) +
                      (item.upgradeLevel > 0 ? ' +${item.upgradeLevel}' : ''),
                  style: TextStyle(color: rarityColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                if (diff != null) _buildDiffChips(diff),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: isEquipped
                ? OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(playerProvider.notifier).unequipItem(item.slot);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4444),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    child: Text(l10n.unequip),
                  )
                : ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(playerProvider.notifier).equipItem(item, item.slot);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    child: Text(l10n.equip),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Kiyaslama chip'leri ---
  Widget _buildDiffChips(Stats diff, {AppLocalizations? l10n}) {
    final l = l10n ?? AppLocalizations.of(context)!;
    final chips = <Widget>[];
    if (diff.hp != 0) chips.add(_diffChip(l.hp, diff.hp));
    if (diff.atk != 0) chips.add(_diffChip(l.atk, diff.atk));
    if (diff.def != 0) chips.add(_diffChip(l.def, diff.def));
    if (diff.spd != 0) chips.add(_diffChip(l.spd, diff.spd));
    if (diff.crit != 0) chips.add(_diffChip(l.critShort, diff.crit));
    if (diff.critDmg != 0) chips.add(_diffChip(l.critDmgShort, diff.critDmg));
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, children: chips);
  }

  Widget _diffChip(String label, double value) {
    final pos = value > 0;
    return Text(
      '$label ${pos ? '+' : ''}${value.toStringAsFixed(value.abs() < 1 ? 2 : 0)}',
      style: TextStyle(
        color: pos ? const Color(0xFF4CAF50) : const Color(0xFFFF4444),
        fontSize: 10,
      ),
    );
  }

  // --- Item base stat satirlari ---
  Widget _buildItemStatRows(AppLocalizations l10n, Stats stats) {
    final entries = <MapEntry<String, double>>[];
    if (stats.hp > 0) entries.add(MapEntry(l10n.hp, stats.hp));
    if (stats.atk > 0) entries.add(MapEntry(l10n.atk, stats.atk));
    if (stats.def > 0) entries.add(MapEntry(l10n.def, stats.def));
    if (stats.spd > 0) entries.add(MapEntry(l10n.spd, stats.spd));
    if (stats.crit > 0) entries.add(MapEntry(l10n.critShort, stats.crit));
    if (stats.critDmg > 0) entries.add(MapEntry(l10n.critDmgShort, stats.critDmg));
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 14,
      runSpacing: 2,
      children: entries.map((e) {
        return Text(
          '${e.key}: ${e.value.toStringAsFixed(e.value == e.value.roundToDouble() ? 0 : 1)}',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        );
      }).toList(),
    );
  }

  // --- Satis onay ---
  void _confirmSell(BuildContext context, Item item, AppLocalizations l10n, int price) {
    if (item.rarity.index >= Rarity.rare.index) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(l10n.sell, style: const TextStyle(color: AppColors.gold)),
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
              child: Text(l10n.confirm, style: const TextStyle(color: AppColors.gold)),
            ),
          ],
        ),
      );
    } else {
      ref.read(playerProvider.notifier).sellItem(item);
    }
  }

  // --- L10n Helpers ---
  String _heroClassL10n(AppLocalizations l10n, HeroClass cls) => switch (cls) {
    HeroClass.kalkanEr => l10n.heroKalkanEr,
    HeroClass.kurtBoru => l10n.heroKurtBoru,
    HeroClass.kam => l10n.heroKam,
    HeroClass.yayCi => l10n.heroYayCi,
    HeroClass.golgeBek => l10n.heroGolgeBek,
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

  String _slotIcon(EquipmentSlot slot) => _slotEmoji(slot);

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

// --- Envanter slot widget ---
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
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: rarityColor.withValues(alpha: isRarePlus ? 0.8 : 0.4),
            width: isRarePlus ? 2 : 1,
          ),
          boxShadow: isRarePlus
              ? [BoxShadow(color: rarityColor.withValues(alpha: 0.3), blurRadius: 4)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _slotEmoji(item.slot),
              style: const TextStyle(fontSize: 20),
            ),
            if (item.upgradeLevel > 0)
              Text(
                '+${item.upgradeLevel}',
                style: TextStyle(color: rarityColor, fontSize: 9, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
