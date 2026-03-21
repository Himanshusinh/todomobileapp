// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brainstorm_idea.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BrainstormIdeaAdapter extends TypeAdapter<BrainstormIdea> {
  @override
  final int typeId = 23;

  @override
  BrainstormIdea read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrainstormIdea(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      colorValue: fields[3] as int,
      orderIndex: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BrainstormIdea obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.orderIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrainstormIdeaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
