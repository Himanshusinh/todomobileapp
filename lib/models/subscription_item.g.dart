// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionItemAdapter extends TypeAdapter<SubscriptionItem> {
  @override
  final int typeId = 7;

  @override
  SubscriptionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionItem(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      cycle: fields[3] as SubscriptionCycle,
      nextRenewalDate: fields[4] as DateTime,
      notes: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.cycle)
      ..writeByte(4)
      ..write(obj.nextRenewalDate)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriptionCycleAdapter extends TypeAdapter<SubscriptionCycle> {
  @override
  final int typeId = 6;

  @override
  SubscriptionCycle read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubscriptionCycle.monthly;
      case 1:
        return SubscriptionCycle.yearly;
      default:
        return SubscriptionCycle.monthly;
    }
  }

  @override
  void write(BinaryWriter writer, SubscriptionCycle obj) {
    switch (obj) {
      case SubscriptionCycle.monthly:
        writer.writeByte(0);
        break;
      case SubscriptionCycle.yearly:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionCycleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
