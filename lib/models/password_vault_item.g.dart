// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_vault_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PasswordVaultItemAdapter extends TypeAdapter<PasswordVaultItem> {
  @override
  final int typeId = 37;

  @override
  PasswordVaultItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PasswordVaultItem(
      id: fields[0] as String,
      siteName: fields[1] as String,
      websiteUrl: fields[2] as String,
      username: fields[3] as String,
      notes: fields[4] as String,
      sortOrder: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PasswordVaultItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.siteName)
      ..writeByte(2)
      ..write(obj.websiteUrl)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordVaultItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
