part of 'ball_model.dart';

class BallAdapter extends TypeAdapter<Ball> {
  @override
  final int typeId = 2;

  @override
  Ball read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ball(
      id: fields[0] as String,
      runsScored: fields[1] as int,
      isWicket: fields[2] as bool,
      isWide: fields[3] as bool,
      isNoBall: fields[4] as bool,
      isBye: fields[5] as bool,
      isLegBye: fields[6] as bool,
      isFreeHit: fields[7] as bool,
      isOverthrow: fields[8] as bool,
      wicketType: fields[9] as String?,
      dismissedPlayerId: fields[10] as String?,
      bowlerId: fields[11] as String,
      batsmanId: fields[12] as String,
      overNumber: fields[13] as int,
      ballInOver: fields[14] as int,
      totalRunsAfterBall: fields[15] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Ball obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.runsScored)
      ..writeByte(2)
      ..write(obj.isWicket)
      ..writeByte(3)
      ..write(obj.isWide)
      ..writeByte(4)
      ..write(obj.isNoBall)
      ..writeByte(5)
      ..write(obj.isBye)
      ..writeByte(6)
      ..write(obj.isLegBye)
      ..writeByte(7)
      ..write(obj.isFreeHit)
      ..writeByte(8)
      ..write(obj.isOverthrow)
      ..writeByte(9)
      ..write(obj.wicketType)
      ..writeByte(10)
      ..write(obj.dismissedPlayerId)
      ..writeByte(11)
      ..write(obj.bowlerId)
      ..writeByte(12)
      ..write(obj.batsmanId)
      ..writeByte(13)
      ..write(obj.overNumber)
      ..writeByte(14)
      ..write(obj.ballInOver)
      ..writeByte(15)
      ..write(obj.totalRunsAfterBall);
  }
}
