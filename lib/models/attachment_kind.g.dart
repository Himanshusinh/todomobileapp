// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_kind.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttachmentKindAdapter extends TypeAdapter<AttachmentKind> {
  @override
  final int typeId = 20;

  @override
  AttachmentKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AttachmentKind.image;
      case 1:
        return AttachmentKind.file;
      case 2:
        return AttachmentKind.voice;
      default:
        return AttachmentKind.image;
    }
  }

  @override
  void write(BinaryWriter writer, AttachmentKind obj) {
    switch (obj) {
      case AttachmentKind.image:
        writer.writeByte(0);
        break;
      case AttachmentKind.file:
        writer.writeByte(1);
        break;
      case AttachmentKind.voice:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachmentKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
