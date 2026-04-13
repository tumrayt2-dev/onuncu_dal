// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ALP: The Great Tree';

  @override
  String get play => 'Play';

  @override
  String get settings => 'Settings';

  @override
  String get exit => 'Exit';

  @override
  String get newGame => 'New Game';

  @override
  String get continueGame => 'Continue';

  @override
  String get chooseHero => 'Choose Your Alp';

  @override
  String get heroName => 'Hero Name';

  @override
  String get heroNameHint => '3-12 characters';

  @override
  String get startAdventure => 'Start Adventure';

  @override
  String get heroKalkanEr => 'Shield-Bearer';

  @override
  String get heroKurtBoru => 'Wolf-Blood';

  @override
  String get heroKam => 'Shaman';

  @override
  String get heroYayCi => 'Archer';

  @override
  String get heroGolgeBek => 'Shadow-Guard';

  @override
  String get roleKalkanEr => 'Tank';

  @override
  String get roleKurtBoru => 'Melee DPS';

  @override
  String get roleKam => 'Caster';

  @override
  String get roleYayCi => 'Ranged';

  @override
  String get roleGolgeBek => 'Assassin';

  @override
  String get descKalkanEr => 'Builds walls of will. Master of block and taunt.';

  @override
  String get descKurtBoru =>
      'Transforms into wolf form with rage. Deadly up close.';

  @override
  String get descKam => 'Master of four elements. Fire, ice, lightning, wind.';

  @override
  String get descYayCi => 'Hold breath, aim, release. King of long range.';

  @override
  String get descGolgeBek =>
      'Hides in shadows, finishes with one strike. Pure damage.';

  @override
  String get resourceIrade => 'Will';

  @override
  String get resourceOfke => 'Rage';

  @override
  String get resourceRuh => 'Spirit';

  @override
  String get resourceSoluk => 'Breath';

  @override
  String get resourceSir => 'Secret';

  @override
  String get hp => 'HP';

  @override
  String get atk => 'ATK';

  @override
  String get def => 'DEF';

  @override
  String get spd => 'SPD';

  @override
  String welcomeHero(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get deleteWarningTitle => 'Are You Sure?';

  @override
  String get deleteWarningBody =>
      'Current save will be deleted. This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get language => 'Language';

  @override
  String get turkish => 'Turkish';

  @override
  String get english => 'English';

  @override
  String get sound => 'Sound';

  @override
  String get music => 'Music';

  @override
  String get notifications => 'Notifications';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameTooShort => 'At least 3 characters';

  @override
  String get nameTooLong => 'At most 12 characters';

  @override
  String get back => 'Back';

  @override
  String get defeated => 'Defeated!';

  @override
  String get retry => 'Retry';

  @override
  String get goBack => 'Go Back';

  @override
  String get stageComplete => 'Stage Complete!';

  @override
  String get totalXp => 'Total XP';

  @override
  String get totalGold => 'Total Gold';

  @override
  String get stars => 'Stars';

  @override
  String get continueText => 'Continue';

  @override
  String get levelUp => 'Level Up!';

  @override
  String get wave => 'Wave';

  @override
  String get stage => 'Stage';

  @override
  String get paused => 'PAUSED';

  @override
  String get autoMode => 'Idle';

  @override
  String get level => 'Lv';

  @override
  String get specialDemirKalkan => 'Iron Shield';

  @override
  String get specialKurtFormu => 'Wolf Form';

  @override
  String get specialRuhFirtinasi => 'Spirit Storm';

  @override
  String get specialKartalGoz => 'Eagle Eye';

  @override
  String get specialGolgeBicagi => 'Shadow Blade';

  @override
  String get itemSwordCommon => 'Sword';

  @override
  String get itemSwordUncommon => 'War Sword';

  @override
  String get itemSwordRare => 'Master Sword';

  @override
  String get itemHelmCommon => 'Helm';

  @override
  String get itemHelmUncommon => 'War Helm';

  @override
  String get itemHelmRare => 'Master Helm';

  @override
  String get itemChestCommon => 'Chestplate';

  @override
  String get itemChestUncommon => 'War Chestplate';

  @override
  String get itemChestRare => 'Master Chestplate';

  @override
  String get itemGlovesCommon => 'Gloves';

  @override
  String get itemGlovesUncommon => 'War Gloves';

  @override
  String get itemGlovesRare => 'Master Gloves';

  @override
  String get itemPantsCommon => 'Pants';

  @override
  String get itemPantsUncommon => 'War Pants';

  @override
  String get itemPantsRare => 'Master Pants';

  @override
  String get itemBootsCommon => 'Boots';

  @override
  String get itemBootsUncommon => 'War Boots';

  @override
  String get itemBootsRare => 'Master Boots';

  @override
  String get itemRingCommon => 'Ring';

  @override
  String get itemRingUncommon => 'War Ring';

  @override
  String get itemRingRare => 'Master Ring';

  @override
  String get itemRing2Common => 'Ring II';

  @override
  String get itemRing2Uncommon => 'War Ring II';

  @override
  String get itemRing2Rare => 'Master Ring II';

  @override
  String get itemAmuletCommon => 'Amulet';

  @override
  String get itemAmuletUncommon => 'War Amulet';

  @override
  String get itemAmuletRare => 'Master Amulet';

  @override
  String get combo => 'COMBO';

  @override
  String get defeatRewards => 'Rewards Earned';

  @override
  String get comboDmg => 'DMG';

  @override
  String get comboXp => 'XP';

  @override
  String get comboGold => 'GOLD';

  @override
  String get exitBattleTitle => 'Leave Battle';

  @override
  String get exitBattlePenalty =>
      'You will lose 50% of earned gold. Items will not be kept.';

  @override
  String exitBattleReward(String xp, String gold) {
    return 'You receive: $xp XP, $gold Gold';
  }

  @override
  String get leaveBattle => 'Leave Battle';

  @override
  String get inventory => 'Inventory';

  @override
  String get emptyInventory => 'Inventory is empty';

  @override
  String get itemDetail => 'Item Detail';

  @override
  String get equip => 'Equip';

  @override
  String get unequip => 'Unequip';

  @override
  String get sell => 'Sell';

  @override
  String sellConfirm(String gold) {
    return 'Sell for $gold gold?';
  }

  @override
  String get iLevel => 'iLv';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get slotWeapon => 'Weapon';

  @override
  String get slotHelmet => 'Helmet';

  @override
  String get slotChest => 'Chest';

  @override
  String get slotGloves => 'Gloves';

  @override
  String get slotPants => 'Pants';

  @override
  String get slotBoots => 'Boots';

  @override
  String get slotRing1 => 'Ring I';

  @override
  String get slotRing2 => 'Ring II';

  @override
  String get slotAmulet => 'Amulet';

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityUncommon => 'Uncommon';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Epic';

  @override
  String get rarityLegendary => 'Legendary';

  @override
  String get rarityMythic => 'Mythic';

  @override
  String get affixAtkPercent => 'Attack';

  @override
  String get affixHpFlat => 'Health';

  @override
  String get affixCritPercent => 'Crit Chance';

  @override
  String get affixCritDmgPercent => 'Crit Damage';

  @override
  String get affixLifestealPercent => 'Lifesteal';

  @override
  String get affixSpdFlat => 'Speed';

  @override
  String get affixGoldFindPercent => 'Gold Find';

  @override
  String get affixMagicFindPercent => 'Magic Find';

  @override
  String get affixDodgePercent => 'Dodge';

  @override
  String get affixResistPercent => 'Resist';

  @override
  String get affixHpRegenFlat => 'HP Regen';

  @override
  String get affixElementDmgPercent => 'Elemental Dmg';

  @override
  String get character => 'Hero';

  @override
  String get equipment => 'Equipment';

  @override
  String get emptySlot => 'Empty';

  @override
  String get statPoints => 'Stat Points';

  @override
  String statPointsAvailable(String count) {
    return '$count points available';
  }

  @override
  String get distribute => 'Apply';

  @override
  String get autoDistribute => 'Auto';

  @override
  String get resetPoints => 'Reset';

  @override
  String get totalStats => 'Total Stats';

  @override
  String get baseStats => 'Base';

  @override
  String get equipBonus => 'Gear';

  @override
  String get change => 'Change';

  @override
  String get noItemForSlot => 'No item for this slot';

  @override
  String get critShort => 'CRIT';

  @override
  String get critDmgShort => 'CRIT DMG';

  @override
  String get dodgeShort => 'DODGE';

  @override
  String get blockShort => 'BLOCK';

  @override
  String get lifestealShort => 'LIFESTEAL';

  @override
  String get resistShort => 'RESIST';

  @override
  String get magicFindShort => 'MAGIC FIND';

  @override
  String get hpRegenShort => 'HP REGEN';

  @override
  String get sortByRarity => 'Rarity';

  @override
  String get sortByLevel => 'Level';

  @override
  String get equipped => 'Equipped';

  @override
  String get comparing => 'Comparison';
}
