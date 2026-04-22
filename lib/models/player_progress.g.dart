// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerProgressAdapter extends TypeAdapter<PlayerProgress> {
  @override
  final int typeId = 0;

  @override
  PlayerProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerProgress(
      totalScore: fields[0] as int,
      coins: fields[1] as int,
      unlockedLevels: (fields[2] as List).cast<int>(),
      levelStars: (fields[3] as List).cast<int>(),
      levelBestTimes: (fields[4] as List).cast<int>(),
      levelBestScores: (fields[5] as List).cast<int>(),
      selectedCarId: fields[6] as String,
      selectedColorIndex: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerProgress obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.totalScore)
      ..writeByte(1)
      ..write(obj.coins)
      ..writeByte(2)
      ..write(obj.unlockedLevels)
      ..writeByte(3)
      ..write(obj.levelStars)
      ..writeByte(4)
      ..write(obj.levelBestTimes)
      ..writeByte(5)
      ..write(obj.levelBestScores)
      ..writeByte(6)
      ..write(obj.selectedCarId)
      ..writeByte(7)
      ..write(obj.selectedColorIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
