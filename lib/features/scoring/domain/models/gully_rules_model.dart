import 'package:hive/hive.dart';

part 'gully_rules_model.g.dart';

@HiveType(typeId: 0)
class GullyRules extends HiveObject {
  @HiveField(0)
  final bool halfCenturyRetire;
  @HiveField(1)
  final bool centuryRetire;
  @HiveField(2)
  final bool lastManBatsAlone;
  @HiveField(3)
  final bool runnerAllowed;
  @HiveField(4)
  final bool reEntryAllowed;
  @HiveField(5)
  final bool tipOneHandOut;
  @HiveField(6)
  final bool wallCatchOut;
  @HiveField(7)
  final bool oneBounceCatchOut;
  @HiveField(8)
  final bool sixIsOut;
  @HiveField(9)
  final bool noballFreeHit;
  @HiveField(10)
  final bool lbwAllowed;
  @HiveField(11)
  final bool byesAllowed;
  @HiveField(12)
  final bool legByesAllowed;
  @HiveField(13)
  final bool overthrowsAllowed;
  @HiveField(14)
  final int maxOversPerBowler;
  @HiveField(15)
  final int ballsPerOver;
  @HiveField(16)
  final int totalOvers;
  @HiveField(17)
  final int team1Players;
  @HiveField(18)
  final int team2Players;

  GullyRules({
    this.halfCenturyRetire = true,
    this.centuryRetire = false,
    this.lastManBatsAlone = true,
    this.runnerAllowed = false,
    this.reEntryAllowed = false,
    this.tipOneHandOut = true,
    this.wallCatchOut = false,
    this.oneBounceCatchOut = false,
    this.sixIsOut = false,
    this.noballFreeHit = true,
    this.lbwAllowed = false,
    this.byesAllowed = true,
    this.legByesAllowed = false,
    this.overthrowsAllowed = true,
    this.maxOversPerBowler = 0,
    this.ballsPerOver = 6,
    this.totalOvers = 5,
    this.team1Players = 6,
    this.team2Players = 6,
  });

  int get maxPlayers => team1Players > team2Players ? team1Players : team2Players;

  GullyRules copyWith({
    bool? halfCenturyRetire,
    bool? centuryRetire,
    bool? lastManBatsAlone,
    bool? runnerAllowed,
    bool? reEntryAllowed,
    bool? tipOneHandOut,
    bool? wallCatchOut,
    bool? oneBounceCatchOut,
    bool? sixIsOut,
    bool? noballFreeHit,
    bool? lbwAllowed,
    bool? byesAllowed,
    bool? legByesAllowed,
    bool? overthrowsAllowed,
    int? maxOversPerBowler,
    int? ballsPerOver,
    int? totalOvers,
    int? team1Players,
    int? team2Players,
  }) {
    return GullyRules(
      halfCenturyRetire: halfCenturyRetire ?? this.halfCenturyRetire,
      centuryRetire: centuryRetire ?? this.centuryRetire,
      lastManBatsAlone: lastManBatsAlone ?? this.lastManBatsAlone,
      runnerAllowed: runnerAllowed ?? this.runnerAllowed,
      reEntryAllowed: reEntryAllowed ?? this.reEntryAllowed,
      tipOneHandOut: tipOneHandOut ?? this.tipOneHandOut,
      wallCatchOut: wallCatchOut ?? this.wallCatchOut,
      oneBounceCatchOut: oneBounceCatchOut ?? this.oneBounceCatchOut,
      sixIsOut: sixIsOut ?? this.sixIsOut,
      noballFreeHit: noballFreeHit ?? this.noballFreeHit,
      lbwAllowed: lbwAllowed ?? this.lbwAllowed,
      byesAllowed: byesAllowed ?? this.byesAllowed,
      legByesAllowed: legByesAllowed ?? this.legByesAllowed,
      overthrowsAllowed: overthrowsAllowed ?? this.overthrowsAllowed,
      maxOversPerBowler: maxOversPerBowler ?? this.maxOversPerBowler,
      ballsPerOver: ballsPerOver ?? this.ballsPerOver,
      totalOvers: totalOvers ?? this.totalOvers,
      team1Players: team1Players ?? this.team1Players,
      team2Players: team2Players ?? this.team2Players,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'halfCenturyRetire': halfCenturyRetire,
      'centuryRetire': centuryRetire,
      'lastManBatsAlone': lastManBatsAlone,
      'runnerAllowed': runnerAllowed,
      'reEntryAllowed': reEntryAllowed,
      'tipOneHandOut': tipOneHandOut,
      'wallCatchOut': wallCatchOut,
      'oneBounceCatchOut': oneBounceCatchOut,
      'sixIsOut': sixIsOut,
      'noballFreeHit': noballFreeHit,
      'lbwAllowed': lbwAllowed,
      'byesAllowed': byesAllowed,
      'legByesAllowed': legByesAllowed,
      'overthrowsAllowed': overthrowsAllowed,
      'maxOversPerBowler': maxOversPerBowler,
      'ballsPerOver': ballsPerOver,
      'totalOvers': totalOvers,
      'team1Players': team1Players,
      'team2Players': team2Players,
      'totalPlayers': maxPlayers,
    };
  }

  factory GullyRules.fromJson(Map<String, dynamic> json) {
    return GullyRules(
      halfCenturyRetire: json['halfCenturyRetire'] as bool? ?? true,
      centuryRetire: json['centuryRetire'] as bool? ?? false,
      lastManBatsAlone: json['lastManBatsAlone'] as bool? ?? true,
      runnerAllowed: json['runnerAllowed'] as bool? ?? false,
      reEntryAllowed: json['reEntryAllowed'] as bool? ?? false,
      tipOneHandOut: json['tipOneHandOut'] as bool? ?? true,
      wallCatchOut: json['wallCatchOut'] as bool? ?? false,
      oneBounceCatchOut: json['oneBounceCatchOut'] as bool? ?? false,
      sixIsOut: json['sixIsOut'] as bool? ?? false,
      noballFreeHit: json['noballFreeHit'] as bool? ?? true,
      lbwAllowed: json['lbwAllowed'] as bool? ?? false,
      byesAllowed: json['byesAllowed'] as bool? ?? true,
      legByesAllowed: json['legByesAllowed'] as bool? ?? false,
      overthrowsAllowed: json['overthrowsAllowed'] as bool? ?? true,
      maxOversPerBowler: json['maxOversPerBowler'] as int? ?? 0,
      ballsPerOver: json['ballsPerOver'] as int? ?? 6,
      totalOvers: json['totalOvers'] as int? ?? 5,
      team1Players: json['team1Players'] as int? ?? json['totalPlayers'] as int? ?? 6,
      team2Players: json['team2Players'] as int? ?? json['totalPlayers'] as int? ?? 6,
    );
  }
}
