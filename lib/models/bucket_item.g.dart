// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bucket_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BucketItemAdapter extends TypeAdapter<BucketItem> {
  @override
  final int typeId = 30;

  @override
  BucketItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BucketItem(
      id: fields[0] as String,
      title: fields[1] as String,
      notes: fields[2] as String,
      isDone: fields[3] as bool,
      completedAt: fields[4] as DateTime?,
      sortOrder: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BucketItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.isDone)
      ..writeByte(4)
      ..write(obj.completedAt)
      ..writeByte(5)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BucketItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
