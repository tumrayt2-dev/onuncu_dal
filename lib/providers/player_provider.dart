import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/affix.dart';
import '../models/enums.dart';
import '../models/hero_character.dart';
import '../models/item.dart';
import '../models/stats.dart';
import '../data/json_loader.dart';
import '../services/save_service.dart';

/// Oyuncu state'ini yöneten Riverpod StateNotifier
class PlayerNotifier extends StateNotifier<HeroCharacter?> {
  PlayerNotifier() : super(null);

  final _save = SaveService.instance;

  /// Kayıtlı oyuncuyu yükle
  void loadFromSave() {
    state = _save.loadPlayer();
  }

  /// Yeni oyuncu oluştur
  Future<void> createNew(HeroClass heroClass, String name) async {
    state = await _save.createNewPlayer(heroClass, name);
  }

  /// Kayıtı sil
  Future<void> deleteSave() async {
    await _save.deletePlayer();
    state = null;
  }

  /// XP ekle, level-up kontrolü
  Future<void> addXp(int amount) async {
    final hero = state;
    if (hero == null) return;

    var newXp = hero.xp + amount;
    var newLevel = hero.level;
    var newStatPoints = hero.statPoints;
    var newSkillPoints = hero.skillPoints;

    // Level-up döngüsü
    while (true) {
      final xpNeeded = _xpToNextLevel(newLevel);
      if (newXp >= xpNeeded && newLevel < 500) {
        newXp -= xpNeeded;
        newLevel++;
        newStatPoints += 5;
        if (newLevel % 2 == 0) newSkillPoints++;
      } else {
        break;
      }
    }

    state = hero.copyWith(
      xp: newXp,
      level: newLevel,
      statPoints: newStatPoints,
      skillPoints: newSkillPoints,
    );
    await _autoSave();
  }

  /// Altın ekle
  Future<void> addGold(int amount) async {
    final hero = state;
    if (hero == null) return;
    state = hero.copyWith(gold: hero.gold + amount);
    await _autoSave();
  }

  /// Envantere item ekle (otomatik satış filtresi uygulanır)
  /// Döndürür: true = envantere eklendi, false = otomatik satıldı
  Future<bool> addItem(Item item) async {
    final hero = state;
    if (hero == null) return false;

    // Otomatik satış kontrolü
    if (hero.autoSellCommon && item.rarity == Rarity.common) {
      await addGold(sellPrice(item.rarity));
      return false;
    }
    if (hero.autoSellUncommon && item.rarity == Rarity.uncommon) {
      await addGold(sellPrice(item.rarity));
      return false;
    }

    final newInventory = List<Item>.from(hero.inventory)..add(item);
    state = hero.copyWith(inventory: newInventory);
    await _autoSave();
    return true;
  }

  /// Otomatik satış ayarını değiştir
  Future<void> setAutoSell(Rarity rarity, bool value) async {
    final hero = state;
    if (hero == null) return;
    if (rarity == Rarity.common) {
      state = hero.copyWith(autoSellCommon: value);
    } else if (rarity == Rarity.uncommon) {
      state = hero.copyWith(autoSellUncommon: value);
    }
    await _autoSave();
  }

  /// İksir satın al (1 iksir = 200 altın, max 3)
  static const int potionCost = 200;
  static const int potionHealPercent = 30; // HP'nin %30'unu iyileştirir

  Future<bool> buyPotion() async {
    final hero = state;
    if (hero == null) return false;
    if (hero.potions >= 3) return false;
    if (hero.gold < potionCost) return false;
    state = hero.copyWith(
      gold: hero.gold - potionCost,
      potions: hero.potions + 1,
    );
    await _autoSave();
    return true;
  }

  /// İksir kullan (savaşta)
  Future<bool> usePotion() async {
    final hero = state;
    if (hero == null) return false;
    if (hero.potions <= 0) return false;
    state = hero.copyWith(potions: hero.potions - 1);
    await _autoSave();
    return true;
  }

  /// Item sat (rarity'ye göre altın: Common:10, Uncommon:50, Rare:200, Epic:1000, Legendary:5000, Mythic:20000)
  Future<void> sellItem(Item item) async {
    final hero = state;
    if (hero == null) return;
    final goldValue = switch (item.rarity) {
      Rarity.common => 10,
      Rarity.uncommon => 50,
      Rarity.rare => 200,
      Rarity.epic => 1000,
      Rarity.legendary => 5000,
      Rarity.mythic => 20000,
    };
    final newInventory = List<Item>.from(hero.inventory)..remove(item);
    state = hero.copyWith(
      inventory: newInventory,
      gold: hero.gold + goldValue,
    );
    await _autoSave();
  }

