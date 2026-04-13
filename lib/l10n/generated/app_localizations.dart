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
  /// **'Onuncu Dal'**
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
