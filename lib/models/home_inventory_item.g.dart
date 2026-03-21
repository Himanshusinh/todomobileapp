// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_inventory_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HomeInventoryItemAdapter extends TypeAdapter<HomeInventoryItem> {
  @override
  final int typeId = 35;

  @override
  HomeInventoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HomeInventoryItem(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      name: fields[2] as String,
      location: fields[3] as String,
      quantity: fields[4] as int,
      notes: fields[5] as String,
      barcode: fields[6] as String,
      valueEstimate: fields[7] as double?,
      sortOrder: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HomeInventoryItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.barcode)
      ..writeByte(7)
      ..write(obj.valueEstimate)
      ..writeByte(8)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeInventoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
