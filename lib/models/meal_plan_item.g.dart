// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealPlanItemAdapter extends TypeAdapter<MealPlanItem> {
  @override
  final int typeId = 15;

  @override
  MealPlanItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealPlanItem(
      id: fields[0] as String,
      dateKey: fields[1] as String,
      mealType: fields[2] as int,
      description: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MealPlanItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateKey)
      ..writeByte(2)
      ..write(obj.mealType)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPlanItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
