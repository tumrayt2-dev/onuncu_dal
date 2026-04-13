import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import '../models/hero_character.dart';
import '../models/item.dart';
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
