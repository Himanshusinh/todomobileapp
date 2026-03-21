// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kanban_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KanbanItemAdapter extends TypeAdapter<KanbanItem> {
  @override
  final int typeId = 28;

  @override
  KanbanItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KanbanItem(
      id: fields[0] as String,
      boardId: fields[1] as String,
      title: fields[2] as String,
      notes: fields[3] as String,
      column: fields[4] as int,
      orderIndex: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, KanbanItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.boardId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.column)
      ..writeByte(5)
      ..write(obj.orderIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KanbanItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
