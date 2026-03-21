// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MilestoneItemAdapter extends TypeAdapter<MilestoneItem> {
  @override
  final int typeId = 26;

  @override
  MilestoneItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MilestoneItem(
      id: fields[0] as String,
      parentGoalId: fields[1] as String,
      title: fields[2] as String,
      dueDate: fields[3] as DateTime?,
      progressPercent: fields[4] as int,
      isCompleted: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MilestoneItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentGoalId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.progressPercent)
      ..writeByte(5)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilestoneItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
