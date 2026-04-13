# Onuncu Dal | Flutter Projesi

## Proje Özeti
Türk mitolojisinden ilham alan, Türkçe + İngilizce, offline çalışan 2D AFK idle RPG oyunu.
Oyuncu hafızasını kaybetmiş bir **Alp** (kahraman) seçer, 10 parçalanmış dünyayı dolaşarak
9 Kayın Tohumu toplar, Uluğ Kayın'ı onarır. Otomatik savaş + AFK offline farm + şerit stratejisi.
5 sınıf × 10 dünya × 50 stage = 500 stage. Flutter UI + Flame (savaş sahnesi).

**Ton:** Destansı, melankolik, mitolojik.
**Hikaye:** Kayıp hafıza → hatırlayış → Erlik düşman değil bekçi → gerçek düşman Ök-Yok (Boşluk).

---

## Teknik Stack
- Flutter 3.x, Dart 3.x, null safety
- UI: saf Flutter widget'ları (CustomPainter gerektiğinde)
- Savaş sahnesi: Flame Engine (sprite + animasyon)
- State: Riverpod
- Storage: Hive (local), shared_preferences (küçük ayarlar)
- Navigasyon: GoRouter
- Lokalizasyon: flutter_localizations + intl + ARB (TR + EN)
- Ses: flame_audio
- Font: Inter veya Rajdhani (TR karakter destekli)
- Palet: koyu lacivert (#0f0f1a) + altın (#FFD700) + bakır (#d4a574) + pembe (#E91E63)

---

## ÇİFT DİL DESTEĞİ — ZORUNLU
- Türkçe (varsayılan) ve İngilizce
- Cihaz dili TR → Türkçe, değilse → İngilizce
- Ayarlardan manuel dil değiştirilebilir (Hive'a kaydet)
- TÜM string'ler ARB dosyalarından gelir — KODA SABİT STRING YAZILMAZ
- `AppLocalizations.of(context).keyName` ile erişim
- Türkçe toLowerCase/toUpperCase → `tr_TR` locale kullan (i/İ sorunu)
- ARB dosyaları: `lib/l10n/app_tr.arb`, `lib/l10n/app_en.arb`

---

## Mimari Kurallar
- Game loop: savaşta tek Ticker, deltaTime, 60 FPS hedef
- Tüm balance değerleri JSON'dan yüklenir (heroes.json, enemies.json, items.json, stages.json, skills.json, worlds.json, pets.json, affixes.json, runes.json)
- Düşman ve mermi object pool ZORUNLU
- Save sistemi: Hive box'ları, her önemli değişimde auto-save + backup
- Placeholder sprite yaklaşımı: renkli dikdörtgen/daire, sonra gerçek asset

---

## 5 ALP SINIFI

| # | Sınıf Adı | Rol | Kaynak | Lv1 HP | Lv1 ATK | Lv1 DEF | Lv1 SPD | Özel Mekanik |
|---|-----------|-----|--------|--------|---------|---------|---------|--------------|
| 1 | **Kalkan-Er** | Tank | İrade (100) | 200 | 18 | 15 | 0.8 | İrade dolunca Demir Duvar (taunt + %80 hasar azaltma 5sn). Blok başarılı → İrade hızlı dolar. |
| 2 | **Kurt-Börü** | Melee DPS | Öfke (0→100) | 150 | 28 | 8 | 1.1 | Hasar al/ver → Öfke birikir. 100'de Kurt Formu (10sn: ATK+%40, SPD+%30, lifesteal+%10). |
| 3 | **Kam** (Şaman) | Caster | Ruh (150) | 110 | 32 | 5 | 0.9 | 4 element: ateş(DoT), buz(yavaşlatma), yıldırım(AoE), rüzgar(itme). Element zayıflığı → +%50 hasar. |
| 4 | **Yay-Çı** | Ranged | Soluk (80) | 120 | 24 | 7 | 1.2 | Nefes Tut: 2sn hareketsiz → sonraki ok garanti CRIT + CRIT DMG ×2. Uçan mob'lara avantajlı. |
| 5 | **Gölge-Bek** | Burst/Crit | Sır (0→5 stack) | 100 | 22 | 6 | 1.4 | Her vuruşta +1 Sır. 5 stack → Kayıp Ol (görünmez + teleport + backstab %300 hasar). |

Her sınıfın: 4 aktif skill + 6 pasif skill = 10 skill. Toplam 50 skill.

---

## STAT SİSTEMİ

### Ana Statlar
HP, Kaynak (sınıfa göre), ATK, DEF, SPD

### İkincil Statlar
CRIT % (max %75), CRIT DMG (max %500), DODGE % (max %40), BLOCK % (max %60, sadece Kalkan-Er),
LIFESTEAL % (max %25), HP REGEN, ACCURACY, RESIST (max %50), MAGIC FIND (max %300)

### Hasar Formülü
```
damage = max(1, (ATK × skillMultiplier) - DEF × 0.5) × (isCrit ? CRIT_DMG : 1.0) × (1 ± %10 random)
Dodge: hedef DODGE - saldıran ACCURACY fazlası > random(0,100) → MISS
Block: Kalkan-Er BLOCK % > random(0,100) → hasar × 0.5
```

### Level & XP
- Max level: 500
- XP formülü: `xpToNext = floor(100 × pow(level, 1.6))`
- Level-up: +5 stat puanı (oyuncu dağıtır veya auto-assign)
- Her 2 level: +1 skill puanı

---

## ŞERİT (LANE) SİSTEMİ
Savaş alanı 3 yatay şerit:
- **Üst:** Uçan mob'lar. Ranged/skill gerekli.
- **Orta:** Varsayılan. Çoğu mob burada.
- **Alt:** Sürü mob'ları, charger'lar.

Şerit değiştirme: tek dokunuş, 0.3sn geçiş, combo bozmaz.

---

## SAVAŞ MEKANİĞİ
- Gerçek zamanlı otomatik savaş
- Oyuncu müdahalesi: şerit değiştirme, skill sırası, hedef önceliği
- Her stage: 8 normal dalga + 1 elit/mini-boss (stage 10,20,30,40) veya world boss (stage 50)
- Combo meter: kesintisiz hasar → 5+ (%5 hasar), 10+ (%10 hasar, %5 XP), 20+ (%15/%10/%5), 50+ (%20/%15/%10)
- 3sn hasar vermezsen combo sıfırlanır
- Combo renk: beyaz(0)→yeşil(5+)→mavi(10+)→mor(20+)→altın(50+)

---

## ENVANTER & EKİPMAN
- 9 slot: Silah, Kask, Göğüs, Eldiven, Pantolon, Bot, Yüzük×2, Kolye
- Envanter: 60 slot (elmasla max 200, 10 slot = 50 elmas)
- Rarity: Common(gri,0-1 affix) → Uncommon(yeşil,1-2) → Rare(mavi,2-3) → Epic(mor,3) → Legendary(turuncu,3-4+soket) → Mythic(kırmızı,4+3soket)
- Affix havuzu: ATK%, HP flat, CRIT%, CRIT DMG%, lifesteal%, SPD flat, gold find%, magic find%, dodge%, resist%, HP regen, element DMG%
- Upgrade: +0→+20 (altın + fodder item). +15'ten sonra başarısızlık şansı var.
- Enchant: Rune Stone ile ekstra affix. Dünya 5'ten sonra çift enchant, Dünya 9'da üçlü enchant.
- Socket + Gem: Legendary+ item, 1-3 soket.
- Set Ekipman: Her dünyada 1 set. 2 parça bonus + 4 parça bonus.
- Pity: 50 savaş Rare+ almadıysan → garanti Rare.
- Otomatik satış filtresi: "Common oto-sat", "Uncommon oto-sat" ayarlanabilir.

---

## STAGE & FARM SİSTEMİ

### 3 Oynama Modu
1. **İlk Geçiş (Story):** Hikaye + ilk-geçiş bonusu + cutscene. 3 yıldız sistemi kilitlenir.
2. **Manuel Tekrar (Farm):** Normal ödüller, cutscene yok.
3. **AFK/Idle:** Seçilen stage'de offline otomatik farm.

### 3 Yıldız
- ⭐ Bitir
- ⭐⭐ HP %80+ bitir
- ⭐⭐⭐ 3dk altında bitir

### x2 Hızlı Savaş
25 stage geçince tüm geçilmiş stage'ler için açılır. Ücretsiz, kalıcı.

### Level Fark Cezası
- 0-9 altı: %100 normal
- 10-19 altı: drop -%50
- 20-29 altı: drop -%80
- 30+ altı: sadece altın, item yok

### Diminishing Returns
- İlk 5 tekrar: %100
- 6-15 tekrar: %80
- 16+: %60
- 24 saat sonra reset
- AFK'da uygulanmaz

### Stage Seçim UI
Her stage ikonunda: 💰(altın), ⭐(XP), 💎(item), 🧪(malzeme) göstergeleri.
Drop azalma uyarısı: level farkı büyükse uyarı pop-up.

---

## AFK / IDLE SİSTEMİ
- Offline farm: son seçilen stage'de otomatik savaş
- Max offline süre: 12 saat (Prestige ile 24 saate çıkar)
- Geri dönüş: "Yokluğunda kazandın!" pop-up
- Fast-Forward: 4 saatlik kazancı anında al (günde 2 kez ücretsiz)
- AFK stage seçimi: default = en son stage, manuel değiştirilebilir

---

## GÜNLÜK ZİNDANLAR

| Zindan | Gün | Açıklama | Ödül |
|--------|-----|----------|------|
| 💰 Altın Zindanı | Pzt, Per | 10 dalga, altın bolca | Büyük altın + altın iksiri |
| ⭐ Tecrübe Zindanı | Sal, Cum | XP yoğun | Büyük XP + XP boost |
| 🔨 Malzeme Zindanı | Çar, Cmt | Upgrade malzemesi | Rune Stone, Essence, gem |
| 🐾 Pet Zindanı | Pazar | Pet yemi + yumurta şansı | Pet yemi + %5 pet egg |
| 🏆 Haftalık Meydan | Haftada 1 | Artan zorluk, leaderboard | Pet yumurtası, legendary |

- Günde 2 ücretsiz giriş. +1 = 50 elmas.
- 3 yıldızla geçince Instant Sweep açılır (günde 2).
- Dünya 2 bitince açılır.

---

## PET SİSTEMİ

| Pet | Pasif | Aktif |
|-----|-------|-------|
| 🐺 Börü Yavrusu | +%15 ATK | Uluma (korkutma 2sn) |
| 🕊️ Hüma Kuşu | — | 1 kez dirilme (her savaş) |
| 🐂 Kök Boğa | +%20 HP | Charge AoE |
| 🐴 Tulpar | +%15 SPD | Acil kaçış (3sn dokunulmazlık) |
| 🦅 Şahin | +%10 CRIT | Hava keşfi |
| 🐉 Ejder Yavrusu | +%10 ATK | Ateş nefesi AoE DoT |
| 🦊 Ak Tilki | Gold Find +%30 | Gizli altın keşfi |
| 🐢 Kaplumbağa Ata | +%25 DEF | Kabuk kalkanı (5sn) |
| 🐟 Su Ata | HP regen +5/sn | Şifa dalgası (%15 HP) |
| 🦅 Kartal-Ana | Tüm stat +%5 | Gök gözü (5sn görünürlük) |

- 3 pet aynı anda aktif
- Pet yemi ile level (max 30)
- 3 evrim: Yavru(lv10) → Genç(lv20) → Ulu(lv30)
- Pet koleksiyonu prestige'de SİLİNMEZ

---

## PRESTIGE (YENİDEN DOĞUŞ)
- Açılma: Level 200+ ve Dünya 5 bitince
- Sıfırlanan: Level, ekipman, altın, elmas, stage ilerlemesi
- Kalıcı: Pet koleksiyonu, achievement, cosmetic, Ruh Taşı, prestige tree
- Ruh Taşı formülü: `ruhTasi = floor(sqrt(toplamStage × level / 100))`

### Prestige Tree Upgrade'leri
| Upgrade | Maliyet | Etki |
|---------|---------|------|
| Alp'in Mirası | 5 RT | +%10 tüm hasar |
| Bilge Ruh | 3 RT | +%15 XP |
| Altın Kaynağı | 3 RT | +%15 altın |
| Şanslı El | 8 RT | +%10 drop şansı |
| Uzun Uyku | 10 RT | AFK süre 12→18→24 saat |
| Kök Hafıza | 15 RT | +1 aktif skill slotu |
| Gök Bereket | 20 RT | Başlangıç rarity Common→Uncommon |

---

## RÜN SİSTEMİ (Dünya 5'te açılır)
- Körük-Er Demirhan NPC'den (Dünya 5 özel NPC) öğrenilir
- Rünler silaha kalıcı özel efekt ekler
- Rün malzemeleri: Lav Cevheri, Ruh Cevheri, dünya-özel malzemeler

---

## PARA BİRİMLERİ

| Para | Kazanım | Harcama | Prestige'de |
|------|---------|---------|-------------|
| 💰 Altın | Mob, satış, quest, AFK | Upgrade, potion, dükkan | Sıfırlanır |
| 💎 Elmas | Boss, achievement, giriş, 3-yıldız | Envanter, zindan, cosmetic | Sıfırlanır |
| 🔮 Ruh Taşı | Prestige | Prestige tree | KALICI |
| ✨ Ruh Cevheri | Nadir drop, zindan, achievement | Skill reset, rün crafting | Sıfırlanır |

---

## QUEST SİSTEMİ
- **Ana Quest:** Dünya başına 1 (hikaye ilerlemesi)
- **Yan Quest:** Dünya başına 2-3 (özel NPC'lerden)
- **Günlük Quest:** 5 adet, her gün yenilenir
- **Haftalık Quest:** 3 adet
- **Achievement:** 100+, kalıcı, elmas ödüllü
- **Günlük Giriş:** 30 günlük döngü, 7. ve 30. gün büyük ödül

---

## 10 DÜNYA — TEMA & ETKİ

| # | Dünya | Tema | Dünya Etkisi | World Boss |
|---|-------|------|--------------|------------|
| 1 | 🌲 Kayın Vadisi | Yeşil orman, zehirli sular | Sakin (yok) | Yelbegen (7 başlı) |
| 2 | 🕳️ Kör Mağaralar | Karanlık, fosforlu mantarlar | **Karanlık** — mob siluet, saldırıda parıltı | Büyük Abaası (tek göz) |
| 3 | 🏜️ Sarıkum Denizi | Çöl, gömülü şehir | **Sıcak Çarpması** — 30sn'de tüm SPD -%20 | Şahmaran (yarı yılan) |
| 4 | ❄️ Ayaz Doruk | Ebedi kış, donmuş göller | **Buzlu Zemin** — şerit değişiminde %25 kayma | Ayaz Ata (kış efendisi) |
| 5 | 🔥 Andar Ocakları | Volkan, lav nehirleri | **Lav Patlaması** — 20sn'de rastgele şeritte lav | Alaz Han (ateş tanrısı, 3 form) |
| 6 | ☁️ Ak Yayık Gökleri | Bulut kaleleri, rüzgar | **Rüzgar Sapması** — ranged %20 sapma | Ak Yayık (dev gök kuşu) |
| 7 | 🌊 Yutpa Derinlikleri | Su altı krallığı | **Su Direnci** — SPD -%30, regen +%100 | Yutpa (3 kabuklu dev) |
| 8 | ⚰️ Toybodım Nehri | Melankoli, sürekli yağmur | **Yağmur** — ateş -%40, elektrik +%30 | Duguy Han (yüz değiştiren) |
| 9 | 👑 Kara Demir Sarayı | Erlik'in sarayı | **Erlik'in Gözetimi** — boss %50'de mob buff | Erlik Han (5 fazlı) |
| 10 | 🌌 Boşluk Tengiz | Varlık-yokluk arası | **Kaos** — şeritler karışır, ekran ters döner | Ök-Yok (formsuz, 3 faz) |

Her dünyada: 8 mob + 4 mini-boss (stage 10,20,30,40) + 1 world boss (stage 50)
Dünya 9 farklı: 6 mob + 9 oğul mini-boss (her 5 stage'de) + Erlik (stage 46-50, 5 faz)
Dünya 10 farklı: 8 mob + 4 mini-boss + Ök-Yok (stage 50, 3 faz)

### Stage Scaling (dünya bazlı)
| Dünya | HP çarpanı/stage | ATK çarpanı/stage |
|-------|-----------------|-------------------|
| D1 | ×1.08 | ×1.06 |
| D2 | ×1.10 | ×1.08 |
| D3 | ×1.11 | ×1.09 |
| D4 | ×1.12 | ×1.09 |
| D5 | ×1.13 | ×1.10 |
| D6 | ×1.14 | ×1.11 |
| D7 | ×1.15 | ×1.12 |
| D8 | ×1.16 | ×1.13 |
| D9 | ×1.18 | ×1.14 |
| D10 | ×1.20 | ×1.15 |

---

## BOSS REHBER SİSTEMİ (3 Katman)
Her mini-boss bir mekanik öğretir. Oyuncu bunu fark etsin diye 3 katmanlı rehber:

1. **Savaş Öncesi İpucu:** NPC kısa bir ipucu verir (doğrudan çözüm söylemez).
2. **Savaş İçi Gösterge:** İlk denemede 10sn ekranda ikon+metin (🛤️ "Şerit dene!", 👹 "Küçükleri temizle!" vb).
3. **Yenilgi Sonrası Kart:** 3 kez kaybedince detaylı strateji kartı: boss zayıflığı, oyuncunun eksik stat'ı, tavsiye. [Ekipmanıma Git] [Tekrar Dene] [Farm Yap] butonları.

---

## SABİT NPC'LER
- **Yaşlı Kam Börteçin:** Mentor, sadece Dünya 1. Tutorial NPC.
- **Demirci Kübey:** Ekipman/upgrade, her dünyada. Upgrade, enchant, reroll, rün, dünya-özel item satışı.
- **Gezgin Bilge Mergen:** Anlatıcı/quest veren, her dünyada. Ana quest + yan quest. Kimliği gizemli (Oyun 2'de açığa çıkar).

Her dünyada ayrıca 1-2 özel NPC bulunur (şaman, tüccar, hikaye NPC'si vb).

---

## HİKAYE YAPISI (ÖZET)
- **Perde 1 (D1-3):** Uyanış. Hafıza yok. Mekanik öğrenme. İlk ipuçları.
- **Perde 2 (D4-6):** Hatırlayış. D5 dönüm noktası — Alp'in koruyucu olduğu ortaya çıkar. Boss'lar eski koruyucu pattern'i.
- **Perde 3 (D7-9):** Yüzleşme. Erlik bekçi, düşman değil. Plot twist.
- **Perde 4 (D10):** Gerçek son. Ök-Yok ile varoluş savaşı.

### 9 Hafıza Parçası (flashback)
D1: yok. D2-S25: bulanık el. D3-S30: ateş başı. D4-S35: yanan köy. D5-S20: Tengri'nin görevi. D5-S40: düşüş. D6-S25: uçuş hatırası. D7-S30: Erlik yorgun. D8-S35: Erlik ağlıyor. D9-S45: tam hafıza.

---

## CUTSCENE FORMAT
Siyah ekran + metin/seslendirme. Production basit tutulacak:
- Siyah giriş → kısa görüntü (siluet/illüstrasyon) → beyaz metin → tepki → normal oyuna dönüş
- Seslendirme yoksa yazılı metin yeterli
- Toplam 12 büyük cutscene (oyun açılış, her dünya geçişi, final)

---

## SES & GÖRSEL
- **Müzik:** Her dünya ayrı loop. Kopuz + davul + boğaz ezgisi temel. Dünyaya göre ek enstrüman.
- **SFX:** Vuruş, kritik, skill, level-up, loot, UI tık, element efektleri.
- **Parallax:** Her dünya 3 katman (uzak, orta, yakın).
- **Placeholder sprite:** İlk geliştirmede renkli geometrik şekiller, sonra gerçek asset.

---

## ONLINE / SOSYAL
- İlk sürümde online YOK (PvP yok, lonca yok)
- Tamamen offline oynanabilir
- Platform: Android + iOS + web (geliştirme için)

---

## ÖNEMLİ NOTLAR
- Tüm mob stat'ları, boss mekanikleri, NPC diyalogları, dünya detayları wiki HTML dosyalarında belgelenmiştir
- JSON veri dosyaları wiki'deki tablolardan üretilecektir
- Her prompt sonrası `flutter analyze` + `flutter run` test zorunlu
- Bir prompt'un testlerini geçmeden sonrakine ASLA geçme
