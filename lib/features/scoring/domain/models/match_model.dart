import 'package:hive/hive.dart';

import 'gully_rules_model.dart';
import 'innings_model.dart';
import 'player_model.dart';

part 'match_model.g.dart';

@HiveType(typeId: 6)
class MatchModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String team1Name;
  @HiveField(2)
  final String team2Name;
  @HiveField(3)
  final List<Player> team1Players;
  @HiveField(4)
  final List<Player> team2Players;
  @HiveField(5)
  final GullyRules rules;
  @HiveField(6)
  final Innings? firstInnings;
  @HiveField(7)
  final Innings? secondInnings;
  @HiveField(8)
  final String? winnerTeamName;
  @HiveField(9)
  final String? winDescription;
  @HiveField(10)
  final int status;
  @HiveField(11)
  final DateTime createdAt;
  @HiveField(12)
  final DateTime? completedAt;
  @HiveField(13)
  final String? tossWinnerTeamName;
  @HiveField(14)
  final String? tossDecision;
  @HiveField(15)
  final String battingFirstTeamId;

  MatchModel({
    required this.id,
    required this.team1Name,
    required this.team2Name,
    this.team1Players = const [],
    this.team2Players = const [],
    GullyRules? rules,
    this.firstInnings,
    this.secondInnings,
    this.winnerTeamName,
    this.winDescription,
    this.status = 0,
    DateTime? createdAt,
    this.completedAt,
    this.tossWinnerTeamName,
    this.tossDecision,
    this.battingFirstTeamId = 'team1',
  }) : rules = rules ?? GullyRules(),
       createdAt = createdAt ?? DateTime.now();

  Innings? get currentInnings => secondInnings ?? firstInnings;
  bool get isFirstInnings => secondInnings == null;
  int? get target => firstInnings == null ? null : firstInnings!.totalRuns + 1;

  List<Player> get battingTeamPlayers =>
      battingFirstTeamId == 'team1' ? team1Players : team2Players;
  List<Player> get bowlingTeamPlayers =>
      battingFirstTeamId == 'team1' ? team2Players : team1Players;

  MatchModel copyWith({
    String? id,
    String? team1Name,
    String? team2Name,
    List<Player>? team1Players,
    List<Player>? team2Players,
    GullyRules? rules,
    Innings? firstInnings,
    Innings? secondInnings,
    String? winnerTeamName,
    String? winDescription,
    int? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? tossWinnerTeamName,
    String? tossDecision,
    String? battingFirstTeamId,
  }) {
    return MatchModel(
      id: id ?? this.id,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Players: team1Players ?? this.team1Players,
      team2Players: team2Players ?? this.team2Players,
      rules: rules ?? this.rules,
      firstInnings: firstInnings ?? this.firstInnings,
      secondInnings: secondInnings ?? this.secondInnings,
      winnerTeamName: winnerTeamName ?? this.winnerTeamName,
      winDescription: winDescription ?? this.winDescription,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      tossWinnerTeamName: tossWinnerTeamName ?? this.tossWinnerTeamName,
      tossDecision: tossDecision ?? this.tossDecision,
      battingFirstTeamId: battingFirstTeamId ?? this.battingFirstTeamId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team1Name': team1Name,
      'team2Name': team2Name,
      'team1Players': team1Players.map((player) => player.toJson()).toList(),
      'team2Players': team2Players.map((player) => player.toJson()).toList(),
      'rules': rules.toJson(),
      'firstInnings': firstInnings?.toJson(),
      'secondInnings': secondInnings?.toJson(),
      'winnerTeamName': winnerTeamName,
      'winDescription': winDescription,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'tossWinnerTeamName': tossWinnerTeamName,
      'tossDecision': tossDecision,
      'battingFirstTeamId': battingFirstTeamId,
    };
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String? ?? '',
      team1Name: json['team1Name'] as String? ?? '',
      team2Name: json['team2Name'] as String? ?? '',
      team1Players: (json['team1Players'] as List<dynamic>? ?? [])
          .map((player) => Player.fromJson(Map<String, dynamic>.from(player as Map)))
          .toList(),
      team2Players: (json['team2Players'] as List<dynamic>? ?? [])
          .map((player) => Player.fromJson(Map<String, dynamic>.from(player as Map)))
          .toList(),
      rules: json['rules'] == null
          ? GullyRules()
          : GullyRules.fromJson(Map<String, dynamic>.from(json['rules'] as Map)),
      firstInnings: json['firstInnings'] == null
          ? null
          : Innings.fromJson(Map<String, dynamic>.from(json['firstInnings'] as Map)),
      secondInnings: json['secondInnings'] == null
          ? null
          : Innings.fromJson(Map<String, dynamic>.from(json['secondInnings'] as Map)),
      winnerTeamName: json['winnerTeamName'] as String?,
      winDescription: json['winDescription'] as String?,
      status: json['status'] as int? ?? 0,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
      completedAt:
          json['completedAt'] == null ? null : DateTime.parse(json['completedAt'] as String),
      tossWinnerTeamName: json['tossWinnerTeamName'] as String?,
      tossDecision: json['tossDecision'] as String?,
      battingFirstTeamId: json['battingFirstTeamId'] as String? ?? 'team1',
    );
  }
}
