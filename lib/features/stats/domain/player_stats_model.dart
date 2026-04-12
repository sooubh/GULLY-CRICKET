class PlayerStats {
  const PlayerStats({
    required this.playerName,
    this.matches = 0,
    this.innings = 0,
    this.totalRuns = 0,
    this.ballsFaced = 0,
    this.notOuts = 0,
    this.highScore = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.fours = 0,
    this.sixes = 0,
    this.ducks = 0,
    this.timesRetired = 0,
    this.ballsBowled = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.maidens = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.bestWickets = 0,
    this.bestRuns = 0,
    this.fiveWicketHauls = 0,
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
    this.wins = 0,
    this.losses = 0,
    this.ties = 0,
    this.lastFiveScores = const <int>[],
  });

  final String playerName;

  // ── Batting ──
  final int matches;
  final int innings;
  final int totalRuns;
  final int ballsFaced;
  final int notOuts;
  final int highScore;
  final int fifties;
  final int hundreds;
  final int fours;
  final int sixes;
  final int ducks;
  final int timesRetired;

  // Computed batting
  double get battingAverage {
    final outs = innings - notOuts;
    return outs == 0 ? totalRuns.toDouble() : totalRuns / outs;
  }

  double get strikeRate => ballsFaced == 0 ? 0 : (totalRuns / ballsFaced) * 100;

  double get runsPerMatch => matches == 0 ? 0 : totalRuns / matches;

  // ── Bowling ──
  final int ballsBowled;
  final int runsConceded;
  final int wickets;
  final int maidens;
  final int wides;
  final int noBalls;
  final int bestWickets;
  final int bestRuns;
  final int fiveWicketHauls;

  // Computed bowling
  double get economy => ballsBowled == 0 ? 0 : (runsConceded / ballsBowled) * 6;

  double get bowlingAverage => wickets == 0 ? 0 : runsConceded / wickets;

  double get strikeRateBowling => wickets == 0 ? 0 : ballsBowled / wickets;

  String get bestBowling => '$bestWickets/$bestRuns';

  // ── Fielding ──
  final int catches;
  final int runOuts;
  final int stumpings;

  // ── Match results ──
  final int wins;
  final int losses;
  final int ties;

  double get winPercentage => matches == 0 ? 0 : (wins / matches) * 100;

  // ── Form (last 5 scores) ──
  final List<int> lastFiveScores;

  String get formString => lastFiveScores.map((score) => score.toString()).join(' ');
}
