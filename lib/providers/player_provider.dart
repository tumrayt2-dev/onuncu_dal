import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import '../models/hero_character.dart';
import '../models/item.dart';
import '../models/stats.dart';
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

  /// Envantere item ekle
  Future<void> addItem(Item item) async {
    final hero = state;
    if (hero == null) return;
    final newInventory = List<Item>.from(hero.inventory)..add(item);
    state = hero.copyWith(inventory: newInventory);
    await _autoSave();
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

  /// Otomatik stat dağıtımı (sınıfa göre optimal)
  Future<void> autoDistributeStats() async {
    final hero = state;
    if (hero == null || hero.statPoints <= 0) return;

    final points = hero.statPoints;
    final allocation = <String, int>{};

    switch (hero.heroClass) {
      case HeroClass.kalkanEr: // Tank: HP %40, DEF %30, ATK %20, CRIT %10
        allocation['hp'] = (points * 0.4).round();
        allocation['def'] = (points * 0.3).round();
        allocation['atk'] = (points * 0.2).round();
        allocation['crit'] = points - allocation['hp']! - allocation['def']! - allocation['atk']!;
      case HeroClass.kurtBoru: // Melee DPS: ATK %40, CRIT %25, HP %20, DEF %15
        allocation['atk'] = (points * 0.4).round();
        allocation['crit'] = (points * 0.25).round();
        allocation['hp'] = (points * 0.2).round();
        allocation['def'] = points - allocation['atk']! - allocation['crit']! - allocation['hp']!;
      case HeroClass.kam: // Caster: ATK %45, HP %25, CRIT %20, DEF %10
        allocation['atk'] = (points * 0.45).round();
        allocation['hp'] = (points * 0.25).round();
        allocation['crit'] = (points * 0.2).round();
        allocation['def'] = points - allocation['atk']! - allocation['hp']! - allocation['crit']!;
      case HeroClass.yayCi: // Ranged: ATK %35, CRIT %30, SPD %20, HP %15
        allocation['atk'] = (points * 0.35).round();
        allocation['crit'] = (points * 0.3).round();
        allocation['spd'] = (points * 0.2).round();
        allocation['hp'] = points - allocation['atk']! - allocation['crit']! - allocation['spd']!;
      case HeroClass.golgeBek: // Assassin: CRIT %35, ATK %35, SPD %20, HP %10
        allocation['crit'] = (points * 0.35).round();
        allocation['atk'] = (points * 0.35).round();
        allocation['spd'] = (points * 0.2).round();
        allocation['hp'] = points - allocation['crit']! - allocation['atk']! - allocation['spd']!;
    }

    await distributeStatPoints(allocation);
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
