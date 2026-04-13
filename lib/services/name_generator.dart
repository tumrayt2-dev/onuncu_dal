import 'dart:math';

/// Turk mitolojisi temasinda rastgele isim uretici
class NameGenerator {
  NameGenerator._();

  static final _rng = Random();

  static const _prefixes = [
    'Alp', 'Kara', 'Ak', 'Gok', 'Demir',
    'Kut', 'Bay', 'Er', 'Kor', 'Boz',
    'Ulu', 'Kok', 'Yar', 'Ton', 'Soy',
    'Ata', 'Bas', 'Oz', 'Tig', 'Kel',
  ];

  static const _suffixes = [
    'han', 'bek', 'tug', 'bay', 'alp',
    'er', 'kan', 'tim', 'tay', 'dag',
    'kut', 'sun', 'tas', 'yol', 'gul',
    'din', 'nur', 'mir', 'ten', 'bol',
  ];

  /// Rastgele bir isim uret
  static String generate() {
    final prefix = _prefixes[_rng.nextInt(_prefixes.length)];
    final suffix = _suffixes[_rng.nextInt(_suffixes.length)];
    return '$prefix$suffix';
  }
}
