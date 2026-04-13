import '../models/affix.dart';
import '../models/enums.dart';
import '../models/hero_character.dart';
import '../models/item.dart';
import '../models/stats.dart';
import '../data/json_loader.dart';

/// Toplam stat hesaplama: base + level bonus + ekipman + affix'ler
class StatCalculator {
  const StatCalculator._();

  /// Tam stat hesapla: base + level + equipment + affixes
  static Stats totalStats(HeroCharacter hero) {
    final heroId = switch (hero.heroClass) {
      HeroClass.kalkanEr => 'kalkan_er',
      HeroClass.kurtBoru => 'kurt_boru',
      HeroClass.kam => 'kam',
      HeroClass.yayCi => 'yay_ci',
      HeroClass.golgeBek => 'golge_bek',
    };
    final perLevel = JsonLoader.instance.getHeroPerLevel(heroId);

    // Base + level bonus
    Stats total = hero.effectiveStats(perLevel);

    // Equipment base stats + upgrade bonus
    for (final item in hero.equipment.values) {
      total = total + _itemTotalStats(item);
    }

    // Equipment affix'leri (yüzde olanlar base'e eklenir)
    final affixFlat = _collectAffixFlats(hero.equipment.values);
    total = total + affixFlat;

    final affixPercent = _collectAffixPercents(hero.equipment.values);
    total = _applyPercents(total, affixPercent);

    return total;
  }

  /// Item'ın upgrade dahil toplam base stat'ları
  static Stats _itemTotalStats(Item item) {
    if (item.upgradeLevel <= 0) return item.baseStats;
    // Her + seviye base stat'ı %5 artırır
    final mult = 1.0 + (item.upgradeLevel * 0.05);
    return Stats(
      hp: item.baseStats.hp * mult,
      mp: item.baseStats.mp * mult,
      atk: item.baseStats.atk * mult,
      def: item.baseStats.def * mult,
      spd: item.baseStats.spd * mult,
      crit: item.baseStats.crit * mult,
      critDmg: item.baseStats.critDmg * mult,
      dodge: item.baseStats.dodge * mult,
      block: item.baseStats.block * mult,
      lifesteal: item.baseStats.lifesteal * mult,
      hpRegen: item.baseStats.hpRegen * mult,
      accuracy: item.baseStats.accuracy * mult,
      resist: item.baseStats.resist * mult,
      magicFind: item.baseStats.magicFind * mult,
    );
  }

  /// Flat affix'leri topla (isPercent=false)
  static Stats _collectAffixFlats(Iterable<Item> items) {
    double hp = 0, spd = 0, hpRegen = 0;
    for (final item in items) {
      for (final a in item.affixes) {
        if (a.isPercent) continue;
        switch (a.type) {
          case AffixType.hpFlat:
            hp += a.value;
          case AffixType.spdFlat:
            spd += a.value;
          case AffixType.hpRegenFlat:
            hpRegen += a.value;
          default:
            break;
        }
      }
    }
    return Stats(hp: hp, spd: spd, hpRegen: hpRegen);
  }

  /// Yüzde affix'leri topla (isPercent=true)
  static Map<AffixType, double> _collectAffixPercents(Iterable<Item> items) {
    final result = <AffixType, double>{};
    for (final item in items) {
      for (final a in item.affixes) {
        if (!a.isPercent) continue;
        result[a.type] = (result[a.type] ?? 0) + a.value;
      }
    }
    return result;
  }

  /// Yüzde bonuslarını stat'lara uygula
  static Stats _applyPercents(Stats base, Map<AffixType, double> percents) {
    double atk = base.atk;
    double crit = base.crit;
    double critDmg = base.critDmg;
    double lifesteal = base.lifesteal;
    double dodge = base.dodge;
    double resist = base.resist;
    double magicFind = base.magicFind;

    for (final entry in percents.entries) {
      final pct = entry.value / 100;
      switch (entry.key) {
        case AffixType.atkPercent:
          atk += base.atk * pct;
        case AffixType.critPercent:
          crit += entry.value; // Crit zaten % olarak tutuluyor
        case AffixType.critDmgPercent:
          critDmg += entry.value;
        case AffixType.lifestealPercent:
          lifesteal += entry.value;
        case AffixType.dodgePercent:
          dodge += entry.value;
        case AffixType.resistPercent:
          resist += entry.value;
        case AffixType.goldFindPercent:
          break; // Gold find savaş sırasında uygulanır
        case AffixType.magicFindPercent:
          magicFind += entry.value;
        case AffixType.elementDmgPercent:
          break; // Element damage savaş sırasında uygulanır
        default:
          break;
      }
    }

    return base.copyWith(
      atk: atk,
      crit: crit,
      critDmg: critDmg,
      lifesteal: lifesteal,
      dodge: dodge,
      resist: resist,
      magicFind: magicFind,
    );
  }

  /// İki item'ı karşılaştır — stat farkını döndürür (yeni - eski)
  /// Pozitif = yeni daha iyi, negatif = eski daha iyi
  static Stats compareItems(HeroCharacter hero, Item newItem, Item? oldItem) {
    // Geçici hero ile hesapla
    final equipMap = Map<EquipmentSlot, Item>.from(hero.equipment);

    // Eski ile toplam
    final oldTotal = totalStats(hero);

    // Yeni ile toplam
    equipMap[newItem.slot] = newItem;
    final tempHero = hero.copyWith(equipment: equipMap);
    final newTotal = totalStats(tempHero);

    return Stats(
      hp: newTotal.hp - oldTotal.hp,
      mp: newTotal.mp - oldTotal.mp,
      atk: newTotal.atk - oldTotal.atk,
      def: newTotal.def - oldTotal.def,
      spd: newTotal.spd - oldTotal.spd,
      crit: newTotal.crit - oldTotal.crit,
      critDmg: newTotal.critDmg - oldTotal.critDmg,
      dodge: newTotal.dodge - oldTotal.dodge,
      block: newTotal.block - oldTotal.block,
      lifesteal: newTotal.lifesteal - oldTotal.lifesteal,
      hpRegen: newTotal.hpRegen - oldTotal.hpRegen,
      accuracy: newTotal.accuracy - oldTotal.accuracy,
      resist: newTotal.resist - oldTotal.resist,
      magicFind: newTotal.magicFind - oldTotal.magicFind,
    );
  }
}
