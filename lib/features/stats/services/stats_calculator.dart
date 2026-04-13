import '../../../core/constants/match_status.dart';
import '../../scoring/domain/models/ball_model.dart';
import '../../scoring/domain/models/innings_model.dart';
import '../../scoring/domain/models/match_model.dart';
import '../../scoring/domain/models/over_model.dart';
import '../../scoring/domain/models/player_model.dart';
import '../domain/player_stats_model.dart';
import '../domain/stats_reports_model.dart';

class StatsCalculator {
  const StatsCalculator();

  // Compute full PlayerStats for a player name from all completed matches.
  PlayerStats calculateForPlayer(String playerName, List<MatchModel> allMatches) {
    final completedMatches = _completedMatches(allMatches);

    var matches = 0;
    var innings = 0;
    var totalRuns = 0;
    var ballsFaced = 0;
    var notOuts = 0;
    var highScore = 0;
    var fifties = 0;
    var hundreds = 0;
    var fours = 0;
    var sixes = 0;
    var ducks = 0;
    var timesRetired = 0;

    var ballsBowled = 0;
    var runsConceded = 0;
    var wickets = 0;
    var maidens = 0;
    var wides = 0;
    var noBalls = 0;
    var bestWickets = 0;
    var bestRuns = 0;
    var fiveWicketHauls = 0;

    var catches = 0;
    var runOuts = 0;
    var stumpings = 0;

    var wins = 0;
    var losses = 0;
    var ties = 0;

    final scoreTimeline = <_InningsScoreEntry>[];

    for (var matchIndex = 0; matchIndex < completedMatches.length; matchIndex++) {
      final match = completedMatches[matchIndex];
      final playersById = _playersById(match);
      final playerIds = playersById.values
          .where((player) => player.name == playerName)
          .map((player) => player.id)
          .toSet();

      if (playerIds.isEmpty) {
        continue;
      }

      matches += 1;

      final teamNames = <String>{};
      if (match.team1Players.any((player) => playerIds.contains(player.id))) {
        teamNames.add(match.team1Name);
      }
      if (match.team2Players.any((player) => playerIds.contains(player.id))) {
        teamNames.add(match.team2Name);
      }

      if (match.winnerTeamName == null) {
        ties += 1;
      } else if (teamNames.contains(match.winnerTeamName)) {
        wins += 1;
      } else {
        losses += 1;
      }

      timesRetired += playersById.values
          .where((player) => playerIds.contains(player.id) && (player.isRetired || player.isRetiredHurt))
          .length;
      for (final dismissedPlayer in playersById.values.where((player) => player.isOut)) {
        if (dismissedPlayer.dismissedBy == null || !playerIds.contains(dismissedPlayer.dismissedBy)) {
          continue;
        }
        if (_isCatchType(dismissedPlayer.wicketType)) {
          catches += 1;
        } else if (dismissedPlayer.wicketType == 'stumped') {
          stumpings += 1;
        } else if (dismissedPlayer.wicketType == 'run_out') {
          runOuts += 1;
        }
      }

      final inningsList = <Innings?>[match.firstInnings, match.secondInnings];
      for (final currentInnings in inningsList) {
        if (currentInnings == null) {
          continue;
        }

        final inningsBalls = currentInnings.allBalls;
        final playerBalls = inningsBalls
            .where((ball) => playerIds.contains(ball.batsmanId))
            .toList(growable: false);
        final dismissedBall = _findDismissedBall(inningsBalls, playerIds);

        final playerRuns = playerBalls.fold<int>(0, (sum, ball) => sum + _battingRuns(ball));
        final playerFaced = playerBalls.where((ball) => ball.isLegalBall).length;
        final playerFours = playerBalls
            .where((ball) => _isBoundary(ball, 4))
            .length;
        final playerSixes = playerBalls
            .where((ball) => _isBoundary(ball, 6))
            .length;

        final participatedInnings = playerBalls.isNotEmpty || dismissedBall != null;

        if (participatedInnings) {
          innings += 1;
          totalRuns += playerRuns;
          ballsFaced += playerFaced;
          fours += playerFours;
          sixes += playerSixes;
          if (playerRuns > highScore) {
            highScore = playerRuns;
          }
          if (playerRuns >= 50 && playerRuns < 100) {
            fifties += 1;
          }
          if (playerRuns >= 100) {
            hundreds += 1;
          }

          final wasOut = dismissedBall != null;
          if (!wasOut) {
            notOuts += 1;
          }
          if (wasOut && playerRuns == 0) {
            ducks += 1;
          }
          scoreTimeline.add(
            _InningsScoreEntry(
              score: playerRuns,
              timestamp: match.completedAt ?? match.createdAt,
              inningsNumber: currentInnings.inningsNumber,
              matchOrder: matchIndex,
            ),
          );
        }

        final bowlerBalls = inningsBalls
            .where((ball) => playerIds.contains(ball.bowlerId))
            .toList(growable: false);
        final inningsRunsConceded =
            bowlerBalls.fold<int>(0, (sum, ball) => sum + _deliveryTotalRuns(ball));
        final inningsWickets = bowlerBalls
            .where((ball) => ball.isWicket && ball.wicketType != 'run_out')
            .length;

        ballsBowled += bowlerBalls.where((ball) => ball.isLegalBall).length;
        runsConceded += inningsRunsConceded;
        wickets += inningsWickets;
        wides += bowlerBalls.where((ball) => ball.isWide).length;
        noBalls += bowlerBalls.where((ball) => ball.isNoBall).length;

        final playerOvers = currentInnings.overs
            .where((over) => playerIds.contains(over.bowlerId) && over.balls.isNotEmpty)
            .toList(growable: false);
        maidens += playerOvers
            .where((over) => over.isComplete(match.rules.ballsPerOver) && over.runsInOver == 0)
            .length;

        if (_isBetterBowlingFigure(inningsWickets, inningsRunsConceded, bestWickets, bestRuns)) {
          bestWickets = inningsWickets;
          bestRuns = inningsRunsConceded;
        }
        if (inningsWickets >= 5) {
          fiveWicketHauls += 1;
        }

      }
    }

    scoreTimeline.sort((a, b) {
      final byTime = a.timestamp.compareTo(b.timestamp);
      if (byTime != 0) {
        return byTime;
      }
      final byMatchOrder = a.matchOrder.compareTo(b.matchOrder);
      if (byMatchOrder != 0) {
        return byMatchOrder;
      }
      return a.inningsNumber.compareTo(b.inningsNumber);
    });

    final lastFiveScores = scoreTimeline
        .map((entry) => entry.score)
        .toList(growable: false)
        .takeLast(5);

    return PlayerStats(
      playerName: playerName,
      matches: matches,
      innings: innings,
      totalRuns: totalRuns,
      ballsFaced: ballsFaced,
      notOuts: notOuts,
      highScore: highScore,
      fifties: fifties,
      hundreds: hundreds,
      fours: fours,
      sixes: sixes,
      ducks: ducks,
      timesRetired: timesRetired,
      ballsBowled: ballsBowled,
      runsConceded: runsConceded,
      wickets: wickets,
      maidens: maidens,
      wides: wides,
      noBalls: noBalls,
      bestWickets: bestWickets,
      bestRuns: bestRuns,
      fiveWicketHauls: fiveWicketHauls,
      catches: catches,
      runOuts: runOuts,
      stumpings: stumpings,
      wins: wins,
      losses: losses,
      ties: ties,
      lastFiveScores: lastFiveScores,
    );
  }

