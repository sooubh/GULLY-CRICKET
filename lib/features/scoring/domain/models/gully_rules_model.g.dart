part of 'gully_rules_model.dart';

class GullyRulesAdapter extends TypeAdapter<GullyRules> {
  @override
  final int typeId = 0;

  @override
  GullyRules read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GullyRules(
      halfCenturyRetire: fields[0] as bool,
      centuryRetire: fields[1] as bool,
      lastManBatsAlone: fields[2] as bool,
      runnerAllowed: fields[3] as bool,
      reEntryAllowed: fields[4] as bool,
      tipOneHandOut: fields[5] as bool,
      wallCatchOut: fields[6] as bool,
      oneBounceCatchOut: fields[7] as bool,
      sixIsOut: fields[8] as bool,
      noballFreeHit: fields[9] as bool,
      lbwAllowed: fields[10] as bool,
      byesAllowed: fields[11] as bool,
      legByesAllowed: fields[12] as bool,
      overthrowsAllowed: fields[13] as bool,
      maxOversPerBowler: fields[14] as int,
      ballsPerOver: fields[15] as int,
      totalOvers: fields[16] as int,
      totalPlayers: fields[17] as int,
    );
  }

  @override
  void write(BinaryWriter writer, GullyRules obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.halfCenturyRetire)
      ..writeByte(1)
      ..write(obj.centuryRetire)
      ..writeByte(2)
      ..write(obj.lastManBatsAlone)
      ..writeByte(3)
      ..write(obj.runnerAllowed)
      ..writeByte(4)
      ..write(obj.reEntryAllowed)
      ..writeByte(5)
      ..write(obj.tipOneHandOut)
      ..writeByte(6)
      ..write(obj.wallCatchOut)
      ..writeByte(7)
      ..write(obj.oneBounceCatchOut)
      ..writeByte(8)
      ..write(obj.sixIsOut)
      ..writeByte(9)
      ..write(obj.noballFreeHit)
      ..writeByte(10)
      ..write(obj.lbwAllowed)
      ..writeByte(11)
      ..write(obj.byesAllowed)
      ..writeByte(12)
      ..write(obj.legByesAllowed)
      ..writeByte(13)
      ..write(obj.overthrowsAllowed)
      ..writeByte(14)
      ..write(obj.maxOversPerBowler)
      ..writeByte(15)
      ..write(obj.ballsPerOver)
      ..writeByte(16)
      ..write(obj.totalOvers)
      ..writeByte(17)
      ..write(obj.totalPlayers);
  }
}
