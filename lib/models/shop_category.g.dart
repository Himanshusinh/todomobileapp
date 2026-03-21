// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShopCategoryAdapter extends TypeAdapter<ShopCategory> {
  @override
  final int typeId = 33;

  @override
  ShopCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      sortOrder: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ShopCategory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
