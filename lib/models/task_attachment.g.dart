// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_attachment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAttachmentAdapter extends TypeAdapter<TaskAttachment> {
  @override
  final int typeId = 21;

  @override
  TaskAttachment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskAttachment(
      id: fields[0] as String,
      taskId: fields[1] as String,
      localPath: fields[2] as String,
      kind: fields[3] as AttachmentKind,
      displayName: fields[4] as String,
      addedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TaskAttachment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.localPath)
      ..writeByte(3)
      ..write(obj.kind)
      ..writeByte(4)
      ..write(obj.displayName)
      ..writeByte(5)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAttachmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