  // Compute stats for ALL players in a team across all matches.
  List<PlayerStats> calculateForTeam(String teamName, List<MatchModel> allMatches) {
    final completedMatches = _completedMatches(allMatches);
    final playerNames = <String>{};

    for (final match in completedMatches) {
      if (match.team1Name == teamName) {
        playerNames.addAll(match.team1Players.map((player) => player.name));
      }
      if (match.team2Name == teamName) {
        playerNames.addAll(match.team2Players.map((player) => player.name));
      }
    }

    final results = playerNames
        .map((name) => _calculateForPlayerInTeam(name, teamName, completedMatches))
        .toList(growable: false)
      ..sort((a, b) {
        final byRuns = b.totalRuns.compareTo(a.totalRuns);
        if (byRuns != 0) {
          return byRuns;
        }
        return b.matches.compareTo(a.matches);
      });

    return results;
  }

  // Compute match-specific stats (for post-match report).
  MatchStatsReport calculateMatchReport(MatchModel match) {
    final playersById = _playersById(match);
    final inningsList = <Innings?>[match.firstInnings, match.secondInnings];

    final battingRuns = <String, int>{};
    final bowlingRuns = <String, int>{};
    final bowlingWickets = <String, int>{};
    final bowlingDotBalls = <String, int>{};
    final boundaries = <String, int>{};

    final runRateChart = <OverRunRatePoint>[];
    final partnerships = <PartnershipRecord>[];

    Over? highestOver;
    int highestOverInnings = 0;

    for (final innings in inningsList.whereType<Innings>()) {
      var cumulativeRuns = 0;
      var cumulativeLegalBalls = 0;

      for (final over in innings.overs.where((over) => over.balls.isNotEmpty)) {
        cumulativeRuns += over.runsInOver;
        cumulativeLegalBalls += over.legalBallCount;

        final runRate = cumulativeLegalBalls == 0
            ? 0.0
            : (cumulativeRuns / cumulativeLegalBalls) * match.rules.ballsPerOver;
        runRateChart.add(
          OverRunRatePoint(
            inningsNumber: innings.inningsNumber,
            overNumber: over.overNumber + 1,
            runs: cumulativeRuns,
            runRate: runRate,
          ),
        );

        if (highestOver == null || over.runsInOver > highestOver.runsInOver) {
          highestOver = over;
          highestOverInnings = innings.inningsNumber;
        }

        for (final ball in over.balls) {
          battingRuns.update(ball.batsmanId, (value) => value + _battingRuns(ball), ifAbsent: () => _battingRuns(ball));
          bowlingRuns.update(ball.bowlerId, (value) => value + _deliveryTotalRuns(ball), ifAbsent: () => _deliveryTotalRuns(ball));

          if (ball.isWicket && ball.wicketType != 'run_out') {
            bowlingWickets.update(ball.bowlerId, (value) => value + 1, ifAbsent: () => 1);
          }

          if (ball.isLegalBall && _deliveryTotalRuns(ball) == 0) {
            bowlingDotBalls.update(ball.bowlerId, (value) => value + 1, ifAbsent: () => 1);
          }

          if (_isBoundary(ball, 4) || _isBoundary(ball, 6)) {
            boundaries.update(ball.batsmanId, (value) => value + 1, ifAbsent: () => 1);
          }
        }
      }

      partnerships.addAll(_extractPartnerships(innings, playersById));
    }

    final topScorerId = _maxKeyByValue(battingRuns);
    final topScorer = topScorerId == null
        ? null
        : LeaderStat(playerName: _playerName(playersById, topScorerId), value: battingRuns[topScorerId] ?? 0);

    final bestBowlerId = _bestBowlerId(bowlingWickets, bowlingRuns);
    final bestBowler = bestBowlerId == null
        ? null
        : BowlingLeaderStat(
            playerName: _playerName(playersById, bestBowlerId),
            wickets: bowlingWickets[bestBowlerId] ?? 0,
            runs: bowlingRuns[bestBowlerId] ?? 0,
          );

    final dotLeaderId = _maxKeyByValue(bowlingDotBalls);
    final mostDotBalls = dotLeaderId == null
        ? null
        : LeaderStat(
            playerName: _playerName(playersById, dotLeaderId),
            value: bowlingDotBalls[dotLeaderId] ?? 0,
          );

    final boundaryLeaderId = _maxKeyByValue(boundaries);
    final mostBoundaries = boundaryLeaderId == null
        ? null
        : LeaderStat(
            playerName: _playerName(playersById, boundaryLeaderId),
            value: boundaries[boundaryLeaderId] ?? 0,
          );

    final highestOverText = highestOver == null
        ? null
        : 'Innings $highestOverInnings - Over ${highestOver.overNumber + 1}: ${highestOver.runsInOver} runs';

    return MatchStatsReport(
      topScorer: topScorer,
      bestBowler: bestBowler,
      mostDotBalls: mostDotBalls,
      mostBoundaries: mostBoundaries,
      partnerships: partnerships,
      highestOver: highestOverText,
      runRateChart: runRateChart,
    );
  }

