// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_quality.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterQualityAdapter extends TypeAdapter<WaterQuality> {
  @override
  final int typeId = 0;

  @override
  WaterQuality read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterQuality(
      id: fields[0] as String?,
      ph: fields[1] as double,
      temperature: fields[2] as double,
      dissolvedOxygen: fields[3] as double,
      turbidity: fields[4] as double,
      timestamp: fields[5] as DateTime,
      location: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WaterQuality obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ph)
      ..writeByte(2)
      ..write(obj.temperature)
      ..writeByte(3)
      ..write(obj.dissolvedOxygen)
      ..writeByte(4)
      ..write(obj.turbidity)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.location);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterQualityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
