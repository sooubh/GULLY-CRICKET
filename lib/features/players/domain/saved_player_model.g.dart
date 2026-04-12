part of 'saved_player_model.dart';

class SavedPlayerAdapter extends TypeAdapter<SavedPlayer> {
  @override
  final int typeId = 7;

  @override
  SavedPlayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedPlayer(
      id: fields[0] as String,
      name: fields[1] as String,
      timesPlayed: fields[2] as int,
      lastPlayed: fields[3] as DateTime,
      totalRunsCareer: fields[4] as int,
      totalWicketsCareer: fields[5] as int,
      isFavorite: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SavedPlayer obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.timesPlayed)
      ..writeByte(3)
      ..write(obj.lastPlayed)
      ..writeByte(4)
      ..write(obj.totalRunsCareer)
      ..writeByte(5)
      ..write(obj.totalWicketsCareer)
      ..writeByte(6)
      ..write(obj.isFavorite);
  }
}