  // Head-to-head: Team A vs Team B historical record.
  HeadToHead calculateH2H(String team1, String team2, List<MatchModel> matches) {
    final relevantMatches = _completedMatches(matches)
        .where(
          (match) =>
              (match.team1Name == team1 && match.team2Name == team2) ||
              (match.team1Name == team2 && match.team2Name == team1),
        )
        .toList(growable: false);

    var team1Wins = 0;
    var team2Wins = 0;
    var ties = 0;

    final totals = <int>[];
    final firstInningsTotals = <int>[];
    final secondInningsTotals = <int>[];

    for (final match in relevantMatches) {
      final winner = match.winnerTeamName;
      if (winner == null) {
        ties += 1;
      } else if (winner == team1) {
        team1Wins += 1;
      } else if (winner == team2) {
        team2Wins += 1;
      }

      final first = match.firstInnings;
      final second = match.secondInnings;
      if (first != null) {
        totals.add(first.totalRuns);
        firstInningsTotals.add(first.totalRuns);
      }
      if (second != null) {
        totals.add(second.totalRuns);
        secondInningsTotals.add(second.totalRuns);
      }
    }

    final highestTeamTotal = totals.isEmpty ? 0 : totals.reduce((a, b) => a > b ? a : b);
    final lowestTeamTotal = totals.isEmpty ? 0 : totals.reduce((a, b) => a < b ? a : b);

    return HeadToHead(
      team1: team1,
      team2: team2,
      matches: relevantMatches.length,
      team1Wins: team1Wins,
      team2Wins: team2Wins,
      ties: ties,
      highestTeamTotal: highestTeamTotal,
      lowestTeamTotal: lowestTeamTotal,
      averageFirstInningsScore: _average(firstInningsTotals),
      averageSecondInningsScore: _average(secondInningsTotals),
    );
  }

