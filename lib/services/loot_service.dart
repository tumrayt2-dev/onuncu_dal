import 'dart:math';

import '../data/json_loader.dart';
import '../models/affix.dart';
import '../models/enemy.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/stats.dart';

/// Loot hesaplama sonucu
class LootResult {
  const LootResult({
    required this.gold,
    this.item,
  });

  final int gold;
  final Item? item;
}

/// Mob olumunde loot hesaplar: gold + item drop + pity sistemi
class LootService {
  LootService({this.magicFind = 0, this.testMode = false});

  static final _rng = Random();

  /// Oyuncunun magic find bonusu (%)
  double magicFind;

  /// Test modu: item drop orani %100
  final bool testMode;

  /// Pity sayaci: rare+ almadan gecen kill sayisi
  int _pityCounter = 0;
  static const _pityThreshold = 50;

  int get pityCounter => _pityCounter;

  /// Mob oldugunde loot hesapla
  LootResult calculateLoot({
    required Enemy enemy,
    required int stageId,
    double goldMultiplier = 1.0,
  }) {
    final loot = enemy.lootTable;

    // Gold: min-max arasi random
    final goldRange = loot.goldMax - loot.goldMin;
    final baseGold = loot.goldMin + (goldRange > 0 ? _rng.nextInt(goldRange + 1) : 0);
    final gold = (baseGold * goldMultiplier).round();

    // Item drop kontrolu
    Item? droppedItem;

    // Pity sistemi: esige ulastiysa garanti rare
    if (_pityCounter >= _pityThreshold) {
      droppedItem = _generateItem(
        stageId: stageId,
        forcedMinRarity: Rarity.rare,
      );
      _pityCounter = 0;
    } else {
      // Normal drop sansi (test modda %100)
      final dropChance = testMode ? 1.0 : loot.itemDropChance;
      // Magic find bonusu drop sansini arttirir
      final effectiveChance = dropChance * (1 + magicFind / 100);

      if (_rng.nextDouble() < effectiveChance) {
        droppedItem = _generateItem(stageId: stageId);
        // Rare+ dustuyse pity sifirla
        if (droppedItem.rarity.index >= Rarity.rare.index) {
          _pityCounter = 0;
        } else {
          _pityCounter++;
        }
      } else {
        _pityCounter++;
      }
    }

    // Special drop kontrolu
    if (droppedItem == null && loot.specialDrops.isNotEmpty) {
      for (final special in loot.specialDrops) {
        if (stageId >= special.minStage && _rng.nextDouble() < special.chance) {
          droppedItem = _generateItemFromBase(
            baseItemId: special.itemId,
            stageId: stageId,
          );
          if (droppedItem != null &&
              droppedItem.rarity.index >= Rarity.rare.index) {
            _pityCounter = 0;
          }
          break;
        }
      }
    }

    return LootResult(gold: gold, item: droppedItem);
  }

  /// Rastgele item olustur
  Item _generateItem({
    required int stageId,
    Rarity? forcedMinRarity,
  }) {
    final baseItems = JsonLoader.instance.itemsBase;
    if (baseItems.isEmpty) {
      return _fallbackItem(stageId);
    }

    // Rastgele base item sec
    final base = baseItems[_rng.nextInt(baseItems.length)];

    // Rarity belirle
    final rarity = _rollRarity(forcedMinRarity: forcedMinRarity);

    // Affix sayisi rarity'ye gore
    final affixCount = rarity.affixCount;
    final affixes = _generateAffixes(affixCount, stageId);

    // Base stat'lari iLevel ile olcekle
    final scaledStats = _scaleStats(base['baseStats'] as Map<String, dynamic>, stageId);

    return Item(
      id: '${base['id']}_${DateTime.now().millisecondsSinceEpoch}',
      nameKey: base['nameKey'] as String,
      slot: EquipmentSlot.values.byName(base['slot'] as String),
      rarity: rarity,
      iLevel: stageId,
      baseStats: scaledStats,
      affixes: affixes,
    );
  }

