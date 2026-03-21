// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'okr_objective.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OkrObjectiveAdapter extends TypeAdapter<OkrObjective> {
  @override
  final int typeId = 31;

  @override
  OkrObjective read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OkrObjective(
      id: fields[0] as String,
      title: fields[1] as String,
      periodLabel: fields[2] as String,
      sortOrder: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OkrObjective obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.periodLabel)
      ..writeByte(3)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OkrObjectiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
