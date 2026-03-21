// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepEntryAdapter extends TypeAdapter<SleepEntry> {
  @override
  final int typeId = 13;

  @override
  SleepEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepEntry(
      id: fields[0] as String,
      dateKey: fields[1] as String,
      hoursSlept: fields[2] as double,
      quality: fields[3] as int?,
      note: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SleepEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateKey)
      ..writeByte(2)
      ..write(obj.hoursSlept)
      ..writeByte(3)
      ..write(obj.quality)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