  /// Satış fiyatı hesapla
  static int sellPrice(Rarity rarity) => switch (rarity) {
        Rarity.common => 10,
        Rarity.uncommon => 50,
        Rarity.rare => 200,
        Rarity.epic => 1000,
        Rarity.legendary => 5000,
        Rarity.mythic => 20000,
      };

  /// Item kuşan
  Future<void> equipItem(Item item, EquipmentSlot slot) async {
    final hero = state;
    if (hero == null) return;

    final newEquipment = Map<EquipmentSlot, Item>.from(hero.equipment);
    final newInventory = List<Item>.from(hero.inventory);

    // Mevcut ekipmani çıkar
    final existing = newEquipment[slot];
    if (existing != null) {
      newInventory.add(existing);
    }

    // Envanterden kaldır, slota yerleştir
    newInventory.remove(item);
    newEquipment[slot] = item;

    state = hero.copyWith(
      equipment: newEquipment,
      inventory: newInventory,
    );
    await _autoSave();
  }

  /// Item çıkar
  Future<void> unequipItem(EquipmentSlot slot) async {
    final hero = state;
    if (hero == null) return;

    final existing = hero.equipment[slot];
    if (existing == null) return;

    final newEquipment = Map<EquipmentSlot, Item>.from(hero.equipment);
    final newInventory = List<Item>.from(hero.inventory);

    newEquipment.remove(slot);
    newInventory.add(existing);

    state = hero.copyWith(
      equipment: newEquipment,
      inventory: newInventory,
    );
    await _autoSave();
  }

  /// Stat puanı dağıt (belirli bir stat'a belirli miktarda)
  Future<void> distributeStatPoints(Map<String, int> allocation) async {
    final hero = state;
    if (hero == null) return;

    int totalUsed = 0;
    for (final v in allocation.values) {
      totalUsed += v;
    }
    if (totalUsed <= 0 || totalUsed > hero.statPoints) return;

    final d = hero.distributedStats;
    state = hero.copyWith(
      statPoints: hero.statPoints - totalUsed,
      distributedStats: d.copyWith(
        hp: d.hp + (allocation['hp'] ?? 0) * 10, // Her puan +10 HP
        atk: d.atk + (allocation['atk'] ?? 0) * 2, // Her puan +2 ATK
        def: d.def + (allocation['def'] ?? 0) * 2, // Her puan +2 DEF
        spd: d.spd + (allocation['spd'] ?? 0) * 0.01, // Her puan +0.01 SPD
        crit: d.crit + (allocation['crit'] ?? 0) * 0.5, // Her puan +0.5% CRIT
      ),
    );
    await _autoSave();
  }

  /// Stat puanlarını sıfırla (tümünü geri al)
  Future<void> resetStatPoints() async {
    final hero = state;
    if (hero == null) return;

    // Dağıtılmış puanları geri hesapla
    final d = hero.distributedStats;
    final hpPoints = (d.hp / 10).round();
    final atkPoints = (d.atk / 2).round();
    final defPoints = (d.def / 2).round();
    final spdPoints = (d.spd / 0.01).round();
    final critPoints = (d.crit / 0.5).round();
    final totalRecovered = hpPoints + atkPoints + defPoints + spdPoints + critPoints;

    state = hero.copyWith(
      statPoints: hero.statPoints + totalRecovered,
      distributedStats: const Stats(),
    );
    await _autoSave();
  }

  /// Sınıfa göre optimal dağılım hesapla (UI önizleme için static)
  static Map<String, int> calculateAutoAllocation(HeroClass heroClass, int points) {
    if (points <= 0) return {};
    final allocation = <String, int>{};
    switch (heroClass) {
      case HeroClass.kalkanEr:
        allocation['hp'] = (points * 0.4).round();
        allocation['def'] = (points * 0.3).round();
        allocation['atk'] = (points * 0.2).round();
        allocation['crit'] = points - allocation['hp']! - allocation['def']! - allocation['atk']!;
      case HeroClass.kurtBoru:
        allocation['atk'] = (points * 0.4).round();
        allocation['crit'] = (points * 0.25).round();
        allocation['hp'] = (points * 0.2).round();
        allocation['def'] = points - allocation['atk']! - allocation['crit']! - allocation['hp']!;
      case HeroClass.kam:
        allocation['atk'] = (points * 0.45).round();
        allocation['hp'] = (points * 0.25).round();
        allocation['crit'] = (points * 0.2).round();
        allocation['def'] = points - allocation['atk']! - allocation['hp']! - allocation['crit']!;
      case HeroClass.yayCi:
        allocation['atk'] = (points * 0.35).round();
        allocation['crit'] = (points * 0.3).round();
        allocation['spd'] = (points * 0.2).round();
        allocation['hp'] = points - allocation['atk']! - allocation['crit']! - allocation['spd']!;
      case HeroClass.golgeBek:
        allocation['crit'] = (points * 0.35).round();
        allocation['atk'] = (points * 0.35).round();
        allocation['spd'] = (points * 0.2).round();
        allocation['hp'] = points - allocation['crit']! - allocation['atk']! - allocation['spd']!;
    }
    return allocation;
  }

