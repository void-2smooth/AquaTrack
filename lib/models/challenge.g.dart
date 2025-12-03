// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActiveChallengeAdapter extends TypeAdapter<ActiveChallenge> {
  @override
  final int typeId = 5;

  @override
  ActiveChallenge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActiveChallenge(
      challengeId: fields[0] as String,
      startDate: fields[1] as DateTime,
      endDate: fields[2] as DateTime,
      status: fields[3] != null 
          ? ChallengeStatus.values[fields[3] as int]
          : ChallengeStatus.active,
      progress: fields[4] as Map<String, dynamic>? ?? {},
      completed: fields[5] as bool? ?? false,
      completedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ActiveChallenge obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.challengeId)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.status.index)
      ..writeByte(4)
      ..write(obj.progress)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveChallengeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

