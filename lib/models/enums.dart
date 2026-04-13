/// 5 Alp sınıfı
enum HeroClass {
  kalkanEr,   // Tank — İrade
  kurtBoru,   // Melee DPS — Öfke
  kam,        // Caster (Şaman) — Ruh
  yayCi,      // Ranged — Soluk
  golgeBek,   // Burst/Crit — Sır
}

/// Item nadirlik seviyeleri
enum Rarity {
  common(affixCount: 1, colorHex: 0xFF9E9E9E),      // Gri
  uncommon(affixCount: 2, colorHex: 0xFF4CAF50),     // Yeşil
  rare(affixCount: 3, colorHex: 0xFF2196F3),         // Mavi
  epic(affixCount: 3, colorHex: 0xFF9C27B0),         // Mor
  legendary(affixCount: 4, colorHex: 0xFFFF9800),    // Turuncu
  mythic(affixCount: 4, colorHex: 0xFFF44336);       // Kırmızı

  const Rarity({required this.affixCount, required this.colorHex});

  final int affixCount;
  final int colorHex;
}

/// 9 ekipman slotu
enum EquipmentSlot {
  weapon,
  helmet,
  chest,
  gloves,
  pants,
  boots,
  ring1,
  ring2,
  amulet,
}

/// Hasar tipleri
enum DamageType {
  physical,
  fire,
  ice,
  lightning,
  poison,
  dark,
}

/// Savaş şeritleri
enum Lane {
  top,
  middle,
  bottom,
}

/// Sınıfa özel kaynak tipleri
enum ResourceType {
  irade,  // Kalkan-Er — başlangıç 100
  ofke,   // Kurt-Börü — 0→100
  ruh,    // Kam — başlangıç 150
  soluk,  // Yay-Çı — başlangıç 80
  sir,    // Gölge-Bek — 0→5 stack
}