  /// Otomatik stat dağıtımı (sınıfa göre optimal)
  Future<void> autoDistributeStats() async {
    final hero = state;
    if (hero == null || hero.statPoints <= 0) return;
    final allocation = calculateAutoAllocation(hero.heroClass, hero.statPoints);
    await distributeStatPoints(allocation);
  }

  // --- Upgrade Sistemi (Kübey) ---

  static final _rng = math.Random();

  /// Upgrade maliyeti (altın): baseGold * (upgradeLevel + 1)
  static int upgradeCost(Item item) {
    final baseGold = switch (item.rarity) {
      Rarity.common => 20,
      Rarity.uncommon => 50,
      Rarity.rare => 150,
      Rarity.epic => 500,
      Rarity.legendary => 2000,
      Rarity.mythic => 8000,
    };
    return baseGold * (item.upgradeLevel + 1);
  }

  /// Upgrade başarı oranı (1.0 = %100)
  static double upgradeSuccessRate(int currentLevel) {
    if (currentLevel < 15) return 1.0;
    return switch (currentLevel) {
      15 => 0.80,
      16 => 0.70,
      17 => 0.60,
      _ => 0.50, // 18, 19, 20
    };
  }

  /// Item upgrade: altın + fodder item (aynı rarity) gerekli
  /// Döndürür: true = başarı, false = başarısızlık
  Future<bool> upgradeItem(Item item, Item fodder) async {
    final hero = state;
    if (hero == null) return false;
    if (item.upgradeLevel >= 20) return false;
    if (fodder.rarity != item.rarity) return false;

    final cost = upgradeCost(item);
    if (hero.gold < cost) return false;

    // Fodder'ı envanterden kaldır + altın düş
    final newInventory = List<Item>.from(hero.inventory);
    newInventory.remove(fodder);
    final newGold = hero.gold - cost;

    // Başarı kontrolü
    final rate = upgradeSuccessRate(item.upgradeLevel);
    final success = _rng.nextDouble() < rate;

    if (success) {
      // Item'ı upgrade et
      final upgraded = item.copyWith(upgradeLevel: item.upgradeLevel + 1);

      // Item equipment'ta mı envanterde mi?
      final newEquipment = Map<EquipmentSlot, Item>.from(hero.equipment);
      bool found = false;
      for (final entry in newEquipment.entries) {
        if (entry.value.id == item.id) {
          newEquipment[entry.key] = upgraded;
          found = true;
          break;
        }
      }
      if (!found) {
        final idx = newInventory.indexWhere((i) => i.id == item.id);
        if (idx >= 0) newInventory[idx] = upgraded;
      }

      state = hero.copyWith(
        gold: newGold,
        inventory: newInventory,
        equipment: newEquipment,
      );
    } else {
      // Başarısızlık — malzeme + altın gider, item kalır
      state = hero.copyWith(
        gold: newGold,
        inventory: newInventory,
      );
    }

    await _autoSave();
    return success;
  }

  /// Enchant maliyeti (Ruh Cevheri yerine şimdilik altın)
  static int enchantCost(Item item) {
    return switch (item.rarity) {
      Rarity.common => 50,
      Rarity.uncommon => 150,
      Rarity.rare => 500,
      Rarity.epic => 1500,
      Rarity.legendary => 5000,
      Rarity.mythic => 15000,
    };
  }

