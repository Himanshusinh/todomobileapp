// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskItemAdapter extends TypeAdapter<TaskItem> {
  @override
  final int typeId = 0;

  @override
  TaskItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      priority: fields[3] as TaskPriority,
      dueDate: fields[4] as DateTime?,
      isCompleted: fields[5] as bool,
      subTasks: (fields[6] as List?)?.cast<SubTask>(),
      recurringInterval: fields[7] as RecurringInterval,
      dependencies: (fields[8] as List?)?.cast<String>(),
      tags: (fields[9] as List?)?.cast<String>(),
      dueTime: fields[11] as DateTime?,
      categoryId: fields[12] as String?,
      startTime: fields[13] as DateTime?,
      endTime: fields[14] as DateTime?,
      durationMinutes: fields[15] as int?,
      estimatedMinutes: fields[16] as int?,
      actualMinutes: fields[17] as int?,
      expenseAmount: fields[19] as double?,
      noteMarkdown: (fields[20] as String?) ?? '',
    )
      .._orderIndex = fields[10] as int?
      .._isFavorited = fields[18] as bool?;
  }

  @override
  void write(BinaryWriter writer, TaskItem obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.subTasks)
      ..writeByte(7)
      ..write(obj.recurringInterval)
      ..writeByte(8)
      ..write(obj.dependencies)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj._orderIndex)
      ..writeByte(11)
      ..write(obj.dueTime)
      ..writeByte(12)
      ..write(obj.categoryId)
      ..writeByte(13)
      ..write(obj.startTime)
      ..writeByte(14)
      ..write(obj.endTime)
      ..writeByte(15)
      ..write(obj.durationMinutes)
      ..writeByte(16)
      ..write(obj.estimatedMinutes)
      ..writeByte(17)
      ..write(obj.actualMinutes)
      ..writeByte(18)
      ..write(obj._isFavorited)
      ..writeByte(19)
      ..write(obj.expenseAmount)
      ..writeByte(20)
      ..write(obj.noteMarkdown);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 2;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.high;
      case 3:
        return TaskPriority.urgent;
      default:
        return TaskPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.low:
        writer.writeByte(0);
        break;
      case TaskPriority.medium:
        writer.writeByte(1);
        break;
      case TaskPriority.high:
        writer.writeByte(2);
        break;
      case TaskPriority.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurringIntervalAdapter extends TypeAdapter<RecurringInterval> {
  @override
  final int typeId = 3;

  @override
  RecurringInterval read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurringInterval.none;
      case 1:
        return RecurringInterval.daily;
      case 2:
        return RecurringInterval.weekly;
      case 3:
        return RecurringInterval.monthly;
      case 4:
        return RecurringInterval.custom;
      default:
        return RecurringInterval.none;
    }
  }

  @override
  void write(BinaryWriter writer, RecurringInterval obj) {
    switch (obj) {
      case RecurringInterval.none:
        writer.writeByte(0);
        break;
      case RecurringInterval.daily:
        writer.writeByte(1);
        break;
      case RecurringInterval.weekly:
        writer.writeByte(2);
        break;
      case RecurringInterval.monthly:
        writer.writeByte(3);
        break;
      case RecurringInterval.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringIntervalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
