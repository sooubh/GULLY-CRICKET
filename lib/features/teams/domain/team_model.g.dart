part of 'team_model.dart';

class TeamModelAdapter extends TypeAdapter<TeamModel> {
  @override
  final int typeId = 8;

  @override
  TeamModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TeamModel(
      id: fields[0] as String,
      name: fields[1] as String,
      shortName: fields[2] as String?,
      colorHex: (fields[3] as String?) ?? '#2E7D32',
      playerNames: (fields[4] as List?)?.cast<String>() ?? const <String>[],
      createdAt: (fields[5] as DateTime?) ?? DateTime.now(),
      matchesPlayed: (fields[6] as int?) ?? 0,
      wins: (fields[7] as int?) ?? 0,
      losses: (fields[8] as int?) ?? 0,
      ties: (fields[9] as int?) ?? 0,
      isFavorite: (fields[10] as bool?) ?? false,
      captainName: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TeamModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.shortName)
      ..writeByte(3)
      ..write(obj.colorHex)
      ..writeByte(4)
      ..write(obj.playerNames)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.matchesPlayed)
      ..writeByte(7)
      ..write(obj.wins)
      ..writeByte(8)
      ..write(obj.losses)
      ..writeByte(9)
      ..write(obj.ties)
      ..writeByte(10)
      ..write(obj.isFavorite)
      ..writeByte(11)
      ..write(obj.captainName);
  }
}
