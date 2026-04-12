part of 'player_model.dart';

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 1;

  @override
  Player read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Player(
      id: fields[0] as String,
      name: fields[1] as String,
      teamId: fields[2] as String,
      runsScored: fields[3] as int,
      ballsFaced: fields[4] as int,
      isOut: fields[5] as bool,
      isRetired: fields[6] as bool,
      isRetiredHurt: fields[7] as bool,
      wicketType: fields[8] as String?,
      dismissedBy: fields[9] as String?,
      oversBowled: fields[10] as int,
      runsConceded: fields[11] as int,
      wicketsTaken: fields[12] as int,
      widesBowled: fields[13] as int,
      noballsBowled: fields[14] as int,
      isCurrentlyBatting: fields[15] as bool,
      isCurrentlyBowling: fields[16] as bool,
      battingPosition: fields[17] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.teamId)
      ..writeByte(3)
      ..write(obj.runsScored)
      ..writeByte(4)
      ..write(obj.ballsFaced)
      ..writeByte(5)
      ..write(obj.isOut)
      ..writeByte(6)
      ..write(obj.isRetired)
      ..writeByte(7)
      ..write(obj.isRetiredHurt)
      ..writeByte(8)
      ..write(obj.wicketType)
      ..writeByte(9)
      ..write(obj.dismissedBy)
      ..writeByte(10)
      ..write(obj.oversBowled)
      ..writeByte(11)
      ..write(obj.runsConceded)
      ..writeByte(12)
      ..write(obj.wicketsTaken)
      ..writeByte(13)
      ..write(obj.widesBowled)
      ..writeByte(14)
      ..write(obj.noballsBowled)
      ..writeByte(15)
      ..write(obj.isCurrentlyBatting)
      ..writeByte(16)
      ..write(obj.isCurrentlyBowling)
      ..writeByte(17)
      ..write(obj.battingPosition);
  }
}
