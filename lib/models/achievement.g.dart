// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UnlockedAchievementAdapter extends TypeAdapter<UnlockedAchievement> {
  @override
  final int typeId = 4;

  @override
  UnlockedAchievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnlockedAchievement(
      achievementId: fields[0] as String,
      unlockedAt: fields[1] as DateTime,
      seen: fields[2] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, UnlockedAchievement obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.achievementId)
      ..writeByte(1)
      ..write(obj.unlockedAt)
      ..writeByte(2)
      ..write(obj.seen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnlockedAchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

