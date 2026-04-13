import 'dart:math';

import '../models/stats.dart';

/// Saldiri sonucu
class AttackResult {
  const AttackResult({
    required this.damage,
    required this.isCrit,
    required this.isMiss,
    required this.isBlocked,
  });

  final double damage;
  final bool isCrit;
  final bool isMiss;
  final bool isBlocked;
}

/// Hasar hesaplama servisi
class CombatService {
  CombatService._();

  static final _rng = Random();

  /// CLAUDE.md formulu:
  /// damage = max(1, (ATK * skillMultiplier) - DEF * 0.5) * (isCrit ? CRIT_DMG : 1.0) * (1 +/- 10% random)
  /// Dodge: hedef DODGE - saldiran ACCURACY fazlasi > random(0,100) -> MISS
  /// Block: Kalkan-Er BLOCK % > random(0,100) -> hasar * 0.5
  static AttackResult calculateDamage({
    required Stats attacker,
    required Stats defender,
    double skillMultiplier = 1.0,
  }) {
    // Dodge check
    final dodgeChance = (defender.dodge - attacker.accuracy).clamp(0, 40);
    if (_rng.nextDouble() * 100 < dodgeChance) {
      return const AttackResult(
        damage: 0,
        isCrit: false,
        isMiss: true,
        isBlocked: false,
      );
    }

    // Crit check
    final isCrit =
        _rng.nextDouble() * 100 < attacker.crit.clamp(0, 75);
    final critMultiplier =
        isCrit ? (attacker.critDmg.clamp(150, 500) / 100) : 1.0;

    // Base damage
    final baseDmg =
        (attacker.atk * skillMultiplier - defender.def * 0.5).clamp(1, double.infinity);

    // Random variance +/- 10%
    final variance = 0.9 + _rng.nextDouble() * 0.2;

    var finalDmg = baseDmg * critMultiplier * variance;

    // Block check
    final isBlocked = _rng.nextDouble() * 100 < defender.block.clamp(0, 60);
    if (isBlocked) {
      finalDmg *= 0.5;
    }

    return AttackResult(
      damage: finalDmg,
      isCrit: isCrit,
      isMiss: false,
      isBlocked: isBlocked,
    );
  }

  /// Saldiri hizi: SPD 1.0 = saniyede 1 vurus
  static double attackInterval(double spd) {
    if (spd <= 0) return 2.0;
    return 1.0 / spd;
  }
}