  PlayerStats _calculateForPlayerInTeam(String playerName, String teamName, List<MatchModel> matches) {
    final filteredMatches = matches
        .where(
          (match) =>
              (match.team1Name == teamName &&
                  match.team1Players.any((player) => player.name == playerName)) ||
              (match.team2Name == teamName &&
                  match.team2Players.any((player) => player.name == playerName)),
        )
        .toList(growable: false);

    return calculateForPlayer(playerName, filteredMatches);
  }

  List<PartnershipRecord> _extractPartnerships(
    Innings innings,
    Map<String, Player> playersById,
  ) {
    final records = <PartnershipRecord>[];
    var segmentRuns = 0;
    var segmentBalls = 0;
    var wicketNumber = 1;
    final segmentBatters = <String>[];

    void flushSegment() {
      if (segmentRuns == 0 && segmentBalls == 0) {
        return;
      }
      records.add(
        PartnershipRecord(
          batters: segmentBatters.isEmpty
              ? 'Unknown'
              : segmentBatters.map((id) => _playerName(playersById, id)).join(' & '),
          runs: segmentRuns,
          balls: segmentBalls,
          forWicket: wicketNumber,
          inningsNumber: innings.inningsNumber,
        ),
      );
    }

    for (final ball in innings.allBalls) {
      segmentRuns += _deliveryTotalRuns(ball);
      if (ball.isLegalBall) {
        segmentBalls += 1;
      }
      if (!segmentBatters.contains(ball.batsmanId) && segmentBatters.length < 2) {
        segmentBatters.add(ball.batsmanId);
      }

      if (ball.isWicket) {
        flushSegment();
        segmentRuns = 0;
        segmentBalls = 0;
        wicketNumber += 1;
        segmentBatters.clear();
      }
    }

    flushSegment();
    return records;
  }

