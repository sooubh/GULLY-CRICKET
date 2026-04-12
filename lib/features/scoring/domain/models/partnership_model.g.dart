part of 'partnership_model.dart';

class PartnershipAdapter extends TypeAdapter<Partnership> {
  @override
  final int typeId = 4;

  @override
  Partnership read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Partnership(
      batsmanAId: fields[0] as String,
      batsmanBId: fields[1] as String,
      runs: fields[2] as int,
      balls: fields[3] as int,
      forWicket: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Partnership obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.batsmanAId)
      ..writeByte(1)
      ..write(obj.batsmanBId)
      ..writeByte(2)
      ..write(obj.runs)
      ..writeByte(3)
      ..write(obj.balls)
      ..writeByte(4)
      ..write(obj.forWicket);
  }
}
