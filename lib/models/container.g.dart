// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter packages pub run build_runner build

part of 'container.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterContainerAdapter extends TypeAdapter<WaterContainer> {
  @override
  final int typeId = 2;

  @override
  WaterContainer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterContainer(
      id: fields[0] as String,
      name: fields[1] as String,
      amountMl: fields[2] as double,
      icon: fields[3] as String,
      colorValue: fields[4] as int,
      createdAt: fields[5] as DateTime,
      isDefault: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WaterContainer obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amountMl)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterContainerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

