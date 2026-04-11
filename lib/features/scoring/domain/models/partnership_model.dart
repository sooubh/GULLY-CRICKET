import 'package:hive/hive.dart';

part 'partnership_model.g.dart';

@HiveType(typeId: 4)
class Partnership extends HiveObject {
  @HiveField(0)
  final String batsmanAId;
  @HiveField(1)
  final String batsmanBId;
  @HiveField(2)
  final int runs;
  @HiveField(3)
  final int balls;
  @HiveField(4)
  final int forWicket;

  Partnership({
    required this.batsmanAId,
    required this.batsmanBId,
    this.runs = 0,
    this.balls = 0,
    required this.forWicket,
  });

  Partnership copyWith({
    String? batsmanAId,
    String? batsmanBId,
    int? runs,
    int? balls,
    int? forWicket,
  }) {
    return Partnership(
      batsmanAId: batsmanAId ?? this.batsmanAId,
      batsmanBId: batsmanBId ?? this.batsmanBId,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      forWicket: forWicket ?? this.forWicket,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batsmanAId': batsmanAId,
      'batsmanBId': batsmanBId,
      'runs': runs,
      'balls': balls,
      'forWicket': forWicket,
    };
  }

  factory Partnership.fromJson(Map<String, dynamic> json) {
    return Partnership(
      batsmanAId: json['batsmanAId'] as String? ?? '',
      batsmanBId: json['batsmanBId'] as String? ?? '',
      runs: json['runs'] as int? ?? 0,
      balls: json['balls'] as int? ?? 0,
      forWicket: json['forWicket'] as int? ?? 0,
    );
  }
}
