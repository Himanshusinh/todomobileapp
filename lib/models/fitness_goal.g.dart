// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FitnessGoalAdapter extends TypeAdapter<FitnessGoal> {
  @override
  final int typeId = 19;

  @override
  FitnessGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FitnessGoal(
      id: fields[0] as String,
      title: fields[1] as String,
      targetWeightKg: fields[2] as double,
      startWeightKg: fields[3] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, FitnessGoal obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.targetWeightKg)
      ..writeByte(3)
      ..write(obj.startWeightKg);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FitnessGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
