# Onuncu Dal — Flutter Prompt Planı v2

## 🎯 Kullanım Stratejisi

1. `CLAUDE.md` dosyasını proje kök dizinine kopyala
2. Prompt'ları sırayla Claude Code'a yapıştır
3. **HER PROMPT SONRASI TEST ZORUNLU** — `flutter analyze` + `flutter run`
4. Her prompt'un altındaki ✅ kontrol listesini takip et
5. Tüm kontroller geçtiyse sonraki prompt'a geç

**Her prompt arası Claude Code'a:**
> "Devam etmeden önce mevcut kodu flutter analyze ile kontrol et ve hataları düzelt"

**⚠️ KRİTİK: Bir prompt'un testlerini geçmeden sonrakine ASLA geçme!**

---

# MILESTONE 1 — İskelet + Menü + Save (Prompt 1-6)

## PROMPT 1.1 — Proje Oluştur

```
Flutter ile 2D AFK idle RPG oyunu geliştireceğiz. Proje adı: Onunda Dal CLAUDE.md'yi oku ve tüm kurallara uy.

pubspec.yaml'a ekle:
- flame ^1.18.0
- flame_audio ^2.10.0
- hive ^2.2.3, hive_flutter ^1.1.0
- flutter_riverpod ^2.5.0
- go_router ^14.0.0
- intl, flutter_localizations
- google_fonts ^6.2.1

Klasör yapısı:
lib/
├── main.dart
├── app.dart                 (MaterialApp + GoRouter)
├── core/
│   ├── constants.dart       (renkler, boyutlar)
│   ├── theme.dart           (koyu tema)
│   └── extensions.dart
├── l10n/
│   ├── app_tr.arb
│   └── app_en.arb
├── models/
├── data/
├── services/
├── providers/
├── screens/
├── widgets/
├── game/
└── assets/
    └── data/

main.dart: Hive.initFlutter(), ProviderScope, MaterialApp.
İlk ekran: ana menü (Oyna / Ayarlar / Çıkış — henüz işlev yok).
Koyu tema uygula (arka plan #0f0f1a, vurgu altın #FFD700, metin #e0e0e0).
Inter fontu ekle.
l10n.yaml oluştur, ARB'de: appTitle, play, settings, exit, newGame, continueGame.
```

### ✅ Test
- [ ] `flutter analyze` → 0 hata
- [ ] `flutter run` → uygulama açılıyor
- [ ] Ana menüde 3 buton, Türkçe yazıyor
- [ ] Koyu tema, altın vurgular uygulanmış
- [ ] Cihaz EN ise İngilizce görünüyor

---

## PROMPT 1.2 — Model Katmanı (Enum + Base)

```
CLAUDE.md'deki sınıf, stat, rarity bilgilerine göre temel modelleri oluştur:

lib/models/ altına:
- enums.dart:
  - HeroClass enum: kalkanEr, kurtBoru, kam, yayCi, golgeBek
  - Rarity enum: common, uncommon, rare, epic, legendary, mythic (her birinin rengi + affix sayısı)
  - EquipmentSlot enum: weapon, helmet, chest, gloves, pants, boots, ring1, ring2, amulet
  - DamageType enum: physical, fire, ice, lightning, poison, dark
  - Lane enum: top, middle, bottom
  - ResourceType enum: irade, ofke, ruh, soluk, sir

- stats.dart:
  - Stats sınıfı: hp, mp, atk, def, spd, crit, critDmg, dodge, block, lifesteal, hpRegen, accuracy, resist, magicFind
  - copyWith, toJson/fromJson, operator+ (iki stat'ı toplama)

Henüz Hive adapter yazmana gerek yok, sadece temel modeller.
Her model immutable olsun (final fields + copyWith).
```

### ✅ Test
- [ ] `flutter analyze` → 0 hata
- [ ] Enum'lar doğru tanımlı, 5 hero sınıfı Türkçe adlarla
- [ ] Stats sınıfı copyWith ile çalışıyor

---

## PROMPT 1.3 — Hero + Item + Enemy Modelleri

```
CLAUDE.md'deki envanter, item, düşman bilgilerine göre kalan modelleri oluştur:

lib/models/ altına:
- affix.dart: Affix { id, type (AffixType enum), value, isPercent }
  - AffixType: atkPercent, hpFlat, critPercent, critDmgPercent, lifestealPercent, spdFlat, goldFindPercent, magicFindPercent, dodgePercent, resistPercent, hpRegenFlat, elementDmgPercent
- item.dart: Item { id, nameKey (ARB key), slot, rarity, iLevel, baseStats, affixes List, upgradeLevel, sockets, gems }
- hero_character.dart: HeroCharacter { id, name, heroClass, level, xp, statPoints, skillPoints, baseStats, equipment Map<EquipmentSlot,Item?>, inventory List<Item>, gold, gems, soulStones, essences }
- skill.dart: Skill { id, nameKey, heroClass, type (active/passive), level, maxLevel(5), cooldown, descriptionKey }
- enemy.dart: Enemy { id, nameKey, archetype, worldId, baseStats, lootTable, lane, specialAbility }
- stage.dart: Stage { worldId, stageId, waves, bossId, rewards, stars }
- world_data.dart: WorldData { id, nameKey, theme, worldEffect, bossId }

Tüm modeller: toJson/fromJson, copyWith.
```

