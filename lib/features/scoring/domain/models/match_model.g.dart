part of 'match_model.dart';

class MatchModelAdapter extends TypeAdapter<MatchModel> {
  @override
  final int typeId = 6;

  @override
  MatchModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchModel(
      id: fields[0] as String,
      team1Name: fields[1] as String,
      team2Name: fields[2] as String,
      team1Players: (fields[3] as List).cast<Player>(),
      team2Players: (fields[4] as List).cast<Player>(),
      rules: fields[5] as GullyRules,
      firstInnings: fields[6] as Innings?,
      secondInnings: fields[7] as Innings?,
      winnerTeamName: fields[8] as String?,
      winDescription: fields[9] as String?,
      status: fields[10] as int,
      createdAt: fields[11] as DateTime,
      completedAt: fields[12] as DateTime?,
      tossWinnerTeamName: fields[13] as String?,
      tossDecision: fields[14] as String?,
      battingFirstTeamId: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MatchModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.team1Name)
      ..writeByte(2)
      ..write(obj.team2Name)
      ..writeByte(3)
      ..write(obj.team1Players)
      ..writeByte(4)
      ..write(obj.team2Players)
      ..writeByte(5)
      ..write(obj.rules)
      ..writeByte(6)
      ..write(obj.firstInnings)
      ..writeByte(7)
      ..write(obj.secondInnings)
      ..writeByte(8)
      ..write(obj.winnerTeamName)
      ..writeByte(9)
      ..write(obj.winDescription)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.completedAt)
      ..writeByte(13)
      ..write(obj.tossWinnerTeamName)
      ..writeByte(14)
      ..write(obj.tossDecision)
      ..writeByte(15)
      ..write(obj.battingFirstTeamId);
  }
}
