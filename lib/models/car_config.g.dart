// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CarConfigAdapter extends TypeAdapter<CarConfig> {
  @override
  final int typeId = 1;

  @override
  CarConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CarConfig(
      carId: fields[0] as String,
      colorIndex: fields[1] as int,
      engineUpgrade: fields[2] as int,
      handlingUpgrade: fields[3] as int,
      brakeUpgrade: fields[4] as int,
      owned: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CarConfig obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.carId)
      ..writeByte(1)
      ..write(obj.colorIndex)
      ..writeByte(2)
      ..write(obj.engineUpgrade)
      ..writeByte(3)
      ..write(obj.handlingUpgrade)
      ..writeByte(4)
      ..write(obj.brakeUpgrade)
      ..writeByte(5)
      ..write(obj.owned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
