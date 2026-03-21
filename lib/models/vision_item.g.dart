// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vision_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VisionItemAdapter extends TypeAdapter<VisionItem> {
  @override
  final int typeId = 29;

  @override
  VisionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisionItem(
      id: fields[0] as String,
      title: fields[1] as String,
      caption: fields[2] as String,
      imagePath: fields[3] as String?,
      sortOrder: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VisionItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.caption)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