### ✅ Test
- [ ] `flutter analyze` → 0 hata
- [ ] Tüm modeller import edilebiliyor, instance oluşturulabiliyor
- [ ] JSON serialize/deserialize çalışıyor

---

## PROMPT 1.4 — JSON Veri Dosyaları (Dünya 1)

```
assets/data/ altına Dünya 1 için JSON dosyaları oluştur. CLAUDE.md'deki stat tablolarını kullan:

1. heroes.json: 5 sınıfın base stat'ları + level-up artış oranları. CLAUDE.md'deki tablodaki değerleri aynen kullan.

2. enemies_world1.json: Dünya 1'in 8 mob'u:
   - Yelbegen Yavrusu (Melee, Orta, HP:45, ATK:9, DEF:2, SPD:1.0)
   - Arçura Fidanı (Caster, Orta, HP:40, ATK:14, DEF:1, SPD:0.7)
   - Jek Cini (Fast, Orta, HP:30, ATK:11, DEF:1, SPD:1.5)
   - Orman Börüsü (Pack, Alt, HP:35, ATK:10, DEF:3, SPD:1.3)
   - Ağaç-Adam (Tank, Orta, HP:120, ATK:8, DEF:10, SPD:0.5)
   - Yaban Yunanı (Charger, Alt, HP:65, ATK:13, DEF:5, SPD:0.9)
   - Albıs Perisi (Buffer, Orta, HP:50, ATK:8, DEF:2, SPD:0.8)
   - Kara Kuzgun (Flying, Üst, HP:25, ATK:12, DEF:1, SPD:1.4)
   Her mob'a lootTable ekle: goldMin, goldMax, xp, itemDropChance, specialDrop.

3. bosses_world1.json: 4 mini-boss + Yelbegen world boss. Her boss'un HP, ATK, DEF, SPD, mekanik açıklaması, ödülleri.

4. stages_world1.json: 50 stage. Her stage: stageId, waves (mob listesi + sayıları), isBoss (10,20,30,40,50), rewards.

5. affixes.json: 12 affix tipi, min-max değer aralıkları.

6. items_base.json: Her slot için 3'er base item (Common/Uncommon/Rare) = 27 item.

7. skills.json: 5 sınıf × 10 skill = 50 skill. Her skill: id, nameKey, heroClass, type, maxLevel, cooldown, descriptionKey, effectPerLevel.

lib/data/json_loader.dart: Tüm JSON'ları parse eden servis. App başlarken çağrılır.
```

### ✅ Test
- [ ] `flutter analyze` → 0 hata
- [ ] App açılışında console: "Loaded 5 heroes, 8 enemies, 50 stages, 50 skills, 27 items, 12 affixes"
- [ ] JSON'larda TR ve EN nameKey'ler var

---

## PROMPT 1.5 — Hive + Save Sistemi

```
1. lib/data/hive_adapters.dart:
   - HeroCharacter, Item, Affix, Stats, Skill için Hive TypeAdapter'lar kaydet
   - main.dart'ta registerAdapter çağrıları ekle

2. lib/services/save_service.dart:
   - Hive box 'player' aç
   - createNewPlayer(HeroClass, String name) → HeroCharacter oluştur, kaydet
   - loadPlayer() → HeroCharacter? döndür
   - savePlayer(HeroCharacter) → kaydet
   - deletePlayer() → sil
   - autoSave() → her kritik aksiyonda çağrılır
   - Yedekleme: save öncesi backup kopyası

3. lib/providers/player_provider.dart (Riverpod StateNotifier):
   - state: HeroCharacter?
   - notifyListeners ile UI güncelleme
   - addXp(int), addGold(int), equipItem(Item, EquipmentSlot), unequipItem(EquipmentSlot)
```

### ✅ Test
- [ ] `flutter analyze` → 0 hata
- [ ] HeroCharacter oluşturulup Hive'a kaydedilebiliyor
- [ ] App kapanıp açılınca kayıt korunuyor

---

## PROMPT 1.6 — Karakter Seçim + Ana Menü Güncelleme

```
1. lib/screens/hero_select_screen.dart:
   - 5 Alp sınıfını yatay PageView ile göster (büyük kart, placeholder ikon)
   - Her kartta: sınıf adı (Kalkan-Er, Kurt-Börü, Kam, Yay-Çı, Gölge-Bek)
   - Kısa açıklama, base HP/ATK/DEF/SPD, özel mekanik (İrade/Öfke/Ruh/Soluk/Sır)
   - Rol etiketi (Tank/DPS/Caster/Ranged/Burst) badge ile
   - "İsim gir" TextField (3-12 karakter, TR karakter destekli)
   - "Maceraya Başla" butonu
   - Kart renkleri sınıfa göre (mavi/kırmızı/mor/yeşil/mor)

2. Ana menü güncelleme:
   - Save varsa → "Devam Et" + "Yeni Oyun" (uyarı ile: mevcut kayıt silinecek)
   - Save yoksa → "Oyna" → hero select
   - Karakter seçildikten sonra geçici main_game_screen (sadece "Hoş geldin [isim]!" yazsın)

3. lib/screens/settings_screen.dart:
   - Dil değiştirme (TR/EN) → Hive'a kaydet, app yeniden başla
   - Placeholder: ses, müzik, bildirim toggle'ları (henüz işlev yok)

4. ARB'ye 50+ yeni string ekle (sınıf isimleri, açıklamalar, butonlar, uyarılar).
```

