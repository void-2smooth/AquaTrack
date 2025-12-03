// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter packages pub run build_runner build

part of 'water_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterEntryAdapter extends TypeAdapter<WaterEntry> {
  @override
  final int typeId = 0;

  @override
  WaterEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterEntry(
      id: fields[0] as String,
      amountMl: fields[1] as double,
      timestamp: fields[2] as DateTime,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WaterEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amountMl)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 1;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      dailyGoalMl: fields[0] as double? ?? 2000,
      useMetricUnits: fields[1] as bool? ?? true,
      notificationsEnabled: fields[2] as bool? ?? false,
      reminderIntervalMinutes: fields[3] as int? ?? 60,
      isDarkMode: fields[4] as bool? ?? false,
      currentStreak: fields[5] as int? ?? 0,
      longestStreak: fields[6] as int? ?? 0,
      lastActiveDate: fields[7] as DateTime?,
      userName: fields[8] as String?,
      weightKg: fields[9] as double?,
      activityLevel: fields[10] as int?,
      useCustomGoal: fields[11] as bool? ?? true,
      calculatedGoalMl: fields[12] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.dailyGoalMl)
      ..writeByte(1)
      ..write(obj.useMetricUnits)
      ..writeByte(2)
      ..write(obj.notificationsEnabled)
      ..writeByte(3)
      ..write(obj.reminderIntervalMinutes)
      ..writeByte(4)
      ..write(obj.isDarkMode)
      ..writeByte(5)
      ..write(obj.currentStreak)
      ..writeByte(6)
      ..write(obj.longestStreak)
      ..writeByte(7)
      ..write(obj.lastActiveDate)
      ..writeByte(8)
      ..write(obj.userName)
      ..writeByte(9)
      ..write(obj.weightKg)
      ..writeByte(10)
      ..write(obj.activityLevel)
      ..writeByte(11)
      ..write(obj.useCustomGoal)
      ..writeByte(12)
      ..write(obj.calculatedGoalMl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}


