import 'package:hive/hive.dart';

import 'ball_model.dart';

part 'over_model.g.dart';

@HiveType(typeId: 3)
class Over extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final int overNumber;
  @HiveField(2)
  final String bowlerId;
  @HiveField(3)
  final List<Ball> balls;
  @HiveField(4)
  final int runsInOver;
  @HiveField(5)
  final int wicketsInOver;

  Over({
    required this.id,
    required this.overNumber,
    required this.bowlerId,
    this.balls = const [],
    this.runsInOver = 0,
    this.wicketsInOver = 0,
  });

  int get legalBallCount => balls.where((ball) => ball.isLegalBall).length;
  bool get isMaiden => runsInOver == 0;
  bool isComplete(int ballsPerOver) => legalBallCount >= ballsPerOver;

  Over copyWith({
    String? id,
    int? overNumber,
    String? bowlerId,
    List<Ball>? balls,
    int? runsInOver,
    int? wicketsInOver,
  }) {
    return Over(
      id: id ?? this.id,
      overNumber: overNumber ?? this.overNumber,
      bowlerId: bowlerId ?? this.bowlerId,
      balls: balls ?? this.balls,
      runsInOver: runsInOver ?? this.runsInOver,
      wicketsInOver: wicketsInOver ?? this.wicketsInOver,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'overNumber': overNumber,
      'bowlerId': bowlerId,
      'balls': balls.map((ball) => ball.toJson()).toList(),
      'runsInOver': runsInOver,
      'wicketsInOver': wicketsInOver,
    };
  }

  factory Over.fromJson(Map<String, dynamic> json) {
    return Over(
      id: json['id'] as String? ?? '',
      overNumber: json['overNumber'] as int? ?? 0,
      bowlerId: json['bowlerId'] as String? ?? '',
      balls: (json['balls'] as List<dynamic>? ?? [])
          .map((ball) => Ball.fromJson(Map<String, dynamic>.from(ball as Map)))
          .toList(),
      runsInOver: json['runsInOver'] as int? ?? 0,
      wicketsInOver: json['wicketsInOver'] as int? ?? 0,
    );
  }
}
