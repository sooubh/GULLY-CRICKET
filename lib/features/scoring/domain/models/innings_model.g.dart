part of 'innings_model.dart';

class InningsAdapter extends TypeAdapter<Innings> {
  @override
  final int typeId = 5;

  @override
  Innings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Innings(
      id: fields[0] as String,
      battingTeamId: fields[1] as String,
      bowlingTeamId: fields[2] as String,
      totalRuns: fields[3] as int,
      wickets: fields[4] as int,
      overs: (fields[5] as List).cast<Over>(),
      partnerships: (fields[6] as List).cast<Partnership>(),
      currentBatsmanId: fields[7] as String?,
      currentNonStrikerId: fields[8] as String?,
      currentBowlerId: fields[9] as String?,
      isCompleted: fields[10] as bool,
      inningsNumber: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Innings obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.battingTeamId)
      ..writeByte(2)
      ..write(obj.bowlingTeamId)
      ..writeByte(3)
      ..write(obj.totalRuns)
      ..writeByte(4)
      ..write(obj.wickets)
      ..writeByte(5)
      ..write(obj.overs)
      ..writeByte(6)
      ..write(obj.partnerships)
      ..writeByte(7)
      ..write(obj.currentBatsmanId)
      ..writeByte(8)
      ..write(obj.currentNonStrikerId)
      ..writeByte(9)
      ..write(obj.currentBowlerId)
      ..writeByte(10)
      ..write(obj.isCompleted)
      ..writeByte(11)
      ..write(obj.inningsNumber);
  }
}