### ✅ Test
- [ ] 5 sınıf swipe ile görünüyor, Türkçe isimler doğru
- [ ] İsim girilmeden başlanamıyor (validation)
- [ ] Oyun kapanıp açılınca "Devam Et" çıkıyor
- [ ] Yeni Oyun uyarı veriyor
- [ ] Dil değişince tüm metinler değişiyor
- [ ] `flutter analyze` temiz

---

# MILESTONE 2 — İlk Savaş MVP (Prompt 2.1-2.6)

## PROMPT 2.1 — Flame Savaş Sahnesi Kurulumu

```
lib/game/ altına Flame tabanlı savaş sahnesi kur:

1. battle_game.dart: FlameGame extend eden BattleGame sınıfı
   - 3 şerit sistemi (üst/orta/alt) — sabit y pozisyonları
   - Arka plan: tek renkli gradient (şimdilik)
   - Kamera: sabit, yatay scroll yok

2. hero_component.dart: SpriteComponent extend eden HeroComponent
   - Placeholder: renkli dikdörtgen (sınıf renginde, 40×60px)
   - Pozisyon: sol taraf, seçili şerit
   - Basit idle animasyonu (hafif yukarı-aşağı sallanma)

3. enemy_component.dart: SpriteComponent extend eden EnemyComponent
   - Placeholder: farklı renkli dikdörtgen (mob türüne göre)
   - Pozisyon: sağ taraftan yaklaşır
   - HP bar (üstte küçük çubuk)

4. lane_system.dart: 3 şerit yönetimi
   - Şerit pozisyonları (y koordinatları)
   - Dokunma ile şerit değiştirme (0.3sn geçiş animasyonu)
   - Şerit göstergesi (hangi şeritte olduğun UI'da belli)

5. lib/screens/battle_screen.dart: GameWidget ile BattleGame'i embed et.
   - Üstte HP/kaynak barı, altta skill butonları (placeholder)
   - Stage bilgisi, dalga sayısı göstergesi
```

### ✅ Test
- [ ] Savaş ekranı açılıyor, Flame çalışıyor
- [ ] Hero sol tarafta, şerit ortada görünüyor
- [ ] Dokunma ile 3 şerit arası geçiş yapılıyor (animasyonlu)
- [ ] Placeholder enemy sağ tarafta görünüyor
- [ ] HP bar çalışıyor

---

## PROMPT 2.2 — Basit Savaş Mekaniği

```
lib/services/combat_service.dart + Flame component güncellemeleri:

1. Otomatik saldırı sistemi:
   - Hero SPD'ye göre vuruş hızı (SPD 1.0 = saniyede 1 vuruş)
   - Hero aynı şeritteki en yakın enemy'ye otomatik saldırır
   - Hasar formülü: CLAUDE.md'deki formül → max(1, (ATK × 1.0) - DEF × 0.5) × (1 ± %10 random)
   - CRIT kontrolü: CRIT% > random → hasar × CRIT_DMG
   - Dodge kontrolü: hedef DODGE > random → MISS

2. Hasar göstergeleri (floating text):
   - Normal hasar: beyaz rakam, yukarı kayarak söner
   - Kritik: sarı, büyük font, "!" ile
   - Miss: gri "MISS" yazısı
   - Heal: yeşil rakam

3. Enemy AI:
   - Enemy hedefe (hero) doğru yürür
   - Menzile girince saldırır (aynı şerit kontrolü)
   - Farklı şeritteyse yaklaşmaz (melee mob)
   - HP 0 → ölüm animasyonu (küçülüp kaybolma)

4. Hero ölümü:
   - HP 0 → "Yenildin" ekranı
   - "Tekrar Dene" / "Geri Dön" butonları
```

### ✅ Test
- [ ] Hero otomatik saldırıyor, enemy hasar alıyor
- [ ] Hasar rakamları ekranda görünüyor
- [ ] Kritik vuruş sarı ve büyük
- [ ] Miss "MISS" yazıyor
- [ ] Enemy ölünce kaybolıyor
- [ ] Hero ölünce "Yenildin" ekranı

---

## PROMPT 2.3 — Dalga Sistemi + XP/Altın

```
1. lib/services/wave_service.dart:
   - Stage'den mob listesini al (stages_world1.json)
   - 8 dalga: her dalgada 2-5 mob spawn (JSON'dan)
   - Mob'lar sağ taraftan gelir, aralarında 0.5-1sn gecikme
   - Dalga temizlenince 2sn bekleme → sonraki dalga
   - Dalga sayacı UI'da göster (Dalga 3/8)

2. XP ve altın kazanımı:
   - Her mob öldüğünde: XP + altın (JSON'daki değerler)
   - Ekranda küçük "+12 XP", "+5 altın" popup
   - Stage sonunda toplam: "Kazandın! 150 XP, 80 altın" özet ekranı

3. Level-up:
   - XP yetince level atla
   - Level-up efekti (ekran parlaması + ses placeholder)
   - +5 stat puanı → şimdilik otomatik dağıt (auto-assign)
   - +1 skill puanı (her 2 level)

4. Stage tamamlama:
   - Tüm dalgalar bitince → "Stage Tamamlandı!" ekranı
   - XP, altın, item drop (şimdilik sadece altın)
   - 3 yıldız hesapla (HP %, süre)
   - "Devam" → stage map'e dön (şimdilik ana menüye)
```