  /// Enchant: item'a 1 random affix ekle (max = rarity affix count)
  /// Döndürür: eklenen Affix veya null (limit doluysa)
  Future<Affix?> enchantItem(Item item) async {
    final hero = state;
    if (hero == null) return null;

    final maxAffixes = item.rarity.affixCount;
    if (item.affixes.length >= maxAffixes) return null;

    final cost = enchantCost(item);
    if (hero.gold < cost) return null;

    // Random affix üret
    final affixDefs = JsonLoader.instance.affixes;
    if (affixDefs.isEmpty) return null;

    final affixDef = affixDefs[_rng.nextInt(affixDefs.length)];
    final affixType = AffixType.values.byName(affixDef['type'] as String);
    final minVal = (affixDef['minValue'] as num).toDouble();
    final maxVal = (affixDef['maxValue'] as num).toDouble();
    final value = minVal + _rng.nextDouble() * (maxVal - minVal);
    final isPercent = affixDef['isPercent'] as bool? ?? false;

    final newAffix = Affix(
      id: 'affix_${DateTime.now().millisecondsSinceEpoch}',
      type: affixType,
      value: double.parse(value.toStringAsFixed(1)),
      isPercent: isPercent,
    );

    final newAffixes = List<Affix>.from(item.affixes)..add(newAffix);
    final enchanted = item.copyWith(affixes: newAffixes);

    // Item'ı güncelle (equipment veya envanter)
    final newInventory = List<Item>.from(hero.inventory);
    final newEquipment = Map<EquipmentSlot, Item>.from(hero.equipment);
    bool found = false;
    for (final entry in newEquipment.entries) {
      if (entry.value.id == item.id) {
        newEquipment[entry.key] = enchanted;
        found = true;
        break;
      }
    }
    if (!found) {
      final idx = newInventory.indexWhere((i) => i.id == item.id);
      if (idx >= 0) newInventory[idx] = enchanted;
    }

    state = hero.copyWith(
      gold: hero.gold - cost,
      inventory: newInventory,
      equipment: newEquipment,
    );
    await _autoSave();
    return newAffix;
  }

  /// Reroll: mevcut bir affix'i random yenisiyle değiştir
  Future<Affix?> rerollAffix(Item item, int affixIndex) async {
    final hero = state;
    if (hero == null) return null;
    if (affixIndex < 0 || affixIndex >= item.affixes.length) return null;

    final cost = enchantCost(item);
    if (hero.gold < cost) return null;

    final affixDefs = JsonLoader.instance.affixes;
    if (affixDefs.isEmpty) return null;

    final affixDef = affixDefs[_rng.nextInt(affixDefs.length)];
    final affixType = AffixType.values.byName(affixDef['type'] as String);
    final minVal = (affixDef['minValue'] as num).toDouble();
    final maxVal = (affixDef['maxValue'] as num).toDouble();
    final value = minVal + _rng.nextDouble() * (maxVal - minVal);
    final isPercent = affixDef['isPercent'] as bool? ?? false;

    final newAffix = Affix(
      id: 'affix_${DateTime.now().millisecondsSinceEpoch}',
      type: affixType,
      value: double.parse(value.toStringAsFixed(1)),
      isPercent: isPercent,
    );

    final newAffixes = List<Affix>.from(item.affixes);
    newAffixes[affixIndex] = newAffix;
    final rerolled = item.copyWith(affixes: newAffixes);

    final newInventory = List<Item>.from(hero.inventory);
    final newEquipment = Map<EquipmentSlot, Item>.from(hero.equipment);
    bool found = false;
    for (final entry in newEquipment.entries) {
      if (entry.value.id == item.id) {
        newEquipment[entry.key] = rerolled;
        found = true;
        break;
      }
    }
    if (!found) {
      final idx = newInventory.indexWhere((i) => i.id == item.id);
      if (idx >= 0) newInventory[idx] = rerolled;
    }

    state = hero.copyWith(
      gold: hero.gold - cost,
      inventory: newInventory,
      equipment: newEquipment,
    );
    await _autoSave();
    return newAffix;
  }

  /// Stage ilerlemesi güncelle
  Future<void> updateStage(int stage, int worldId) async {
    final hero = state;
    if (hero == null) return;
    state = hero.copyWith(
      currentStage: stage,
      currentWorldId: worldId,
      maxStage: stage > hero.maxStage ? stage : hero.maxStage,
    );
    await _autoSave();
  }

  /// Auto-save
  Future<void> _autoSave() async {
    final hero = state;
    if (hero != null) {
      await _save.savePlayer(hero);
    }
  }

  int _xpToNextLevel(int level) {
    return (100 * math.pow(level, 1.6)).floor();
  }
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, HeroCharacter?>((ref) {
  return PlayerNotifier();
});
