import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final rng = Random(42);
  final mobs = [
    'w1_yelbegen_yavrusu','w1_arcura_fidani','w1_jek_cini','w1_orman_borusu',
    'w1_agac_adam','w1_yaban_yunani','w1_albis_perisi','w1_kara_kuzgun'
  ];
  final bosses = <int, String>{
    10: 'w1_boss_obur_yelbegen',
    20: 'w1_boss_arcura_ana',
    30: 'w1_boss_kara_dis',
    40: 'w1_boss_agac_ata',
    50: 'w1_boss_yelbegen',
  };

  final stages = <Map<String, dynamic>>[];
  for (var s = 1; s <= 50; s++) {
    final waves = <List<Map<String, dynamic>>>[];
    for (var w = 0; w < 8; w++) {
      List<String> pool;
      int mobCount;
      if (s <= 5) { pool = mobs.sublist(0, 3); mobCount = 2 + rng.nextInt(2); }
      else if (s <= 15) { pool = mobs.sublist(0, 5); mobCount = 2 + rng.nextInt(3); }
      else if (s <= 25) { pool = mobs.sublist(0, 6); mobCount = 3 + rng.nextInt(2); }
      else if (s <= 35) { pool = mobs.sublist(0, 7); mobCount = 3 + rng.nextInt(3); }
      else { pool = mobs; mobCount = 3 + rng.nextInt(3); }

      final shuffled = List<String>.from(pool)..shuffle(rng);
      final chosen = shuffled.take(min(mobCount, pool.length)).toList();
      final wave = <Map<String, dynamic>>[];
      for (final m in chosen) {
        final cnt = m == 'w1_orman_borusu' ? 3 : 1 + rng.nextInt(2);
        wave.add({'enemyId': m, 'count': cnt});
      }
      waves.add(wave);
    }
    final baseGold = 15 + s * 5;
    final baseXp = 20 + s * 8;
    stages.add({
      'worldId': 1,
      'stageId': s,
      'waves': waves,
      'bossId': bosses[s],
      'rewards': {
        'goldMin': baseGold,
        'goldMax': (baseGold * 1.5).floor(),
        'xp': baseXp,
        'firstClearGold': baseGold * 3,
        'firstClearGems': s % 5 == 0 ? 5 : 0,
      },
    });
  }

  final encoder = JsonEncoder.withIndent('  ');
  File('assets/data/stages_world1.json').writeAsStringSync(encoder.convert(stages));
  print('Generated ${stages.length} stages');
}