### ✅ Test
- [ ] 8 dalga sırayla geliyor, sayaç doğru
- [ ] Mob öldüğünde XP + altın kazanılıyor
- [ ] Level atlama çalışıyor
- [ ] Stage tamamlanınca özet ekranı
- [ ] 3 yıldız hesaplanıyor

---

## PROMPT 2.4 — Combo Meter + Kaynak Sistemi

```
1. Combo meter:
   - Kesintisiz hasar → combo sayacı artar
   - UI'da combo sayısı göstergesi (büyük rakam)
   - 3sn hasar vermezsen combo sıfırlanır
   - Bonuslar: 10+ → +%5 hasar, 25+ → +%10 hasar +%5 XP, 50+ → +%15/+%10/+%5, 100+ → +%20/+%15/+%10/+%5
   - Combo renk değişimi: beyaz→yeşil→mavi→mor→altın

2. Kaynak sistemi (sınıfa göre):
   - Kalkan-Er: İrade (100 max). Blok başarılı → +10. Zamanla +2/sn.
   - Kurt-Börü: Öfke (0→100). Hasar al/ver → +öfke. 100'de Kurt Formu tetiklenir.
   - Kam: Ruh (150 max). Zamanla +5/sn. Skill kullanınca harcanır.
   - Yay-Çı: Soluk (80 max). Zamanla +3/sn. Nefes Tut mekaniği.
   - Gölge-Bek: Sır (0→5 stack). Her vuruşta +1. 5'te Kayıp Ol tetiklenir.

3. Kaynak barı UI:
   - HP barının altında, sınıf renginde kaynak barı
   - Dolu olunca parıldama efekti (special ready)

4. Basit special ability (her sınıfa 1 tane, placeholder):
   - Kaynak dolunca otomatik tetiklenir
   - Kalkan-Er: 5sn hasar azaltma
   - Kurt-Börü: 10sn ATK+%40
   - Kam: AoE hasar (tüm şeritler)
   - Yay-Çı: Garanti CRIT
   - Gölge-Bek: Backstab %300 hasar
```

### ✅ Test
- [ ] Combo sayacı çalışıyor, 3sn'de sıfırlanıyor
- [ ] Combo bonusları uygulanıyor
- [ ] Her sınıfın kaynak barı doğru çalışıyor
- [ ] Kaynak dolunca special ability tetikleniyor
- [ ] Kurt-Börü öfke birikimi doğru

---

## PROMPT 2.5 — Loot Sistemi

```
1. lib/services/loot_service.dart:
   - Mob öldüğünde loot hesapla (JSON'daki drop şansları)
   - Item oluşturma: base item seç → rarity belirle → affix sayısı (rarity'ye göre) → random affix ekle
   - iLevel = mevcut stage numarası
   - Gold drop: her mob %100 (min-max arası random)
   - Pity sistem: 50 savaş rare+ almadıysan → garanti rare

2. Loot gösterimi:
   - Mob öldüğünde yere item düşer (küçük renkli kutu, rarity renginde)
   - Otomatik toplama (idle oyun)
   - Ekranda kısa popup: item ismi + rarity rengi
   - Nadir+ drop'ta ekstra efekt (ışık patlaması)

3. lib/models/loot_table.dart:
   - LootTable { goldMin, goldMax, xp, itemDropChance, specialDrops }
   - SpecialDrop { itemId, chance, minStage }
```

### ✅ Test
- [ ] Mob öldüğünde altın düşüyor
- [ ] Item drop çalışıyor (düşük oranda ama test modda artırılabilir)
- [ ] Item'ın rarity'si doğru, affix sayısı rarity'ye uygun
- [ ] Pity sayacı çalışıyor

---

## PROMPT 2.6 — Tam Savaş Döngüsü Birleştirme

```
Şu ana kadar yapılanları birleştir:

1. Oyun akışı:
   Ana Menü → (yeni oyun) Karakter Seç → İsim Gir → Stage 1 Savaş → Stage Bitti → Tekrar / Ana Menü

2. Savaş sonucu kaydı:
   - XP, altın, loot → HeroCharacter'a ekle → Hive'a kaydet
   - Level atladıysa stat artışı kaydet

3. Stage ilerlemesi:
   - Stage 1 geçildi → Stage 2 açık (basit stage counter)
   - En yüksek stage kaydı

4. Basit debug panel:
   - Ayarlar ekranına: "DEV" bölümü
   - Hızlı level atla (+10 level butonu)
   - Altın ekle (+1000)
   - Stage atla (+5)
   - Bu butonlar sadece debug için, release'de gizle

5. Performans kontrolü:
   - 60 FPS hedefi kontrol et
   - Object pool: en az enemy'ler için pool yap (spawn/despawn)
   - Memory leak kontrolü
```

### ✅ Test
- [ ] Tam döngü çalışıyor: menü → seç → savaş → kazan → tekrar
- [ ] Kayıt korunuyor (kapat-aç)
- [ ] XP, altın, level doğru birikiyorl
- [ ] Debug panel çalışıyor
- [ ] 60 FPS, takılma yok
- [ ] **MİLESTONE 2 BİTTİ: 1 stage gerçekten oynanabiliyor**

---

# MILESTONE 3 — Döngü Kapanışı (Prompt 3.1-3.5)

## PROMPT 3.1 — Envanter Ekranı

