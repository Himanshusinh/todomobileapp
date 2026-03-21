// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitLogAdapter extends TypeAdapter<HabitLog> {
  @override
  final int typeId = 11;

  @override
  HabitLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitLog(
      habitId: fields[0] as String,
      dateKey: fields[1] as String,
      completed: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.habitId)
      ..writeByte(1)
      ..write(obj.dateKey)
      ..writeByte(2)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
