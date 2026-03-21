// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'okr_key_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OkrKeyResultAdapter extends TypeAdapter<OkrKeyResult> {
  @override
  final int typeId = 32;

  @override
  OkrKeyResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OkrKeyResult(
      id: fields[0] as String,
      objectiveId: fields[1] as String,
      title: fields[2] as String,
      current: fields[3] as double,
      target: fields[4] as double,
      unit: fields[5] as String,
      sortOrder: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OkrKeyResult obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.objectiveId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.current)
      ..writeByte(4)
      ..write(obj.target)
      ..writeByte(5)
      ..write(obj.unit)
      ..writeByte(6)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OkrKeyResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