```
lib/screens/inventory_screen.dart:
- Grid görünümde envanter (60 slot)
- Her slot: item ikonu (rarity renginde placeholder kare), isim, iLevel
- Boş slot: gri çerçeve
- Item'a tıkla → detay popup: stat listesi, affix'ler, rarity, iLevel, upgrade level
- "Kuşan" / "Çıkar" / "Sat" butonları
- Satış: item rarity'sine göre altın (Common:10, Uncommon:50, Rare:200, Epic:1000)
- Sağ üstte: toplam altın göstergesi
```

### ✅ Test
- [ ] Envanter açılıyor, loot'tan düşen item'lar görünüyor
- [ ] Item detayları doğru (stat, affix, rarity)
- [ ] Kuşanma çalışıyor (slot uyumu kontrolü)
- [ ] Satış çalışıyor, altın artıyor

---

## PROMPT 3.2 — Ekipman Sistemi + Stat Hesaplama

```
1. Ekipman slotları UI:
   - Karakter ekranı: 9 slot görsel (silah, kask, göğüs, eldiven, pantolon, bot, yüzük×2, kolye)
   - Her slot: kuşanılmış item gösterir veya boş
   - Kuşanılmış item'a tıkla → "Çıkar" / "Değiştir"

2. Stat hesaplama servisi (lib/services/stat_calculator.dart):
   - Toplam stat = base stat + level bonus + ekipman stat'ları + ekipman affix'leri + set bonusu (şimdilik yok)
   - Karakter ekranında toplam stat göster
   - Stat değişim preview: yeni item kuşanmadan önce "+12 ATK ↑" gibi karşılaştırma

3. Stat puanı dağıtım ekranı:
   - Mevcut dağıtılmamış puan göster
   - HP, ATK, DEF, SPD, CRIT'e +/- butonlarla dağıt
   - "Otomatik Dağıt" butonu (sınıfa göre optimal)
   - "Onayla" butonu
```

### ✅ Test
- [ ] 9 ekipman slotu doğru çalışıyor
- [ ] Item kuşanınca stat artıyor
- [ ] Item çıkarınca stat azalıyor
- [ ] Stat preview doğru hesaplıyor
- [ ] Stat puanı dağıtımı çalışıyor

---

## PROMPT 3.3 — Upgrade Sistemi (Kübey)

```
lib/screens/upgrade_screen.dart (Demirci Kübey NPC ekranı):

1. Item Upgrade (+0 → +20):
   - Item seç → "Güçlendir" butonu
   - Maliyet: altın + aynı rarity fodder item
   - Her + base stat %5 artır
   - +15'ten sonra başarısızlık: %20 (+15), %30 (+16), %40 (+17), %50 (+18-20)
   - Başarısızlıkta item kaybolmaz, sadece malzeme harcanır
   - Başarı/başarısızlık animasyonu (yeşil parıltı / kırmızı titreme)

2. Upgrade gösterimi:
   - Item adının yanında "+3" gibi seviye
   - Her + için stat artış preview

3. Enchant (basit):
   - "Büyüle" butonu
   - Maliyet: Ruh Cevheri
   - Item'a 1 ekstra random affix ekler
   - Mevcut affix reroll seçeneği (aynı maliyet)
```

### ✅ Test
- [ ] Item +1'den +5'e kadar upgrade edilebiliyor
- [ ] Maliyet doğru hesaplanıyor
- [ ] Stat artışı doğru
- [ ] Enchant çalışıyor (affix ekleniyor)
- [ ] Başarısızlık animasyonu çalışıyor

---

## PROMPT 3.4 — Stage Map Ekranı

```
lib/screens/stage_map_screen.dart:

1. Dünya 1 stage haritası:
   - Dikey scroll liste (50 stage)
   - Her stage: numara, isim, yıldız sayısı (0-3), kilit durumu
   - Geçilmiş: renkli, yıldızlarla
   - Aktif (en son açılan): parlayan çerçeve
   - Kilitli: gri, kilit ikonu
   - Mini-boss stage'leri (10,20,30,40): özel ikon (kılıç)
   - World boss stage (50): büyük ikon (ejder)

2. Stage detay popup:
   - Stage'e tıkla → detay: mob listesi, tahmini zorluk, ödüller
   - "Savaş!" butonu
   - Farm göstergeleri: 💰⭐💎🧪 ikonları (şimdilik placeholder)

3. Dünya geçişi:
   - Stage 50 geçilince → "Dünya 2 Açıldı!" popup
   - Dünya seçici (üstte tab veya dropdown)
   - Şimdilik sadece Dünya 1 aktif

4. Navigasyon:
   - Alt navbar: Savaş (stage map) / Kahraman / Envanter / Dükkan (placeholder) / Ayarlar
```

### ✅ Test
- [ ] Stage map 50 stage gösteriyor
- [ ] Geçilmiş/aktif/kilitli doğru
- [ ] Yıldızlar doğru
- [ ] Mini-boss ve boss stage'leri farklı ikon
- [ ] Stage'e tıklayınca detay popup + savaş başlatma
- [ ] Alt navbar çalışıyor

---

## PROMPT 3.5 — Döngü Birleştirme

