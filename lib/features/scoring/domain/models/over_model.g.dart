part of 'over_model.dart';

class OverAdapter extends TypeAdapter<Over> {
  @override
  final int typeId = 3;

  @override
  Over read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Over(
      id: fields[0] as String,
      overNumber: fields[1] as int,
      bowlerId: fields[2] as String,
      balls: (fields[3] as List).cast<Ball>(),
      runsInOver: fields[4] as int,
      wicketsInOver: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Over obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.overNumber)
      ..writeByte(2)
      ..write(obj.bowlerId)
      ..writeByte(3)
      ..write(obj.balls)
      ..writeByte(4)
      ..write(obj.runsInOver)
      ..writeByte(5)
      ..write(obj.wicketsInOver);
  }
}
