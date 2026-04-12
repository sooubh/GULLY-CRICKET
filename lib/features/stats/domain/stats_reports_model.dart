class LeaderStat {
  const LeaderStat({
    required this.playerName,
    required this.value,
  });

  final String playerName;
  final int value;
}

class BowlingLeaderStat {
  const BowlingLeaderStat({
    required this.playerName,
    required this.wickets,
    required this.runs,
  });

  final String playerName;
  final int wickets;
  final int runs;

  String get figures => '$wickets/$runs';
}

class PartnershipRecord {
  const PartnershipRecord({
    required this.batters,
    required this.runs,
    required this.balls,
    required this.forWicket,
    required this.inningsNumber,
  });

  final String batters;
  final int runs;
  final int balls;
  final int forWicket;
  final int inningsNumber;
}

class OverRunRatePoint {
  const OverRunRatePoint({
    required this.inningsNumber,
    required this.overNumber,
    required this.runs,
    required this.runRate,
  });

  final int inningsNumber;
  final int overNumber;
  final int runs;
  final double runRate;
}

class MatchStatsReport {
  const MatchStatsReport({
    this.topScorer,
    this.bestBowler,
    this.mostDotBalls,
    this.mostBoundaries,
    this.partnerships = const <PartnershipRecord>[],
    this.highestOver,
    this.runRateChart = const <OverRunRatePoint>[],
  });

  final LeaderStat? topScorer;
  final BowlingLeaderStat? bestBowler;
  final LeaderStat? mostDotBalls;
  final LeaderStat? mostBoundaries;
  final List<PartnershipRecord> partnerships;
  final String? highestOver;
  final List<OverRunRatePoint> runRateChart;
}

class HeadToHead {
  const HeadToHead({
    required this.team1,
    required this.team2,
    this.matches = 0,
    this.team1Wins = 0,
    this.team2Wins = 0,
    this.ties = 0,
    this.highestTeamTotal = 0,
    this.lowestTeamTotal = 0,
    this.averageFirstInningsScore = 0,
    this.averageSecondInningsScore = 0,
  });

  final String team1;
  final String team2;
  final int matches;
  final int team1Wins;
  final int team2Wins;
  final int ties;
  final int highestTeamTotal;
  final int lowestTeamTotal;
  final double averageFirstInningsScore;
  final double averageSecondInningsScore;
}
