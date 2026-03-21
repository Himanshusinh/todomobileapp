// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_capture.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuickCaptureAdapter extends TypeAdapter<QuickCapture> {
  @override
  final int typeId = 24;

  @override
  QuickCapture read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuickCapture(
      id: fields[0] as String,
      body: fields[1] as String,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, QuickCapture obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.body)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickCaptureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
