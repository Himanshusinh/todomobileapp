// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WishlistItemAdapter extends TypeAdapter<WishlistItem> {
  @override
  final int typeId = 36;

  @override
  WishlistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WishlistItem(
      id: fields[0] as String,
      title: fields[1] as String,
      notes: fields[2] as String,
      url: fields[3] as String,
      priceEstimate: fields[4] as double?,
      isPurchased: fields[5] as bool,
      recipient: fields[6] as String,
      categoryId: fields[7] as String,
      barcode: fields[8] as String,
      sortOrder: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WishlistItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.priceEstimate)
      ..writeByte(5)
      ..write(obj.isPurchased)
      ..writeByte(6)
      ..write(obj.recipient)
      ..writeByte(7)
      ..write(obj.categoryId)
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
      other is WishlistItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