```
Tüm M3 sistemlerini birleştir ve tam döngüyü kapat:

1. Tam oyun akışı:
   Menü → Karakter Seç → Stage Map → Stage Seç → Savaş → Kazan → Loot Al → Envanter Kontrol → Upgrade → Sonraki Stage

2. Otomatik satış filtresi:
   - Ayarlar'da: "Common otomatik sat" toggle
   - Aktifse Common item'lar düştüğünde otomatik satılır

3. İksir sistemi (basit):
   - HP Potion: tam HP iyileştirme (savaşta kullanılabilir, 3 adet limit)
   - Kübey'den satın al (100 altın)
   - Savaş UI'da iksir butonu

4. Quick-equip:
   - Loot ekranında düşen item'a dokunca: "Kuşan" (mevcut slottakinden iyiyse yeşil ok göster)

5. Kayıt bütünlüğü:
   - Tüm ilerleme (stage, level, envanter, altın) kayıt ediliyor
   - Kapat-aç testleri
```

### ✅ Test
- [ ] Tam döngü pürüzsüz: savaş → loot → upgrade → sonraki savaş
- [ ] Otomatik satış çalışıyor
- [ ] İksir çalışıyor
- [ ] Quick-equip çalışıyor
- [ ] Kapat-aç sonrası her şey korunuyor
- [ ] **MİLESTONE 3 BİTTİ: Kendi başına oynanır mini oyun**

---

# MILESTONE 4 — AFK + Skill + Timing (Prompt 4.1-4.5)

## PROMPT 4.1 — AFK Offline Hesaplama
```
lib/services/afk_calculator.dart:
- Son çıkış zamanını kaydet (Hive)
- Geri dönüşte geçen süreyi hesapla (max 12 saat)
- Offline kazanç: seçili stage'in ortalama altın/dakika × süre, XP/dakika × süre
- Item drop: offline süre / ortalama stage süresi × drop şansı
- "Yokluğunda Kazandın!" popup: altın, XP, item listesi
- "Topla" butonu → tümünü HeroCharacter'a ekle
- Fast-Forward: 4 saatlik kazancı anında al butonu (günde 2 kez ücretsiz)
```

## PROMPT 4.2 — Skill Ağacı
```
lib/screens/skill_tree_screen.dart:
- 4 aktif + 6 pasif skill listesi (sınıfa göre JSON'dan)
- Her skill: isim, açıklama, level (0-5), maliyet (1 skill puanı)
- Level-up butonu (puan varsa)
- Aktif skill: cooldown, hasar çarpanı, efekt açıklaması
- Pasif skill: sürekli bonus (%crit, %lifesteal vb)
- Skill öncelik sırası: 4 aktif skill'i sürükle-bırak ile sırala
- Skill reset: 10 Ruh Cevheri ile tüm puanlar geri döner
```

## PROMPT 4.3 — Skill'leri Savaşa Entegre Et
```
- Aktif skill'ler cooldown dolunca otomatik tetiklenir (öncelik sırasına göre)
- Her skill'in savaş efekti: hasar, buff, debuff, AoE, heal
- Cooldown göstergesi UI'da (skill butonu üstünde dairesel progress)
- Pasif skill bonusları stat hesaplamasına ekle
- Kam'ın 4 element büyüsü: ateş DoT, buz yavaşlatma, yıldırım AoE, rüzgar itme
```

## PROMPT 4.4 — Timing + Uyarı Sistemi
```
- Bazı enemy saldırıları uyarı gösterir (1-2sn önce kırmızı alan)
- Oyuncu şerit değiştirerek kaçınabilir
- Kaçınma başarılı → küçük XP bonusu
- Mini-boss'larda mekanik uyarıları (şerit değiştir ikonu, add temizle ikonu)
- Boss Rehber Sistemi Katman 2: ilk denemede 10sn ekranda ipucu metni
```

## PROMPT 4.5 — AFK + Skill Birleştirme
```
- AFK modda skill'ler otomatik kullanılır (öncelik sırasına göre)
- AFK kazanç hesaplamasında skill bonusları dahil
- Skill tree değişikliği AFK kazancını etkiler
- Test: tüm 5 sınıfla savaş + AFK + skill çalışıyor
```

### ✅ Milestone 4 Test
- [ ] AFK offline kazanç çalışıyor (kapat, 1dk bekle, aç → kazanç popup)
- [ ] 10 skill (4 aktif + 6 pasif) savaşta çalışıyor
- [ ] Skill öncelik sırası etkili
- [ ] Timing/uyarı sistemi çalışıyor
- [ ] **MİLESTONE 4 BİTTİ: Oyunun özüne dokunduk**

---

# MILESTONE 5 — Dünya 1 Tam (Prompt 5.1-5.6)

## PROMPT 5.1 — Dünya 1 Parallax + Ortam
```
- 3 katmanlı parallax arka plan (placeholder renkli katmanlar)
- Hava durumu sistemi: güneşli (default), sis (stage 20+), yağmur (stage 35+)
- Ses placeholder: ambiyans loop (basit ses dosyası veya sessizlik)
```

## PROMPT 5.2 — 8 Mob Tam Mekanik
```
- 8 mob'un özel yetenekleri tam çalışıyor (JSON'dan):
  - Arçura Fidanı: -%30 SPD yavaşlatma
  - Jek Cini: şerit değiştirme
  - Albıs Perisi: +%30 ATK buff yakınlara
  - Kara Kuzgun: sadece ranged ile vurulur
  - vb (CLAUDE.md + wiki referans)
```

