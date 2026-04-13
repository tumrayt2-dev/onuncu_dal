// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Onuncu Dal';

  @override
  String get play => 'Oyna';

  @override
  String get settings => 'Ayarlar';

  @override
  String get exit => 'Cikis';

  @override
  String get newGame => 'Yeni Oyun';

  @override
  String get continueGame => 'Devam Et';

  @override
  String get chooseHero => 'Alpini Sec';

  @override
  String get heroName => 'Alpinin Adi';

  @override
  String get heroNameHint => '3-12 karakter';

  @override
  String get startAdventure => 'Maceraya Basla';

  @override
  String get heroKalkanEr => 'Kalkan-Er';

  @override
  String get heroKurtBoru => 'Kurt-Boru';

  @override
  String get heroKam => 'Kam';

  @override
  String get heroYayCi => 'Yay-Ci';

  @override
  String get heroGolgeBek => 'Golge-Bek';

  @override
  String get roleKalkanEr => 'Tank';

  @override
  String get roleKurtBoru => 'Yakin Dovus';

  @override
  String get roleKam => 'Buyucu';

  @override
  String get roleYayCi => 'Nisanci';

  @override
  String get roleGolgeBek => 'Suikastci';

  @override
  String get descKalkanEr =>
      'Irade gucuyle savunma duvari orer. Blok ve taunt ustasi.';

  @override
  String get descKurtBoru =>
      'Ofkesiyle kurt formuna girer. Yakinda olumcul, hizli.';

  @override
  String get descKam => 'Dort elementin efendisi. Ates, buz, yildirim, ruzgar.';

  @override
  String get descYayCi => 'Nefes tut, nisanla, birak. Uzak mesafenin krali.';

  @override
  String get descGolgeBek =>
      'Golgelerde saklanir, bir vurusla bitirir. Saf hasar.';

  @override
  String get resourceIrade => 'Irade';

  @override
  String get resourceOfke => 'Ofke';

  @override
  String get resourceRuh => 'Ruh';

  @override
  String get resourceSoluk => 'Soluk';

  @override
  String get resourceSir => 'Sir';

  @override
  String get hp => 'CAN';

  @override
  String get atk => 'SALDIRI';

  @override
  String get def => 'SAVUNMA';

  @override
  String get spd => 'HIZ';

  @override
  String welcomeHero(String name) {
    return 'Hos geldin, $name!';
  }

  @override
  String get deleteWarningTitle => 'Emin Misin?';

  @override
  String get deleteWarningBody =>
      'Mevcut kayit silinecek. Bu islem geri alinamaz.';

  @override
  String get cancel => 'Vazgec';

  @override
  String get confirm => 'Onayla';

  @override
  String get language => 'Dil';

  @override
  String get turkish => 'Turkce';

  @override
  String get english => 'Ingilizce';

  @override
  String get sound => 'Ses';

  @override
  String get music => 'Muzik';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get nameRequired => 'Isim gerekli';

  @override
  String get nameTooShort => 'En az 3 karakter';

  @override
  String get nameTooLong => 'En fazla 12 karakter';

  @override
  String get back => 'Geri';

  @override
  String get defeated => 'Yenildin!';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get goBack => 'Geri Don';
}
