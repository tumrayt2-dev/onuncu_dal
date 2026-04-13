import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'ALP: Uluğ Kayın'**
  String get appTitle;

  /// No description provided for @play.
  ///
  /// In tr, this message translates to:
  /// **'Oyna'**
  String get play;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @exit.
  ///
  /// In tr, this message translates to:
  /// **'Cikis'**
  String get exit;

  /// No description provided for @newGame.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Oyun'**
  String get newGame;

  /// No description provided for @continueGame.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueGame;

  /// No description provided for @chooseHero.
  ///
  /// In tr, this message translates to:
  /// **'Alpini Sec'**
  String get chooseHero;

  /// No description provided for @heroName.
  ///
  /// In tr, this message translates to:
  /// **'Alpinin Adi'**
  String get heroName;

  /// No description provided for @heroNameHint.
  ///
  /// In tr, this message translates to:
  /// **'3-12 karakter'**
  String get heroNameHint;

  /// No description provided for @startAdventure.
  ///
  /// In tr, this message translates to:
  /// **'Maceraya Basla'**
  String get startAdventure;

  /// No description provided for @heroKalkanEr.
  ///
  /// In tr, this message translates to:
  /// **'Kalkan-Er'**
  String get heroKalkanEr;

  /// No description provided for @heroKurtBoru.
  ///
  /// In tr, this message translates to:
  /// **'Kurt-Boru'**
  String get heroKurtBoru;

  /// No description provided for @heroKam.
  ///
  /// In tr, this message translates to:
  /// **'Kam'**
  String get heroKam;

  /// No description provided for @heroYayCi.
  ///
  /// In tr, this message translates to:
  /// **'Yay-Ci'**
  String get heroYayCi;

  /// No description provided for @heroGolgeBek.
  ///
  /// In tr, this message translates to:
  /// **'Golge-Bek'**
  String get heroGolgeBek;

  /// No description provided for @roleKalkanEr.
  ///
  /// In tr, this message translates to:
  /// **'Tank'**
  String get roleKalkanEr;

  /// No description provided for @roleKurtBoru.
  ///
  /// In tr, this message translates to:
  /// **'Yakin Dovus'**
  String get roleKurtBoru;

  /// No description provided for @roleKam.
  ///
  /// In tr, this message translates to:
  /// **'Buyucu'**
  String get roleKam;

  /// No description provided for @roleYayCi.
  ///
  /// In tr, this message translates to:
  /// **'Nisanci'**
  String get roleYayCi;

  /// No description provided for @roleGolgeBek.
  ///
  /// In tr, this message translates to:
  /// **'Suikastci'**
  String get roleGolgeBek;

  /// No description provided for @descKalkanEr.
  ///
  /// In tr, this message translates to:
  /// **'Irade gucuyle savunma duvari orer. Blok ve taunt ustasi.'**
  String get descKalkanEr;

  /// No description provided for @descKurtBoru.
  ///
  /// In tr, this message translates to:
  /// **'Ofkesiyle kurt formuna girer. Yakinda olumcul, hizli.'**
  String get descKurtBoru;

  /// No description provided for @descKam.
  ///
  /// In tr, this message translates to:
  /// **'Dort elementin efendisi. Ates, buz, yildirim, ruzgar.'**
  String get descKam;

  /// No description provided for @descYayCi.
  ///
  /// In tr, this message translates to:
  /// **'Nefes tut, nisanla, birak. Uzak mesafenin krali.'**
  String get descYayCi;

  /// No description provided for @descGolgeBek.
  ///
  /// In tr, this message translates to:
  /// **'Golgelerde saklanir, bir vurusla bitirir. Saf hasar.'**
  String get descGolgeBek;

  /// No description provided for @resourceIrade.
  ///
  /// In tr, this message translates to:
  /// **'Irade'**
  String get resourceIrade;

  /// No description provided for @resourceOfke.
  ///
  /// In tr, this message translates to:
  /// **'Ofke'**
  String get resourceOfke;

  /// No description provided for @resourceRuh.
  ///
  /// In tr, this message translates to:
  /// **'Ruh'**
  String get resourceRuh;

  /// No description provided for @resourceSoluk.
  ///
  /// In tr, this message translates to:
  /// **'Soluk'**
  String get resourceSoluk;

  /// No description provided for @resourceSir.
  ///
  /// In tr, this message translates to:
  /// **'Sir'**
  String get resourceSir;

  /// No description provided for @hp.
  ///
  /// In tr, this message translates to:
  /// **'CAN'**
  String get hp;

  /// No description provided for @atk.
  ///
  /// In tr, this message translates to:
  /// **'SALDIRI'**
  String get atk;

  /// No description provided for @def.
  ///
  /// In tr, this message translates to:
  /// **'SAVUNMA'**
  String get def;

  /// No description provided for @spd.
  ///
  /// In tr, this message translates to:
  /// **'HIZ'**
  String get spd;

  /// No description provided for @welcomeHero.
  ///
  /// In tr, this message translates to:
  /// **'Hos geldin, {name}!'**
  String welcomeHero(String name);

  /// No description provided for @deleteWarningTitle.
  ///
  /// In tr, this message translates to:
  /// **'Emin Misin?'**
  String get deleteWarningTitle;

  /// No description provided for @deleteWarningBody.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut kayit silinecek. Bu islem geri alinamaz.'**
  String get deleteWarningBody;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgec'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Turkce'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'Ingilizce'**
  String get english;

  /// No description provided for @sound.
  ///
  /// In tr, this message translates to:
  /// **'Ses'**
  String get sound;

  /// No description provided for @music.
  ///
  /// In tr, this message translates to:
  /// **'Muzik'**
  String get music;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @nameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Isim gerekli'**
  String get nameRequired;

  /// No description provided for @nameTooShort.
  ///
  /// In tr, this message translates to:
  /// **'En az 3 karakter'**
  String get nameTooShort;

  /// No description provided for @nameTooLong.
  ///
  /// In tr, this message translates to:
  /// **'En fazla 12 karakter'**
  String get nameTooLong;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @defeated.
  ///
  /// In tr, this message translates to:
  /// **'Yenildin!'**
  String get defeated;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @goBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri Don'**
  String get goBack;

  /// No description provided for @stageComplete.
  ///
  /// In tr, this message translates to:
  /// **'Stage Tamamlandi!'**
  String get stageComplete;

  /// No description provided for @totalXp.
  ///
  /// In tr, this message translates to:
  /// **'Toplam XP'**
  String get totalXp;

  /// No description provided for @totalGold.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Altin'**
  String get totalGold;

  /// No description provided for @stars.
  ///
  /// In tr, this message translates to:
  /// **'Yildiz'**
  String get stars;

  /// No description provided for @continueText.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get continueText;

  /// No description provided for @levelUp.
  ///
  /// In tr, this message translates to:
  /// **'Seviye Atladi!'**
  String get levelUp;

  /// No description provided for @wave.
  ///
  /// In tr, this message translates to:
  /// **'Dalga'**
  String get wave;

  /// No description provided for @stage.
  ///
  /// In tr, this message translates to:
  /// **'Bolum'**
  String get stage;

  /// No description provided for @paused.
  ///
  /// In tr, this message translates to:
  /// **'DURAKLADI'**
  String get paused;

  /// No description provided for @autoMode.
  ///
  /// In tr, this message translates to:
  /// **'OTO'**
  String get autoMode;

  /// No description provided for @level.
  ///
  /// In tr, this message translates to:
  /// **'Sv'**
  String get level;

  /// No description provided for @specialDemirKalkan.
  ///
  /// In tr, this message translates to:
  /// **'Demir Kalkan'**
  String get specialDemirKalkan;

  /// No description provided for @specialKurtFormu.
  ///
  /// In tr, this message translates to:
  /// **'Kurt Formu'**
  String get specialKurtFormu;

  /// No description provided for @specialRuhFirtinasi.
  ///
  /// In tr, this message translates to:
  /// **'Ruh Firtinasi'**
  String get specialRuhFirtinasi;

  /// No description provided for @specialKartalGoz.
  ///
  /// In tr, this message translates to:
  /// **'Kartal Goz'**
  String get specialKartalGoz;

  /// No description provided for @specialGolgeBicagi.
  ///
  /// In tr, this message translates to:
  /// **'Golge Bicagi'**
  String get specialGolgeBicagi;

  /// No description provided for @itemSwordCommon.
  ///
  /// In tr, this message translates to:
  /// **'Kilic'**
  String get itemSwordCommon;

  /// No description provided for @itemSwordUncommon.
  ///
  /// In tr, this message translates to:
  /// **'Savas Kilici'**
  String get itemSwordUncommon;

  /// No description provided for @itemSwordRare.
  ///
  /// In tr, this message translates to:
  /// **'Usta Kilici'**
  String get itemSwordRare;

  /// No description provided for @itemHelmCommon.
  ///
  /// In tr, this message translates to:
  /// **'Miğfer'**
  String get itemHelmCommon;

  /// No description provided for @itemHelmUncommon.
  ///
  /// In tr, this message translates to:
  /// **'Savas Migferi'**
  String get itemHelmUncommon;

  /// No description provided for @itemHelmRare.
  ///
  /// In tr, this message translates to:
  /// **'Usta Migferi'**
  String get itemHelmRare;

  /// No description provided for @itemChestCommon.
  ///
  /// In tr, this message translates to:
  /// **'Gogus Zirhı'**
  String get itemChestCommon;

  /// No description provided for @itemChestUncommon.
  ///
  /// In tr, this message translates to:
  /// **'Savas Zirhi'**
  String get itemChestUncommon;

  /// No description provided for @itemChestRare.
  ///
  /// In tr, this message translates to:
  /// **'Usta Zirhi'**
  String get itemChestRare;

  /// No description provided for @itemGlovesCommon.
  ///
  /// In tr, this message translates to:
  /// **'Eldiven'**
  String get itemGlovesCommon;

  /// No description provided for @itemGlovesUncommon.
  ///
  /// In tr, this message translates to:
  /// **'Savas Eldiveni'**
  String get itemGlovesUncommon;

  /// No description provided for @itemGlovesRare.
  ///
  /// In tr, this message translates to:
  /// **'Usta Eldiveni'**
  String get itemGlovesRare;

  /// No description provided for @itemPantsCommon.
  ///
  /// In tr, this message translates to:
  /// **'Pantolon'**
  String get itemPantsCommon;

  /// No description provided for @itemPantsUncommon.
  ///
  /// In tr, this message translates to:
  /// **'Savas Pantolonu'**
  String get itemPantsUncommon;

  /// No description provided for @itemPantsRare.
  ///
  /// In tr, this message translates to:
  /// **'Usta Pantolonu'**
  String get itemPantsRare;

  /// No description provided for @itemBootsCommon.
  ///
  /// In tr, this message translates to:
  /// **'Cizme'**
  String get itemBootsCommon;

  /// No description provided for @itemBootsUncommon.
  ///
  /// In tr, this message translates to:
  /// **'Savas Cizmesi'**
  String get itemBootsUncommon;

  /// No description provided for @itemBootsRare.
  ///
  /// In tr, this message translates to:
  /// **'Usta Cizmesi'**
  String get itemBootsRare;

  /// No description provided for @itemRingCommon.
  ///
  /// In tr, this message translates to:
  /// **'Yuzuk'**
  String get itemRingCommon;

  /// No description provided for @itemRingUncommon.
  ///
  /// In tr, this message translates to:
  /// **'Savas Yuzugu'**
  String get itemRingUncommon;

  /// No description provided for @itemRingRare.
  ///
  /// In tr, this message translates to:
  /// **'Usta Yuzugu'**
  String get itemRingRare;

  /// No description provided for @itemRing2Common.
  ///
  /// In tr, this message translates to:
  /// **'Ikinci Yuzuk'**
  String get itemRing2Common;

  /// No description provided for @itemRing2Uncommon.
  ///
  /// In tr, this message translates to:
  /// **'Savas Yuzugu II'**
  String get itemRing2Uncommon;

  /// No description provided for @itemRing2Rare.
  ///
  /// In tr, this message translates to:
  /// **'Usta Yuzugu II'**
  String get itemRing2Rare;

  /// No description provided for @itemAmuletCommon.
  ///
  /// In tr, this message translates to:
  /// **'Muska'**
  String get itemAmuletCommon;

  /// No description provided for @itemAmuletUncommon.
  ///
  /// In tr, this message translates to:
  /// **'Savas Muskasi'**
  String get itemAmuletUncommon;

  /// No description provided for @itemAmuletRare.
  ///
  /// In tr, this message translates to:
  /// **'Usta Muskasi'**
  String get itemAmuletRare;

  /// No description provided for @combo.
  ///
  /// In tr, this message translates to:
  /// **'KOMBO'**
  String get combo;

  /// No description provided for @defeatRewards.
  ///
  /// In tr, this message translates to:
  /// **'Kazanilan Oduller'**
  String get defeatRewards;

  /// No description provided for @comboDmg.
  ///
  /// In tr, this message translates to:
  /// **'HASAR'**
  String get comboDmg;

  /// No description provided for @comboXp.
  ///
  /// In tr, this message translates to:
  /// **'XP'**
  String get comboXp;

  /// No description provided for @comboGold.
  ///
  /// In tr, this message translates to:
  /// **'ALTIN'**
  String get comboGold;

  /// No description provided for @exitBattleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Savastan Cik'**
  String get exitBattleTitle;

  /// No description provided for @exitBattlePenalty.
  ///
  /// In tr, this message translates to:
  /// **'Kazandigin altinin %50\'si kesilecek. Itemler verilmeyecek.'**
  String get exitBattlePenalty;

  /// No description provided for @exitBattleReward.
  ///
  /// In tr, this message translates to:
  /// **'Alacagin: {xp} XP, {gold} Altin'**
  String exitBattleReward(String xp, String gold);

  /// No description provided for @leaveBattle.
  ///
  /// In tr, this message translates to:
  /// **'Savastan Cik'**
  String get leaveBattle;

  /// No description provided for @inventory.
  ///
  /// In tr, this message translates to:
  /// **'Envanter'**
  String get inventory;

  /// No description provided for @emptyInventory.
  ///
  /// In tr, this message translates to:
  /// **'Envanter bos'**
  String get emptyInventory;

  /// No description provided for @itemDetail.
  ///
  /// In tr, this message translates to:
  /// **'Item Detay'**
  String get itemDetail;

  /// No description provided for @equip.
  ///
  /// In tr, this message translates to:
  /// **'Kusan'**
  String get equip;

  /// No description provided for @unequip.
  ///
  /// In tr, this message translates to:
  /// **'Cikar'**
  String get unequip;

  /// No description provided for @sell.
  ///
  /// In tr, this message translates to:
  /// **'Sat'**
  String get sell;

  /// No description provided for @sellConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{gold} altina sat?'**
  String sellConfirm(String gold);

  /// No description provided for @iLevel.
  ///
  /// In tr, this message translates to:
  /// **'iSv'**
  String get iLevel;

  /// No description provided for @upgrade.
  ///
  /// In tr, this message translates to:
  /// **'Guclendir'**
  String get upgrade;

  /// No description provided for @slotWeapon.
  ///
  /// In tr, this message translates to:
  /// **'Silah'**
  String get slotWeapon;

  /// No description provided for @slotHelmet.
  ///
  /// In tr, this message translates to:
  /// **'Kask'**
  String get slotHelmet;

  /// No description provided for @slotChest.
  ///
  /// In tr, this message translates to:
  /// **'Gogus'**
  String get slotChest;

  /// No description provided for @slotGloves.
  ///
  /// In tr, this message translates to:
  /// **'Eldiven'**
  String get slotGloves;

  /// No description provided for @slotPants.
  ///
  /// In tr, this message translates to:
  /// **'Pantolon'**
  String get slotPants;

  /// No description provided for @slotBoots.
  ///
  /// In tr, this message translates to:
  /// **'Cizme'**
  String get slotBoots;

  /// No description provided for @slotRing1.
  ///
  /// In tr, this message translates to:
  /// **'Yuzuk I'**
  String get slotRing1;

  /// No description provided for @slotRing2.
  ///
  /// In tr, this message translates to:
  /// **'Yuzuk II'**
  String get slotRing2;

  /// No description provided for @slotAmulet.
  ///
  /// In tr, this message translates to:
  /// **'Kolye'**
  String get slotAmulet;

  /// No description provided for @rarityCommon.
  ///
  /// In tr, this message translates to:
  /// **'Siradan'**
  String get rarityCommon;

  /// No description provided for @rarityUncommon.
  ///
  /// In tr, this message translates to:
  /// **'Yesil'**
  String get rarityUncommon;

  /// No description provided for @rarityRare.
  ///
  /// In tr, this message translates to:
  /// **'Nadir'**
  String get rarityRare;

  /// No description provided for @rarityEpic.
  ///
  /// In tr, this message translates to:
  /// **'Destansi'**
  String get rarityEpic;

  /// No description provided for @rarityLegendary.
  ///
  /// In tr, this message translates to:
  /// **'Efsanevi'**
  String get rarityLegendary;

  /// No description provided for @rarityMythic.
  ///
  /// In tr, this message translates to:
  /// **'Mitik'**
  String get rarityMythic;

  /// No description provided for @affixAtkPercent.
  ///
  /// In tr, this message translates to:
  /// **'Saldiri'**
  String get affixAtkPercent;

  /// No description provided for @affixHpFlat.
  ///
  /// In tr, this message translates to:
  /// **'Can'**
  String get affixHpFlat;

  /// No description provided for @affixCritPercent.
  ///
  /// In tr, this message translates to:
  /// **'Kritik Sans'**
  String get affixCritPercent;

  /// No description provided for @affixCritDmgPercent.
  ///
  /// In tr, this message translates to:
  /// **'Kritik Hasar'**
  String get affixCritDmgPercent;

  /// No description provided for @affixLifestealPercent.
  ///
  /// In tr, this message translates to:
  /// **'Can Cekme'**
  String get affixLifestealPercent;

  /// No description provided for @affixSpdFlat.
  ///
  /// In tr, this message translates to:
  /// **'Hiz'**
  String get affixSpdFlat;

  /// No description provided for @affixGoldFindPercent.
  ///
  /// In tr, this message translates to:
  /// **'Altin Bulma'**
  String get affixGoldFindPercent;

  /// No description provided for @affixMagicFindPercent.
  ///
  /// In tr, this message translates to:
  /// **'Buyulu Bulma'**
  String get affixMagicFindPercent;

  /// No description provided for @affixDodgePercent.
  ///
  /// In tr, this message translates to:
  /// **'Kacinma'**
  String get affixDodgePercent;

  /// No description provided for @affixResistPercent.
  ///
  /// In tr, this message translates to:
  /// **'Direnme'**
  String get affixResistPercent;

  /// No description provided for @affixHpRegenFlat.
  ///
  /// In tr, this message translates to:
  /// **'Can Yenileme'**
  String get affixHpRegenFlat;

  /// No description provided for @affixElementDmgPercent.
  ///
  /// In tr, this message translates to:
  /// **'Element Hasari'**
  String get affixElementDmgPercent;

  /// No description provided for @character.
  ///
  /// In tr, this message translates to:
  /// **'Kahraman'**
  String get character;

  /// No description provided for @equipment.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman'**
  String get equipment;

  /// No description provided for @emptySlot.
  ///
  /// In tr, this message translates to:
  /// **'Bos'**
  String get emptySlot;

  /// No description provided for @statPoints.
  ///
  /// In tr, this message translates to:
  /// **'Stat Puani'**
  String get statPoints;

  /// No description provided for @statPointsAvailable.
  ///
  /// In tr, this message translates to:
  /// **'{count} puan dagitilmamis'**
  String statPointsAvailable(String count);

  /// No description provided for @distribute.
  ///
  /// In tr, this message translates to:
  /// **'Dagit'**
  String get distribute;

  /// No description provided for @autoDistribute.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik'**
  String get autoDistribute;

  /// No description provided for @resetPoints.
  ///
  /// In tr, this message translates to:
  /// **'Sifirla'**
  String get resetPoints;

  /// No description provided for @totalStats.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Statlar'**
  String get totalStats;

  /// No description provided for @baseStats.
  ///
  /// In tr, this message translates to:
  /// **'Temel'**
  String get baseStats;

  /// No description provided for @equipBonus.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman'**
  String get equipBonus;

  /// No description provided for @change.
  ///
  /// In tr, this message translates to:
  /// **'Degistir'**
  String get change;

  /// No description provided for @noItemForSlot.
  ///
  /// In tr, this message translates to:
  /// **'Bu slot icin item yok'**
  String get noItemForSlot;

  /// No description provided for @critShort.
  ///
  /// In tr, this message translates to:
  /// **'KRIT'**
  String get critShort;

  /// No description provided for @critDmgShort.
  ///
  /// In tr, this message translates to:
  /// **'KRIT HS'**
  String get critDmgShort;

  /// No description provided for @dodgeShort.
  ///
  /// In tr, this message translates to:
  /// **'KACINMA'**
  String get dodgeShort;

  /// No description provided for @blockShort.
  ///
  /// In tr, this message translates to:
  /// **'BLOK'**
  String get blockShort;

  /// No description provided for @lifestealShort.
  ///
  /// In tr, this message translates to:
  /// **'CAN CEKME'**
  String get lifestealShort;

  /// No description provided for @resistShort.
  ///
  /// In tr, this message translates to:
  /// **'DIRENC'**
  String get resistShort;

  /// No description provided for @magicFindShort.
  ///
  /// In tr, this message translates to:
  /// **'BUYULU B.'**
  String get magicFindShort;

  /// No description provided for @hpRegenShort.
  ///
  /// In tr, this message translates to:
  /// **'CAN YEN.'**
  String get hpRegenShort;

  /// No description provided for @sortByRarity.
  ///
  /// In tr, this message translates to:
  /// **'Nadirlik'**
  String get sortByRarity;

  /// No description provided for @sortByLevel.
  ///
  /// In tr, this message translates to:
  /// **'Seviye'**
  String get sortByLevel;

  /// No description provided for @equipped.
  ///
  /// In tr, this message translates to:
  /// **'Giyili'**
  String get equipped;

  /// No description provided for @comparing.
  ///
  /// In tr, this message translates to:
  /// **'Karsilastirma'**
  String get comparing;

  /// No description provided for @blacksmith.
  ///
  /// In tr, this message translates to:
  /// **'Demirci Kubey'**
  String get blacksmith;

  /// No description provided for @upgradeItem.
  ///
  /// In tr, this message translates to:
  /// **'Guclendir'**
  String get upgradeItem;

  /// No description provided for @enchantItem.
  ///
  /// In tr, this message translates to:
  /// **'Buyule'**
  String get enchantItem;

  /// No description provided for @rerollAffix.
  ///
  /// In tr, this message translates to:
  /// **'Ozellik Yenile'**
  String get rerollAffix;

  /// No description provided for @upgradeCost.
  ///
  /// In tr, this message translates to:
  /// **'Maliyet'**
  String get upgradeCost;

  /// No description provided for @fodderRequired.
  ///
  /// In tr, this message translates to:
  /// **'Malzeme: Ayni nadirlikte 1 item'**
  String get fodderRequired;

  /// No description provided for @successRate.
  ///
  /// In tr, this message translates to:
  /// **'Basari Sansi'**
  String get successRate;

  /// No description provided for @upgradeSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Basarili! +{level}'**
  String upgradeSuccess(String level);

  /// No description provided for @upgradeFail.
  ///
  /// In tr, this message translates to:
  /// **'Basarisiz! Malzeme harcandi.'**
  String get upgradeFail;

  /// No description provided for @maxUpgrade.
  ///
  /// In tr, this message translates to:
  /// **'Maksimum seviyeye ulasti'**
  String get maxUpgrade;

  /// No description provided for @noFodder.
  ///
  /// In tr, this message translates to:
  /// **'Uygun malzeme yok'**
  String get noFodder;

  /// No description provided for @notEnoughGold.
  ///
  /// In tr, this message translates to:
  /// **'Yeterli altin yok'**
  String get notEnoughGold;

  /// No description provided for @selectFodder.
  ///
  /// In tr, this message translates to:
  /// **'Malzeme Sec'**
  String get selectFodder;

  /// No description provided for @selectItem.
  ///
  /// In tr, this message translates to:
  /// **'Item Sec'**
  String get selectItem;

  /// No description provided for @enchantFull.
  ///
  /// In tr, this message translates to:
  /// **'Ozellik yuvasi dolu'**
  String get enchantFull;

  /// No description provided for @affixAdded.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ozellik eklendi!'**
  String get affixAdded;

  /// No description provided for @affixRerolled.
  ///
  /// In tr, this message translates to:
  /// **'Ozellik yenilendi!'**
  String get affixRerolled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