## PROMPT 5.3 — 4 Mini-Boss Tam Mekanik
```
- Stage 10: Obur Yelbegen (add çağırma + yutma)
- Stage 20: Arçura Ana (3 şeritte kök, şerit zorunlu)
- Stage 30: Börü Reisi Kara-Diş (uluma + kudurma)
- Stage 40: Yaşlı Ağaç-Ata (sadece CRIT hasar alır)
- Boss Rehber: Katman 1 (NPC ipucu) + Katman 2 (savaş içi gösterge) + Katman 3 (3 yenilgi sonrası strateji kartı)
```

## PROMPT 5.4 — Yelbegen World Boss
```
- 7 başlı dev yılan: her baş ayrı HP (3.200), aynı anda 3 aktif
- Baş yenilenme: 20sn sonra %40 HP ile geri gelir, -%15 maks HP
- 3 kez yenilenen baş tamamen ölür
- 7 başın elementleri: 2× ateş, 2× buz, 1× yıldırım, 1× zehir, 1× fiziksel
- Çıldırma fazı: 2+ baş aynı anda kesilirse 8sn vurulmaz ama ATK -%50
- 3 ekran fazı: Sakin → Uyanış (3 baş ölünce) → Çılgınlık (5 baş ölünce)
```

## PROMPT 5.5 — NPC'ler + Cutscene
```
- Kam Börteçin: tutorial diyalogları (ilk 3 stage)
- Demirci Kübey: upgrade ekranı erişimi
- Gezgin Mergen: quest verme UI
- Cutscene sistemi: siyah ekran + metin + "Devam" butonu
- Yelbegen yenilgi cutscene: son söz + tohum alma + Dünya 2 açılma
```

## PROMPT 5.6 — Dünya 1 Ödüller + Farm Tavsiyesi
```
- Yelbegen ilk geçiş ödülü: 15.000 altın, 200 elmas, Kayın Tohumu #1, garanti pet yumurtası, epic item
- 3 yıldız bonusları her stage için
- Farm tavsiyesi UI: stage seçim ekranında 💰⭐💎🧪 ikonları
- Stage'lerdeki farm değerlendirmesi (wiki'den)
- Dünya 2 unlock pop-up
```

### ✅ Milestone 5 Test
- [ ] Dünya 1 başından sonuna oynanabiliyor
- [ ] 8 mob özel yetenekleri çalışıyor
- [ ] 4 mini-boss mekaniği çalışıyor
- [ ] Yelbegen 7 başlı boss mekaniği çalışıyor
- [ ] NPC diyalogları çalışıyor
- [ ] Cutscene çalışıyor
- [ ] Ödüller doğru veriliyor
- [ ] **MİLESTONE 5 BİTTİ: Dünya 1 tam deneyim**

---

# MILESTONE 6 — Ekonomi + Sosyal (Prompt 6.1-6.5)

## PROMPT 6.1 — Dükkan Sistemi
```
- Kübey dükkanı: iksir, meşale, su şişesi vb satışı
- Elmas dükkanı: envanter genişletme, cosmetic
- Dünya-özel item'lar (her dünya NPC'sinden)
```

## PROMPT 6.2 — Quest Sistemi Tam
```
- Ana quest (dünya başına 1)
- Yan quest (NPC'lerden 2-3)
- Günlük quest (5 adet, her gün yenilenir)
- Haftalık quest (3 adet)
- Quest takip UI, ödül toplama
```

## PROMPT 6.3 — Günlük Giriş + Achievement
```
- 30 günlük giriş döngüsü
- Achievement sistemi (100+ achievement)
- Achievement popup + elmas ödülü
```

## PROMPT 6.4 — Günlük Zindanlar
```
- 5 zindan tipi (Altın/XP/Malzeme/Pet/Haftalık Meydan)
- Gün kontrolü, 2 ücretsiz giriş
- Zindan savaş mekaniği (10 dalga)
- Instant Sweep (3 yıldızla geçince)
```

## PROMPT 6.5 — Ekonomi Birleştirme
```
- Tüm para birimleri akışı test
- Altın/elmas/ruh taşı/ruh cevheri dengesi
- Enflasyon kontrolü (geç oyun altın bolluğu)
```

### ✅ Milestone 6 Test
- [ ] Dükkan çalışıyor
- [ ] Quest sistemi çalışıyor (al, takip, tamamla, ödül)
- [ ] Günlük giriş çalışıyor
- [ ] 5 zindan çalışıyor
- [ ] **MİLESTONE 6 BİTTİ: Oyuncu ilerleme sebepleri çeşitlendi**

---

# MILESTONE 7 — Pet + Prestige + Rün (Prompt 7.1-7.4)

## PROMPT 7.1 — Pet Sistemi
```
- 10 pet (JSON'dan)
- Pet yumurtası açma (animasyon)
- 3 aktif pet seçimi
- Pet level (yem ile, max 30)
- 3 evrim aşaması
- Pet savaşta: pasif bonus + aktif yetenek (cooldown)
```

## PROMPT 7.2 — Prestige Sistemi
```
- Açılma koşulu: Level 200+ ve Dünya 5 bitmiş
- Prestige yapma UI: uyarı, onay, sıfırlama animasyonu
- Ruh Taşı hesaplama
- Prestige tree: 7 upgrade (CLAUDE.md'den)
- Kalıcı kayıtlar (pet, achievement, cosmetic, ruh taşı)
```

