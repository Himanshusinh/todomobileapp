// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalItemAdapter extends TypeAdapter<GoalItem> {
  @override
  final int typeId = 25;

  @override
  GoalItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      timeframe: fields[3] as int,
      targetYear: fields[4] as int,
      targetMonth: fields[5] as int?,
      progressPercent: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, GoalItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.timeframe)
      ..writeByte(4)
      ..write(obj.targetYear)
      ..writeByte(5)
      ..write(obj.targetMonth)
      ..writeByte(6)
      ..write(obj.progressPercent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
