// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlyBudgetAdapter extends TypeAdapter<MonthlyBudget> {
  @override
  final int typeId = 9;

  @override
  MonthlyBudget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlyBudget(
      id: fields[0] as String,
      year: fields[1] as int,
      month: fields[2] as int,
      limitAmount: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlyBudget obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.limitAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyBudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
