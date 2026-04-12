class MatchConfig {
  const MatchConfig({
    this.team1Name = 'Team A',
    this.team2Name = 'Team B',
    this.totalOvers = 5,
    this.ballsPerOver = 6,
    this.team1PlayerCount = 6,
    this.team2PlayerCount = 6,
    this.enableToss = false,
    this.team1Players = const <String>[],
    this.team2Players = const <String>[],
    this.halfCenturyRetire = true,
    this.centuryRetire = false,
    this.lastManBatsAlone = true,
    this.reEntryAllowed = false,
    this.tipOneHandOut = true,
    this.wallCatchOut = false,
    this.oneBounceCatchOut = false,
    this.noballFreeHit = true,
    this.lbwAllowed = false,
    this.maxOversPerBowler = 0,
    this.sixIsOut = false,
    this.enableMultiplayer = false,
  });

  final String team1Name;
  final String team2Name;
  final int totalOvers;
  final int ballsPerOver;
  final int team1PlayerCount;
  final int team2PlayerCount;
  final bool enableToss;
  final List<String> team1Players;
  final List<String> team2Players;

  final bool halfCenturyRetire;
  final bool centuryRetire;
  final bool lastManBatsAlone;
  final bool reEntryAllowed;
  final bool tipOneHandOut;
  final bool wallCatchOut;
  final bool oneBounceCatchOut;
  final bool noballFreeHit;
  final bool lbwAllowed;
  final int maxOversPerBowler;
  final bool sixIsOut;
  final bool enableMultiplayer;

  MatchConfig copyWith({
    String? team1Name,
    String? team2Name,
    int? totalOvers,
    int? ballsPerOver,
    int? team1PlayerCount,
    int? team2PlayerCount,
    bool? enableToss,
    List<String>? team1Players,
    List<String>? team2Players,
    bool? halfCenturyRetire,
    bool? centuryRetire,
    bool? lastManBatsAlone,
    bool? reEntryAllowed,
    bool? tipOneHandOut,
    bool? wallCatchOut,
    bool? oneBounceCatchOut,
    bool? noballFreeHit,
    bool? lbwAllowed,
    int? maxOversPerBowler,
    bool? sixIsOut,
    bool? enableMultiplayer,
  }) {
    return MatchConfig(
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      totalOvers: totalOvers ?? this.totalOvers,
      ballsPerOver: ballsPerOver ?? this.ballsPerOver,
      team1PlayerCount: team1PlayerCount ?? this.team1PlayerCount,
      team2PlayerCount: team2PlayerCount ?? this.team2PlayerCount,
      enableToss: enableToss ?? this.enableToss,
      team1Players: team1Players ?? this.team1Players,
      team2Players: team2Players ?? this.team2Players,
      halfCenturyRetire: halfCenturyRetire ?? this.halfCenturyRetire,
      centuryRetire: centuryRetire ?? this.centuryRetire,
      lastManBatsAlone: lastManBatsAlone ?? this.lastManBatsAlone,
      reEntryAllowed: reEntryAllowed ?? this.reEntryAllowed,
      tipOneHandOut: tipOneHandOut ?? this.tipOneHandOut,
      wallCatchOut: wallCatchOut ?? this.wallCatchOut,
      oneBounceCatchOut: oneBounceCatchOut ?? this.oneBounceCatchOut,
      noballFreeHit: noballFreeHit ?? this.noballFreeHit,
      lbwAllowed: lbwAllowed ?? this.lbwAllowed,
      maxOversPerBowler: maxOversPerBowler ?? this.maxOversPerBowler,
      sixIsOut: sixIsOut ?? this.sixIsOut,
      enableMultiplayer: enableMultiplayer ?? this.enableMultiplayer,
    );
  }
}
