// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShoppingListItemAdapter extends TypeAdapter<ShoppingListItem> {
  @override
  final int typeId = 34;

  @override
  ShoppingListItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingListItem(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      name: fields[2] as String,
      quantityLabel: fields[3] as String,
      notes: fields[4] as String,
      isChecked: fields[5] as bool,
      unitPrice: fields[6] as double?,
      lastRecordedPrice: fields[7] as double?,
      barcode: fields[8] as String,
      sortOrder: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingListItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.quantityLabel)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.isChecked)
      ..writeByte(6)
      ..write(obj.unitPrice)
      ..writeByte(7)
      ..write(obj.lastRecordedPrice)
      ..writeByte(8)
      ..write(obj.barcode)
      ..writeByte(9)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
