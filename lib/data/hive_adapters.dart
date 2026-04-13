import 'package:hive/hive.dart';
import '../models/affix.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/hero_character.dart';
import '../models/skill.dart';
import '../models/stats.dart';

/// Hive type ID sabitleri
abstract final class HiveTypeIds {
  static const stats = 0;
  static const affix = 1;
  static const item = 2;
  static const skill = 3;
  static const heroCharacter = 4;
  static const heroClass = 10;
  static const rarity = 11;
  static const equipmentSlot = 12;
  static const affixType = 13;
  static const skillType = 14;
}

// ─── Enum Adapters ───

class HeroClassAdapter extends TypeAdapter<HeroClass> {
  @override
  final int typeId = HiveTypeIds.heroClass;
  @override
  HeroClass read(BinaryReader reader) => HeroClass.values[reader.readInt()];
  @override
  void write(BinaryWriter writer, HeroClass obj) => writer.writeInt(obj.index);
}

class RarityAdapter extends TypeAdapter<Rarity> {
  @override
  final int typeId = HiveTypeIds.rarity;
  @override
  Rarity read(BinaryReader reader) => Rarity.values[reader.readInt()];
  @override
  void write(BinaryWriter writer, Rarity obj) => writer.writeInt(obj.index);
}

class EquipmentSlotAdapter extends TypeAdapter<EquipmentSlot> {
  @override
  final int typeId = HiveTypeIds.equipmentSlot;
  @override
  EquipmentSlot read(BinaryReader reader) =>
      EquipmentSlot.values[reader.readInt()];
  @override
  void write(BinaryWriter writer, EquipmentSlot obj) =>
      writer.writeInt(obj.index);
}

class AffixTypeAdapter extends TypeAdapter<AffixType> {
  @override
  final int typeId = HiveTypeIds.affixType;
  @override
  AffixType read(BinaryReader reader) => AffixType.values[reader.readInt()];
  @override
  void write(BinaryWriter writer, AffixType obj) =>
      writer.writeInt(obj.index);
}

class SkillTypeEnumAdapter extends TypeAdapter<SkillType> {
  @override
  final int typeId = HiveTypeIds.skillType;
  @override
  SkillType read(BinaryReader reader) => SkillType.values[reader.readInt()];
  @override
  void write(BinaryWriter writer, SkillType obj) =>
      writer.writeInt(obj.index);
}

// ─── Model Adapters ───

class StatsAdapter extends TypeAdapter<Stats> {
  @override
  final int typeId = HiveTypeIds.stats;

  @override
  Stats read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Stats.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Stats obj) {
    writer.writeMap(obj.toJson());
  }
}

class AffixAdapter extends TypeAdapter<Affix> {
  @override
  final int typeId = HiveTypeIds.affix;

  @override
  Affix read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Affix.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Affix obj) {
    writer.writeMap(obj.toJson());
  }
}

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = HiveTypeIds.item;

  @override
  Item read(BinaryReader reader) {
    final map = _castDeep(reader.readMap());
    return Item.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer.writeMap(obj.toJson());
  }
}

class SkillAdapter extends TypeAdapter<Skill> {
  @override
  final int typeId = HiveTypeIds.skill;

  @override
  Skill read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Skill.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Skill obj) {
    writer.writeMap(obj.toJson());
  }
}

class HeroCharacterAdapter extends TypeAdapter<HeroCharacter> {
  @override
  final int typeId = HiveTypeIds.heroCharacter;

  @override
  HeroCharacter read(BinaryReader reader) {
    final map = _castDeep(reader.readMap());
    return HeroCharacter.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, HeroCharacter obj) {
    writer.writeMap(obj.toJson());
  }
}

/// Hive okurken Map donebilir, derin cast gerekli
Map<String, dynamic> _castDeep(Map<dynamic, dynamic> raw) {
  return raw.map((key, value) {
    final k = key.toString();
    if (value is Map) {
      return MapEntry(k, _castDeep(value));
    } else if (value is List) {
      return MapEntry(
        k,
        value.map((e) => e is Map ? _castDeep(e) : e).toList(),
      );
    }
    return MapEntry(k, value);
  });
}

/// Tüm Hive adapter'ları kaydet — main.dart'tan çağrılır
void registerHiveAdapters() {
  Hive.registerAdapter(HeroClassAdapter());
  Hive.registerAdapter(RarityAdapter());
  Hive.registerAdapter(EquipmentSlotAdapter());
  Hive.registerAdapter(AffixTypeAdapter());
  Hive.registerAdapter(SkillTypeEnumAdapter());
  Hive.registerAdapter(StatsAdapter());
  Hive.registerAdapter(AffixAdapter());
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(SkillAdapter());
  Hive.registerAdapter(HeroCharacterAdapter());
}