## PROMPT 7.3 — Rün Sistemi
```
- Körük-Er Demirhan NPC (Dünya 5'te açılır)
- Rün crafting UI
- 4 rün: Alev, Arınma, Yeniden Doğuş, Od Ana'nın Mührü
- Silaha rün uygulama, efekt savaşta
```

## PROMPT 7.4 — Uzun Vade Birleştirme
```
- Pet + prestige + rün birlikte çalışma testi
- Prestige sonrası yeniden başlama akışı
- Ruh Taşı dükkanı
- Pet evrim quest'leri
```

### ✅ Milestone 7 Test
- [ ] Pet sistemi tam çalışıyor (yumurta, level, evrim, savaş)
- [ ] Prestige yapılabiliyor, doğru sıfırlanıyor, ruh taşı kazanılıyor
- [ ] Rün crafting ve silaha uygulama çalışıyor
- [ ] **MİLESTONE 7 BİTTİ: Uzun vadeli döngü tamamlandı**

---

# MILESTONE 8 — Dünya 2-5 (Prompt 8.1-8.8)

Her dünya için 2 prompt: 1) mob + ortam + dünya etkisi, 2) mini-boss + world boss + NPC + ödül.
Wiki sayfalarındaki tüm detaylar referans.

## PROMPT 8.1-8.2 — Dünya 2: Kör Mağaralar
## PROMPT 8.3-8.4 — Dünya 3: Sarıkum Denizi
## PROMPT 8.5-8.6 — Dünya 4: Ayaz Doruk
## PROMPT 8.7-8.8 — Dünya 5: Andar Ocakları

### ✅ Milestone 8 Test
- [ ] 4 yeni dünya oynanabiliyor (D2-D5)
- [ ] Her dünya etkisi çalışıyor (karanlık, sıcak, buz, lav)
- [ ] 32 yeni mob, 16 mini-boss, 4 world boss çalışıyor
- [ ] Hafıza flashback'ları (parça 1-5) çalışıyor
- [ ] Prestige Dünya 5 sonunda açılıyor
- [ ] **MİLESTONE 8 BİTTİ: 5 dünya oynanıyor**

---

# MILESTONE 9 — Dünya 6-10 + Finale (Prompt 9.1-9.10)

## PROMPT 9.1-9.2 — Dünya 6: Ak Yayık Gökleri
## PROMPT 9.3-9.4 — Dünya 7: Yutpa Derinlikleri
## PROMPT 9.5-9.6 — Dünya 8: Toybodım Nehri
## PROMPT 9.7-9.8 — Dünya 9: Kara Demir Sarayı (Erlik + 9 oğul)
## PROMPT 9.9-9.10 — Dünya 10: Boşluk Tengiz (Ök-Yok + final)

### ✅ Milestone 9 Test
- [ ] 10 dünya tam oynanabiliyor
- [ ] Tüm dünya etkileri çalışıyor
- [ ] 80+ mob, 40+ mini-boss, 10 world boss
- [ ] 9 hafıza parçası + 12 cutscene
- [ ] Erlik 5 fazlı boss + plot twist
- [ ] Ök-Yok final boss + gerçek son cutscene
- [ ] Credits + credits sonrası sahne
- [ ] **MİLESTONE 9 BİTTİ: Tam kampanya oynanabiliyor**

---

# MILESTONE 10 — Cila + Release (Prompt 10.1-10.6)

## PROMPT 10.1 — Ses + Müzik
```
- Her dünya için müzik loop
- SFX: vuruş, kritik, skill, level-up, loot, UI, element efektleri
- Boss müzikleri (farklı)
- Ses ayarları (müzik/sfx ayrı volume)
```

## PROMPT 10.2 — Görsel Cila
```
- Parallax arka planlar dünya başına (basit ama atmosferik)
- Parçacık efektleri: kıvılcım, kar, yağmur, lav, kabarcık
- Ekran geçiş animasyonları
- UI polish: buton hover, press efektleri
```

## PROMPT 10.3 — Tutorial Sistemi
```
- İlk 3 stage: Börteçin tutorial diyalogları
- İşaret eden ok + highlight
- "Şerit değiştir!", "Skill kullan!", "Item kuşan!" adımları
- Tutorial skip seçeneği
```

## PROMPT 10.4 — New Game+ & Endgame
```
- New Game+: mob stat ×1.5, boss'lara yeni mekanik
- Sonsuz Zindan: bitmez, her 10 kat zor
- Boss Rush modu
- Leaderboard (yerel)
```

## PROMPT 10.5 — Performans + Test
```
- Tüm ekranlar profiling
- Memory leak kontrolü
- 60 FPS garanti
- Flutter analyze 0 hata 0 uyarı
- Edge case testleri (envanter dolu, altın 0, max level)
```

## PROMPT 10.6 — Release Build
```
- Android APK + iOS build ayarları
- App icon, splash screen
- Uygulama adı: "Onuncu Dal"
- Store açıklaması (TR + EN)
- Screenshot'lar
- Son test: tam oyun baştan sona 1 kez oyna
```

### ✅ Milestone 10 Test
- [ ] Ses + müzik çalışıyor
- [ ] Görsel cilalı
- [ ] Tutorial çalışıyor
- [ ] New Game+ çalışıyor
- [ ] Performans OK
- [ ] Release build hazır
- [ ] **MİLESTONE 10 BİTTİ: YAYINA HAZIR**
