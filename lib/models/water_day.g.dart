// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterDayAdapter extends TypeAdapter<WaterDay> {
  @override
  final int typeId = 17;

  @override
  WaterDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterDay(
      id: fields[0] as String,
      totalMl: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WaterDay obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.totalMl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
