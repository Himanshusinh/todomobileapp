// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_board.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectBoardAdapter extends TypeAdapter<ProjectBoard> {
  @override
  final int typeId = 27;

  @override
  ProjectBoard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectBoard(
      id: fields[0] as String,
      title: fields[1] as String,
      colorValue: fields[2] as int,
      sortOrder: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectBoard obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBoardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