  List<MatchModel> _completedMatches(List<MatchModel> allMatches) {
    final completed = allMatches.where((match) => match.status == MatchStatus.completed).toList();
    completed.sort((a, b) {
      final aDate = a.completedAt ?? a.createdAt;
      final bDate = b.completedAt ?? b.createdAt;
      return aDate.compareTo(bDate);
    });
    return completed;
  }

  Map<String, Player> _playersById(MatchModel match) {
    return <String, Player>{
      for (final player in <Player>[...match.team1Players, ...match.team2Players]) player.id: player,
    };
  }

  String _dismissedPlayerId(Ball ball) {
    return ball.dismissedPlayerId ?? ball.batsmanId;
  }

  Ball? _findDismissedBall(List<Ball> balls, Set<String> playerIds) {
    for (final ball in balls) {
      if (!ball.isWicket) {
        continue;
      }
      if (playerIds.contains(_dismissedPlayerId(ball))) {
        return ball;
      }
    }
    return null;
  }

  bool _isBoundary(Ball ball, int runs) {
    return !ball.isWide && !ball.isBye && !ball.isLegBye && ball.runsScored == runs;
  }

  bool _isCatchType(String? wicketType) {
    return wicketType == 'caught' ||
        wicketType == 'tip_catch' ||
        wicketType == 'wall_catch' ||
        wicketType == 'one_bounce';
  }

  int _battingRuns(Ball ball) {
    if (ball.isWide || ball.isBye || ball.isLegBye) {
      return 0;
    }
    return ball.runsScored;
  }

  int _deliveryTotalRuns(Ball ball) {
    // Illegal deliveries contribute one penalty run plus any runs scored off the bat/byes.
    return (ball.isWide || ball.isNoBall) ? 1 + ball.runsScored : ball.runsScored;
  }

  bool _isBetterBowlingFigure(
    int candidateWickets,
    int candidateRuns,
    int currentWickets,
    int currentRuns,
  ) {
    if (candidateWickets != currentWickets) {
      return candidateWickets > currentWickets;
    }
    // Keep the initial 0/0 baseline ahead of 0/N figures.
    if (candidateWickets == 0 && currentRuns == 0) {
      return false;
    }
    return candidateRuns < currentRuns;
  }

  String _playerName(Map<String, Player> playersById, String id) {
    return playersById[id]?.name ?? id;
  }

  String? _maxKeyByValue(Map<String, int> values) {
    String? key;
    var maxValue = -1;
    values.forEach((candidateKey, candidateValue) {
      if (candidateValue > maxValue) {
        maxValue = candidateValue;
        key = candidateKey;
      }
    });
    return key;
  }

  String? _bestBowlerId(Map<String, int> wickets, Map<String, int> runsConceded) {
    // Large ceiling value so the first real bowling figure always wins the tie-break compare.
    const maxRunSentinel = 1 << 30;
    String? bestId;
    var bestWickets = -1;
    var bestRuns = maxRunSentinel;

    for (final id in {...wickets.keys, ...runsConceded.keys}) {
      final w = wickets[id] ?? 0;
      final r = runsConceded[id] ?? 0;
      if (w > bestWickets || (w == bestWickets && r < bestRuns)) {
        bestId = id;
        bestWickets = w;
        bestRuns = r;
      }
    }

    return bestId;
  }

  double _average(List<int> values) {
    if (values.isEmpty) {
      return 0;
    }
    final total = values.fold<int>(0, (sum, value) => sum + value);
    return total / values.length;
  }
}

class _InningsScoreEntry {
  const _InningsScoreEntry({
    required this.score,
    required this.timestamp,
    required this.inningsNumber,
    required this.matchOrder,
  });

  final int score;
  final DateTime timestamp;
  final int inningsNumber;
  final int matchOrder;
}

extension _TakeLastExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count <= 0 || isEmpty) {
      return <T>[];
    }
    if (length <= count) {
      return List<T>.from(this);
    }
    return sublist(length - count);
  }
}
