import 'package:hive/hive.dart';

import 'ball_model.dart';
import 'over_model.dart';
import 'partnership_model.dart';

part 'innings_model.g.dart';

@HiveType(typeId: 5)
class Innings extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String battingTeamId;
  @HiveField(2)
  final String bowlingTeamId;
  @HiveField(3)
  final int totalRuns;
  @HiveField(4)
  final int wickets;
  @HiveField(5)
  final List<Over> overs;
  @HiveField(6)
  final List<Partnership> partnerships;
  @HiveField(7)
  final String? currentBatsmanId;
  @HiveField(8)
  final String? currentNonStrikerId;
  @HiveField(9)
  final String? currentBowlerId;
  @HiveField(10)
  final bool isCompleted;
  @HiveField(11)
  final int inningsNumber;

  Innings({
    required this.id,
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.totalRuns = 0,
    this.wickets = 0,
    this.overs = const [],
    this.partnerships = const [],
    this.currentBatsmanId,
    this.currentNonStrikerId,
    this.currentBowlerId,
    this.isCompleted = false,
    required this.inningsNumber,
  });

  List<Ball> get allBalls => overs.expand((over) => over.balls).toList();
  String get score => '$totalRuns/$wickets';

  int legalBallsCount() => allBalls.where((ball) => ball.isLegalBall).length;

  double completedOvers(int ballsPerOver) {
    if (ballsPerOver <= 0) return 0;
    return legalBallsCount() / ballsPerOver;
  }

  int get extras => allBalls.fold(0, (sum, ball) {
    final ballExtras = (ball.isWide || ball.isNoBall)
        ? 1 + ball.runsScored
        : ((ball.isBye || ball.isLegBye) ? ball.runsScored : 0);
    return sum + ballExtras;
  });

  Innings copyWith({
    String? id,
    String? battingTeamId,
    String? bowlingTeamId,
    int? totalRuns,
    int? wickets,
    List<Over>? overs,
    List<Partnership>? partnerships,
    String? currentBatsmanId,
    String? currentNonStrikerId,
    String? currentBowlerId,
    bool? isCompleted,
    int? inningsNumber,
  }) {
    return Innings(
      id: id ?? this.id,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      totalRuns: totalRuns ?? this.totalRuns,
      wickets: wickets ?? this.wickets,
      overs: overs ?? this.overs,
      partnerships: partnerships ?? this.partnerships,
      currentBatsmanId: currentBatsmanId ?? this.currentBatsmanId,
      currentNonStrikerId: currentNonStrikerId ?? this.currentNonStrikerId,
      currentBowlerId: currentBowlerId ?? this.currentBowlerId,
      isCompleted: isCompleted ?? this.isCompleted,
      inningsNumber: inningsNumber ?? this.inningsNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'battingTeamId': battingTeamId,
      'bowlingTeamId': bowlingTeamId,
      'totalRuns': totalRuns,
      'wickets': wickets,
      'overs': overs.map((over) => over.toJson()).toList(),
      'partnerships': partnerships.map((partnership) => partnership.toJson()).toList(),
      'currentBatsmanId': currentBatsmanId,
      'currentNonStrikerId': currentNonStrikerId,
      'currentBowlerId': currentBowlerId,
      'isCompleted': isCompleted,
      'inningsNumber': inningsNumber,
    };
  }

  factory Innings.fromJson(Map<String, dynamic> json) {
    return Innings(
      id: json['id'] as String? ?? '',
      battingTeamId: json['battingTeamId'] as String? ?? '',
      bowlingTeamId: json['bowlingTeamId'] as String? ?? '',
      totalRuns: json['totalRuns'] as int? ?? 0,
      wickets: json['wickets'] as int? ?? 0,
      overs: (json['overs'] as List<dynamic>? ?? [])
          .map((over) => Over.fromJson(Map<String, dynamic>.from(over as Map)))
          .toList(),
      partnerships: (json['partnerships'] as List<dynamic>? ?? [])
          .map(
            (partnership) => Partnership.fromJson(
              Map<String, dynamic>.from(partnership as Map),
            ),
          )
          .toList(),
      currentBatsmanId: json['currentBatsmanId'] as String?,
      currentNonStrikerId: json['currentNonStrikerId'] as String?,
      currentBowlerId: json['currentBowlerId'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      inningsNumber: json['inningsNumber'] as int? ?? 1,
    );
  }
}
