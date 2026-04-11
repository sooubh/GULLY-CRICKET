import 'package:hive/hive.dart';

part 'player_model.g.dart';

@HiveType(typeId: 1)
class Player extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String teamId;
  @HiveField(3)
  final int runsScored;
  @HiveField(4)
  final int ballsFaced;
  @HiveField(5)
  final bool isOut;
  @HiveField(6)
  final bool isRetired;
  @HiveField(7)
  final bool isRetiredHurt;
  @HiveField(8)
  final String? wicketType;
  @HiveField(9)
  final String? dismissedBy;
  @HiveField(10)
  final int oversBowled;
  @HiveField(11)
  final int runsConceded;
  @HiveField(12)
  final int wicketsTaken;
  @HiveField(13)
  final int widesBowled;
  @HiveField(14)
  final int noballsBowled;
  @HiveField(15)
  final bool isCurrentlyBatting;
  @HiveField(16)
  final bool isCurrentlyBowling;
  @HiveField(17)
  final int battingPosition;

  Player({
    required this.id,
    required this.name,
    required this.teamId,
    this.runsScored = 0,
    this.ballsFaced = 0,
    this.isOut = false,
    this.isRetired = false,
    this.isRetiredHurt = false,
    this.wicketType,
    this.dismissedBy,
    this.oversBowled = 0,
    this.runsConceded = 0,
    this.wicketsTaken = 0,
    this.widesBowled = 0,
    this.noballsBowled = 0,
    this.isCurrentlyBatting = false,
    this.isCurrentlyBowling = false,
    this.battingPosition = 0,
  });

  double get strikeRate => ballsFaced == 0 ? 0 : (runsScored / ballsFaced) * 100;
  double get economy => oversBowled == 0 ? 0 : runsConceded / oversBowled;
  String get bowlingFigures => '$wicketsTaken/$runsConceded';

  Player copyWith({
    String? id,
    String? name,
    String? teamId,
    int? runsScored,
    int? ballsFaced,
    bool? isOut,
    bool? isRetired,
    bool? isRetiredHurt,
    String? wicketType,
    String? dismissedBy,
    int? oversBowled,
    int? runsConceded,
    int? wicketsTaken,
    int? widesBowled,
    int? noballsBowled,
    bool? isCurrentlyBatting,
    bool? isCurrentlyBowling,
    int? battingPosition,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      runsScored: runsScored ?? this.runsScored,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      isOut: isOut ?? this.isOut,
      isRetired: isRetired ?? this.isRetired,
      isRetiredHurt: isRetiredHurt ?? this.isRetiredHurt,
      wicketType: wicketType ?? this.wicketType,
      dismissedBy: dismissedBy ?? this.dismissedBy,
      oversBowled: oversBowled ?? this.oversBowled,
      runsConceded: runsConceded ?? this.runsConceded,
      wicketsTaken: wicketsTaken ?? this.wicketsTaken,
      widesBowled: widesBowled ?? this.widesBowled,
      noballsBowled: noballsBowled ?? this.noballsBowled,
      isCurrentlyBatting: isCurrentlyBatting ?? this.isCurrentlyBatting,
      isCurrentlyBowling: isCurrentlyBowling ?? this.isCurrentlyBowling,
      battingPosition: battingPosition ?? this.battingPosition,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teamId': teamId,
      'runsScored': runsScored,
      'ballsFaced': ballsFaced,
      'isOut': isOut,
      'isRetired': isRetired,
      'isRetiredHurt': isRetiredHurt,
      'wicketType': wicketType,
      'dismissedBy': dismissedBy,
      'oversBowled': oversBowled,
      'runsConceded': runsConceded,
      'wicketsTaken': wicketsTaken,
      'widesBowled': widesBowled,
      'noballsBowled': noballsBowled,
      'isCurrentlyBatting': isCurrentlyBatting,
      'isCurrentlyBowling': isCurrentlyBowling,
      'battingPosition': battingPosition,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      runsScored: json['runsScored'] as int? ?? 0,
      ballsFaced: json['ballsFaced'] as int? ?? 0,
      isOut: json['isOut'] as bool? ?? false,
      isRetired: json['isRetired'] as bool? ?? false,
      isRetiredHurt: json['isRetiredHurt'] as bool? ?? false,
      wicketType: json['wicketType'] as String?,
      dismissedBy: json['dismissedBy'] as String?,
      oversBowled: json['oversBowled'] as int? ?? 0,
      runsConceded: json['runsConceded'] as int? ?? 0,
      wicketsTaken: json['wicketsTaken'] as int? ?? 0,
      widesBowled: json['widesBowled'] as int? ?? 0,
      noballsBowled: json['noballsBowled'] as int? ?? 0,
      isCurrentlyBatting: json['isCurrentlyBatting'] as bool? ?? false,
      isCurrentlyBowling: json['isCurrentlyBowling'] as bool? ?? false,
      battingPosition: json['battingPosition'] as int? ?? 0,
    );
  }
}