  /// Belirli base item'dan item olustur (special drop)
  Item? _generateItemFromBase({
    required String baseItemId,
    required int stageId,
  }) {
    final baseItems = JsonLoader.instance.itemsBase;
    final base = baseItems.cast<Map<String, dynamic>?>().firstWhere(
      (b) => b?['id'] == baseItemId,
      orElse: () => null,
    );
    if (base == null) return null;

    final rarity = _rollRarity();
    final affixes = _generateAffixes(rarity.affixCount, stageId);
    final scaledStats = _scaleStats(base['baseStats'] as Map<String, dynamic>, stageId);

    return Item(
      id: '${base['id']}_${DateTime.now().millisecondsSinceEpoch}',
      nameKey: base['nameKey'] as String,
      slot: EquipmentSlot.values.byName(base['slot'] as String),
      rarity: rarity,
      iLevel: stageId,
      baseStats: scaledStats,
      affixes: affixes,
    );
  }

  /// Rarity roll: agirlikli rastgele
  Rarity _rollRarity({Rarity? forcedMinRarity}) {
    // Agirliklar: common %50, uncommon %30, rare %14, epic %5, legendary %0.9, mythic %0.1
    final roll = _rng.nextDouble() * 100;
    Rarity result;
    if (roll < 0.1) {
      result = Rarity.mythic;
    } else if (roll < 1.0) {
      result = Rarity.legendary;
    } else if (roll < 6.0) {
      result = Rarity.epic;
    } else if (roll < 20.0) {
      result = Rarity.rare;
    } else if (roll < 50.0) {
      result = Rarity.uncommon;
    } else {
      result = Rarity.common;
    }

    // Minimum rarity zorlama (pity vb.)
    if (forcedMinRarity != null && result.index < forcedMinRarity.index) {
      result = forcedMinRarity;
    }

    return result;
  }

  /// Rastgele affix'ler olustur
  List<Affix> _generateAffixes(int count, int stageId) {
    final affixDefs = JsonLoader.instance.affixes;
    if (affixDefs.isEmpty) return [];

    final available = List<Map<String, dynamic>>.from(affixDefs);
    available.shuffle(_rng);

    final result = <Affix>[];
    final usedTypes = <String>{};

    for (final def in available) {
      if (result.length >= count) break;
      final type = def['type'] as String;
      if (usedTypes.contains(type)) continue;
      usedTypes.add(type);

      final minVal = (def['minValue'] as num).toDouble();
      final maxVal = (def['maxValue'] as num).toDouble();

      // iLevel ile deger olcekle (stage 1'de min, stage 50'de max)
      final t = ((stageId - 1) / 49).clamp(0.0, 1.0);
      final scaledMin = minVal + (maxVal - minVal) * t * 0.3;
      final scaledMax = minVal + (maxVal - minVal) * t * 1.0;
      final effectiveMin = scaledMin.clamp(minVal, maxVal);
      final effectiveMax = scaledMax.clamp(effectiveMin, maxVal);

      final value = effectiveMin + _rng.nextDouble() * (effectiveMax - effectiveMin);
      final isPercent = def['isPercent'] as bool;

      result.add(Affix(
        id: def['id'] as String,
        type: AffixType.values.byName(type),
        value: double.parse(value.toStringAsFixed(isPercent ? 1 : 0)),
        isPercent: isPercent,
      ));
    }

    return result;
  }

  /// Base stat'lari iLevel ile olcekle
  Stats _scaleStats(Map<String, dynamic> baseStatJson, int stageId) {
    // Stage 1'de base deger, her stage %3 artar
    final scale = pow(1.03, stageId - 1).toDouble();
    final scaled = <String, dynamic>{};
    for (final entry in baseStatJson.entries) {
      scaled[entry.key] = (entry.value as num).toDouble() * scale;
    }
    return Stats.fromJson(scaled);
  }

  /// JSON yuklenmediyse fallback item
  Item _fallbackItem(int stageId) {
    return Item(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      nameKey: 'itemSwordCommon',
      slot: EquipmentSlot.weapon,
      rarity: Rarity.common,
      iLevel: stageId,
      baseStats: Stats(atk: 8.0 * pow(1.03, stageId - 1).toDouble()),
    );
  }
}
