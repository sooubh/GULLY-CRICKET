import '../models/ball_model.dart';
import '../models/innings_model.dart';
import '../models/match_model.dart';
import '../models/over_model.dart';
import '../models/partnership_model.dart';
import '../models/player_model.dart';
import 'rule_engine.dart';

class MatchEngine {
  const MatchEngine();

  static const RuleEngine _ruleEngine = RuleEngine();

  // Apply one ball to the match — returns updated MatchModel (immutable).
  MatchModel recordBall(MatchModel match, Ball ball) {
    // 1) Resolve active innings; if none, nothing to apply.
    final innings = match.currentInnings;
    if (innings == null) return match;

    // 2) Clone overs and ensure there is an active over to append this ball.
    final overs = List<Over>.from(innings.overs);
    if (overs.isEmpty || overs.last.isComplete(match.rules.ballsPerOver)) {
      overs.add(
        Over(
          id: '${innings.id}_${overs.length}',
          overNumber: overs.length,
          bowlerId: innings.currentBowlerId ?? ball.bowlerId,
        ),
      );
    }
    final currentOver = overs.last;

    // 3) Add the ball into the current over and refresh over aggregates.
    final updatedOverBalls = <Ball>[...currentOver.balls, ball];
    final updatedOver = currentOver.copyWith(
      balls: updatedOverBalls,
      runsInOver: currentOver.runsInOver + _deliveryTotalRuns(ball),
      wicketsInOver: currentOver.wicketsInOver + (ball.isWicket ? 1 : 0),
    );
    overs[overs.length - 1] = updatedOver;

    // 4) Split team lists by innings roles so we can update immutable player rows.
    final battingIsTeam1 = innings.battingTeamId == 'team1';
    var battingPlayers = List<Player>.from(battingIsTeam1 ? match.team1Players : match.team2Players);
    var bowlingPlayers = List<Player>.from(battingIsTeam1 ? match.team2Players : match.team1Players);

    // 5) Update striker batting stats.
    final batsmanIndex = battingPlayers.indexWhere((p) => p.id == ball.batsmanId);
    if (batsmanIndex != -1) {
      final batsman = battingPlayers[batsmanIndex];
      final batsmanRuns = (ball.isWide || ball.isBye || ball.isLegBye) ? 0 : ball.runsScored;
      battingPlayers[batsmanIndex] = batsman.copyWith(
        runsScored: batsman.runsScored + batsmanRuns,
        ballsFaced: batsman.ballsFaced + (ball.isLegalBall ? 1 : 0),
      );
    }

    // 6) Update bowler stats for conceded runs/extras/wickets.
    final bowlerIndex = bowlingPlayers.indexWhere((p) => p.id == ball.bowlerId);
    if (bowlerIndex != -1) {
      final bowler = bowlingPlayers[bowlerIndex];
      final creditsBowlerWicket = ball.isWicket && (ball.wicketType != 'run_out');
      bowlingPlayers[bowlerIndex] = bowler.copyWith(
        runsConceded: bowler.runsConceded + _deliveryTotalRuns(ball),
        wicketsTaken: bowler.wicketsTaken + (creditsBowlerWicket ? 1 : 0),
        widesBowled: bowler.widesBowled + (ball.isWide ? 1 : 0),
        noballsBowled: bowler.noballsBowled + (ball.isNoBall ? 1 : 0),
      );
    }

    // 7) If wicket fell, mark dismissed batter as out.
    if (ball.isWicket) {
      final dismissedId = ball.dismissedPlayerId ?? ball.batsmanId;
      final dismissedIndex = battingPlayers.indexWhere((p) => p.id == dismissedId);
      if (dismissedIndex != -1) {
        battingPlayers[dismissedIndex] = battingPlayers[dismissedIndex].copyWith(
          isOut: true,
          wicketType: ball.wicketType,
          dismissedBy: ball.bowlerId,
          isCurrentlyBatting: false,
        );
      }
    }

    // 8) Build updated innings aggregate totals.
    var updatedInnings = innings.copyWith(
      overs: overs,
      totalRuns: innings.totalRuns + _deliveryTotalRuns(ball),
      wickets: innings.wickets + (ball.isWicket ? 1 : 0),
    );

    // 9) Auto-retire striker if rule says so.
    final strikerIndex = updatedInnings.currentBatsmanId == null
        ? -1
        : battingPlayers.indexWhere((p) => p.id == updatedInnings.currentBatsmanId);
    final Player? updatedStriker = strikerIndex == -1 ? null : battingPlayers[strikerIndex];
    if (updatedStriker != null && _ruleEngine.shouldRetire(updatedStriker, match.rules)) {
      final retiringIndex = battingPlayers.indexWhere((p) => p.id == updatedStriker.id);
      if (retiringIndex != -1) {
        battingPlayers[retiringIndex] = battingPlayers[retiringIndex].copyWith(
          isRetired: true,
          isCurrentlyBatting: false,
        );
      }
      updatedInnings = updatedInnings.copyWith(currentBatsmanId: null);
    }

    // 10) Rotate strike for odd runs or over-end.
    final overCompleted = updatedOver.isComplete(match.rules.ballsPerOver);
    if (_ruleEngine.shouldRotateStrike(ball.runsScored, overCompleted)) {
      updatedInnings = updatedInnings.copyWith(
        currentBatsmanId: updatedInnings.currentNonStrikerId,
        currentNonStrikerId: updatedInnings.currentBatsmanId,
      );
    }

    // 11) If over completed and innings continues, pre-create next over stub.
    final endReason = _ruleEngine.checkInningsEnd(
      innings: updatedInnings,
      rules: match.rules,
      battingPlayers: battingPlayers,
      target: updatedInnings.inningsNumber == 2 ? match.target : null,
    );
    if (endReason == null && overCompleted) {
      final nextOvers = List<Over>.from(updatedInnings.overs)
        ..add(
          Over(
            id: '${updatedInnings.id}_${updatedInnings.overs.length}',
            overNumber: updatedInnings.overs.length,
            bowlerId: updatedInnings.currentBowlerId ?? '',
          ),
        );
      updatedInnings = updatedInnings.copyWith(overs: nextOvers);
    }

    // 12) Mark innings complete if any terminating condition is reached.
    if (endReason != null) {
      updatedInnings = updatedInnings.copyWith(isCompleted: true);
    }

    // 13) Reassemble teams back into match according to innings batting side.
    final updatedTeam1 = battingIsTeam1 ? battingPlayers : bowlingPlayers;
    final updatedTeam2 = battingIsTeam1 ? bowlingPlayers : battingPlayers;

    // 14) Write innings back into first/second slot immutably.
    return updatedInnings.inningsNumber == 1
        ? match.copyWith(team1Players: updatedTeam1, team2Players: updatedTeam2, firstInnings: updatedInnings)
        : match.copyWith(team1Players: updatedTeam1, team2Players: updatedTeam2, secondInnings: updatedInnings);
  }

  // Undo the last legal ball — returns previous match state.
  MatchModel undoLastBall(MatchModel match) {
    // 1) Resolve active innings.
    final innings = match.currentInnings;
    if (innings == null || innings.overs.isEmpty) return match;

    // 2) Copy overs and normalize active over pointer.
    final overs = List<Over>.from(innings.overs);
    var activeOver = overs.last;
    if (activeOver.balls.isEmpty && overs.length > 1) {
      overs.removeLast();
      activeOver = overs.last;
    }
    if (activeOver.balls.isEmpty) return match;

    // 3) Remove the last delivered ball.
    final removedBall = activeOver.balls.last;
    final overWasComplete = activeOver.isComplete(match.rules.ballsPerOver);
    final remainingBalls = List<Ball>.from(activeOver.balls)..removeLast();
    final updatedOver = activeOver.copyWith(
      balls: remainingBalls,
      runsInOver: activeOver.runsInOver - _deliveryTotalRuns(removedBall),
      wicketsInOver: activeOver.wicketsInOver - (removedBall.isWicket ? 1 : 0),
    );
    overs[overs.length - 1] = updatedOver;

    // 4) Resolve batting/bowling team lists and reverse player stats.
    final battingIsTeam1 = innings.battingTeamId == 'team1';
    var battingPlayers = List<Player>.from(battingIsTeam1 ? match.team1Players : match.team2Players);
    var bowlingPlayers = List<Player>.from(battingIsTeam1 ? match.team2Players : match.team1Players);

    final batsmanIndex = battingPlayers.indexWhere((p) => p.id == removedBall.batsmanId);
    if (batsmanIndex != -1) {
      final batsman = battingPlayers[batsmanIndex];
      final batsmanRuns =
          (removedBall.isWide || removedBall.isBye || removedBall.isLegBye) ? 0 : removedBall.runsScored;
      battingPlayers[batsmanIndex] = batsman.copyWith(
        runsScored: batsman.runsScored - batsmanRuns,
        ballsFaced: batsman.ballsFaced - (removedBall.isLegalBall ? 1 : 0),
      );
    }

    final bowlerIndex = bowlingPlayers.indexWhere((p) => p.id == removedBall.bowlerId);
    if (bowlerIndex != -1) {
      final bowler = bowlingPlayers[bowlerIndex];
      final creditsBowlerWicket = removedBall.isWicket && (removedBall.wicketType != 'run_out');
      bowlingPlayers[bowlerIndex] = bowler.copyWith(
        runsConceded: bowler.runsConceded - _deliveryTotalRuns(removedBall),
        wicketsTaken: bowler.wicketsTaken - (creditsBowlerWicket ? 1 : 0),
        widesBowled: bowler.widesBowled - (removedBall.isWide ? 1 : 0),
        noballsBowled: bowler.noballsBowled - (removedBall.isNoBall ? 1 : 0),
      );
    }

    // 5) Reverse dismissal marker if this ball took a wicket.
    if (removedBall.isWicket) {
      final dismissedId = removedBall.dismissedPlayerId ?? removedBall.batsmanId;
      final dismissedIndex = battingPlayers.indexWhere((p) => p.id == dismissedId);
      if (dismissedIndex != -1) {
        battingPlayers[dismissedIndex] = battingPlayers[dismissedIndex].copyWith(
          isOut: false,
          wicketType: null,
          dismissedBy: null,
        );
      }
    }

    // 6) Reverse innings totals and restore strike if it was rotated on this ball.
    var updatedInnings = innings.copyWith(
      overs: overs,
      totalRuns: innings.totalRuns - _deliveryTotalRuns(removedBall),
      wickets: innings.wickets - (removedBall.isWicket ? 1 : 0),
      isCompleted: false,
    );

    if (_ruleEngine.shouldRotateStrike(removedBall.runsScored, overWasComplete)) {
      updatedInnings = updatedInnings.copyWith(
        currentBatsmanId: updatedInnings.currentNonStrikerId,
        currentNonStrikerId: updatedInnings.currentBatsmanId,
      );
    }

    // 7) Reassemble teams and write innings back.
    final updatedTeam1 = battingIsTeam1 ? battingPlayers : bowlingPlayers;
    final updatedTeam2 = battingIsTeam1 ? bowlingPlayers : battingPlayers;

    return updatedInnings.inningsNumber == 1
        ? match.copyWith(team1Players: updatedTeam1, team2Players: updatedTeam2, firstInnings: updatedInnings)
        : match.copyWith(team1Players: updatedTeam1, team2Players: updatedTeam2, secondInnings: updatedInnings);
  }

  // Set active batsman (striker or non-striker).
  MatchModel setBatsman(MatchModel match, String playerId, bool isStriker) {
    // 1) Resolve innings and batting side.
    final innings = match.currentInnings;
    if (innings == null) return match;
    final battingIsTeam1 = innings.battingTeamId == 'team1';
    var battingPlayers = List<Player>.from(battingIsTeam1 ? match.team1Players : match.team2Players);

    // 2) Clear existing flag on prior slot occupant.
    final previousId = isStriker ? innings.currentBatsmanId : innings.currentNonStrikerId;
    final previousIndex = previousId == null ? -1 : battingPlayers.indexWhere((p) => p.id == previousId);
    if (previousIndex != -1) {
      battingPlayers[previousIndex] = battingPlayers[previousIndex].copyWith(isCurrentlyBatting: false);
    }

    // 3) Mark new batter as active.
    final newIndex = battingPlayers.indexWhere((p) => p.id == playerId);
    if (newIndex != -1) {
      battingPlayers[newIndex] = battingPlayers[newIndex].copyWith(isCurrentlyBatting: true);
    }

    // 4) Update innings ids immutably.
    final updatedInnings = isStriker
        ? innings.copyWith(currentBatsmanId: playerId)
        : innings.copyWith(currentNonStrikerId: playerId);

    final updatedTeam1 = battingIsTeam1 ? battingPlayers : match.team1Players;
    final updatedTeam2 = battingIsTeam1 ? match.team2Players : battingPlayers;

    return updatedInnings.inningsNumber == 1
        ? match.copyWith(team1Players: updatedTeam1, team2Players: updatedTeam2, firstInnings: updatedInnings)
        : match.copyWith(team1Players: updatedTeam1, team2Players: updatedTeam2, secondInnings: updatedInnings);
  }

  // Set active bowler for new over.
  MatchModel setBowler(MatchModel match, String playerId) {
    // 1) Resolve innings and bowling side.
    final innings = match.currentInnings;
    if (innings == null) return match;
    final bowlingIsTeam1 = innings.bowlingTeamId == 'team1';
    var bowlingPlayers = List<Player>.from(bowlingIsTeam1 ? match.team1Players : match.team2Players);

    // 2) Clear current bowling marker from all bowlers.
    bowlingPlayers = bowlingPlayers.map((p) => p.copyWith(isCurrentlyBowling: false)).toList();

    // 3) Mark selected bowler as active.
    final bowlerIndex = bowlingPlayers.indexWhere((p) => p.id == playerId);
    if (bowlerIndex != -1) {
      bowlingPlayers[bowlerIndex] = bowlingPlayers[bowlerIndex].copyWith(isCurrentlyBowling: true);
    }

    // 4) Ensure a new over stub exists for the selected bowler.
    final overs = List<Over>.from(innings.overs);
    if (overs.isEmpty || overs.last.balls.isNotEmpty) {
      overs.add(
        Over(
          id: '${innings.id}_${overs.length}',
          overNumber: overs.length,
          bowlerId: playerId,
        ),
      );
    } else {
      overs[overs.length - 1] = overs.last.copyWith(bowlerId: playerId);
    }

    // 5) Persist innings and team updates immutably.
    final updatedInnings = innings.copyWith(currentBowlerId: playerId, overs: overs);
    final updatedTeam1 = bowlingIsTeam1 ? bowlingPlayers : match.team1Players;
    final updatedTeam2 = bowlingIsTeam1 ? match.team2Players : bowlingPlayers;

    return updatedInnings.inningsNumber == 1
        ? match.copyWith(team1Players: updatedTeam1, team2Players: updatedTeam2, firstInnings: updatedInnings)
        : match.copyWith(team1Players: updatedTeam1, team2Players: updatedTeam2, secondInnings: updatedInnings);
  }

  // Retire batsman (voluntary or hurt).
  MatchModel retireBatsman(MatchModel match, String playerId, bool isHurt) {
    // 1) Resolve innings and batting side.
    final innings = match.currentInnings;
    if (innings == null) return match;
    final battingIsTeam1 = innings.battingTeamId == 'team1';
    var battingPlayers = List<Player>.from(battingIsTeam1 ? match.team1Players : match.team2Players);

    // 2) Mark player retired and clear currently batting flag.
    final index = battingPlayers.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      battingPlayers[index] = battingPlayers[index].copyWith(
        isRetired: !isHurt,
        isRetiredHurt: isHurt,
        isCurrentlyBatting: false,
      );
    }

    // 3) Remove player from active striker/non-striker slots.
    var updatedInnings = innings;
    if (innings.currentBatsmanId == playerId) {
      updatedInnings = updatedInnings.copyWith(currentBatsmanId: null);
    }
    if (innings.currentNonStrikerId == playerId) {
      updatedInnings = updatedInnings.copyWith(currentNonStrikerId: null);
    }

    final updatedTeam1 = battingIsTeam1 ? battingPlayers : match.team1Players;
    final updatedTeam2 = battingIsTeam1 ? match.team2Players : battingPlayers;

    return updatedInnings.inningsNumber == 1
        ? match.copyWith(team1Players: updatedTeam1, team2Players: updatedTeam2, firstInnings: updatedInnings)
        : match.copyWith(team1Players: updatedTeam1, team2Players: updatedTeam2, secondInnings: updatedInnings);
  }

  // Start second innings — swap batting/bowling teams.
  MatchModel startSecondInnings(MatchModel match) {
    // 1) First innings must exist to start second innings.
    final first = match.firstInnings;
    if (first == null) return match;

    // 2) Close first innings.
    final closedFirst = first.copyWith(isCompleted: true);

    // 3) Create second innings with teams swapped.
    final second = Innings(
      id: '${match.id}_innings_2',
      battingTeamId: first.bowlingTeamId,
      bowlingTeamId: first.battingTeamId,
      inningsNumber: 2,
    );

    // 4) Reset per-innings player state for second innings tracking.
    List<Player> resetPlayers(List<Player> players) {
      return players
          .map(
            (p) => p.copyWith(
              runsScored: 0,
              ballsFaced: 0,
              isOut: false,
              isRetired: false,
              isRetiredHurt: false,
              wicketType: null,
              dismissedBy: null,
              oversBowled: 0,
              runsConceded: 0,
              wicketsTaken: 0,
              widesBowled: 0,
              noballsBowled: 0,
              isCurrentlyBatting: false,
              isCurrentlyBowling: false,
            ),
          )
          .toList();
    }

    // 5) Return live match state for second innings.
    return match.copyWith(
      firstInnings: closedFirst,
      secondInnings: second,
      team1Players: resetPlayers(match.team1Players),
      team2Players: resetPlayers(match.team2Players),
      status: 2,
    );
  }

  // Finalize match.
  MatchModel completeMatch(MatchModel match) {
    // 1) If scorecards are incomplete, keep current state.
    final first = match.firstInnings;
    final second = match.secondInnings;
    if (first == null || second == null) return match;

    // 2) Compare totals and derive result text.
    String? winner;
    String description;
    if (second.totalRuns > first.totalRuns) {
      winner = second.battingTeamId == 'team1' ? match.team1Name : match.team2Name;
      final wicketsRemaining = match.rules.totalPlayers - 1 - second.wickets;
      description = '$winner won by $wicketsRemaining wickets';
    } else if (first.totalRuns > second.totalRuns) {
      winner = first.battingTeamId == 'team1' ? match.team1Name : match.team2Name;
      final runMargin = first.totalRuns - second.totalRuns;
      description = '$winner won by $runMargin runs';
    } else {
      description = 'Match Tied';
    }

    // 3) Mark match complete with final metadata.
    return match.copyWith(
      winnerTeamName: winner,
      winDescription: description,
      status: 4,
      completedAt: DateTime.now(),
      firstInnings: first.copyWith(isCompleted: true),
      secondInnings: second.copyWith(isCompleted: true),
    );
  }

  // Compute current run rate.
  double currentRunRate(Innings innings) {
    // 1) Count legal balls only.
    final balls =
        innings.overs.fold(0, (sum, o) => sum + o.balls.where((b) => b.isLegalBall).length);
    // 2) Guard divide-by-zero.
    if (balls == 0) return 0;
    // 3) Convert runs/ball to runs/over.
    return (innings.totalRuns / balls) * 6;
  }

  // Compute required run rate (second innings only).
  double requiredRunRate(int target, int runsScored, int ballsRemaining) {
    // 1) Guard divide-by-zero.
    if (ballsRemaining == 0) return 0;
    // 2) Runs needed per over from remaining balls.
    return ((target - runsScored) / ballsRemaining) * 6;
  }

  // Get current partnership runs + balls.
  Partnership currentPartnership(Innings innings) {
    // 1) Need two active batters to form a current partnership.
    final strikerId = innings.currentBatsmanId;
    final nonStrikerId = innings.currentNonStrikerId;
    if (strikerId == null || nonStrikerId == null) {
      return Partnership(
        batsmanAId: strikerId ?? '',
        batsmanBId: nonStrikerId ?? '',
        runs: 0,
        balls: 0,
        forWicket: innings.wickets + 1,
      );
    }

    // 2) Slice deliveries since the most recent wicket.
    final allBalls = innings.overs.expand((o) => o.balls).toList();
    final lastWicketIndex = allBalls.lastIndexWhere((b) => b.isWicket);
    final partnershipBalls = lastWicketIndex == -1 ? allBalls : allBalls.skip(lastWicketIndex + 1).toList();

    // 3) Sum partnership runs from both active batters.
    final runs = partnershipBalls
        .where((b) => b.batsmanId == strikerId || b.batsmanId == nonStrikerId)
        .fold(
          0,
          (sum, b) => sum + ((b.isWide || b.isBye || b.isLegBye) ? 0 : b.runsScored),
        );

    // 4) Count legal balls in the same partnership window.
    final balls = partnershipBalls.where((b) => b.isLegalBall).length;

    return Partnership(
      batsmanAId: strikerId,
      batsmanBId: nonStrikerId,
      runs: runs,
      balls: balls,
      forWicket: innings.wickets + 1,
    );
  }

  int _deliveryTotalRuns(Ball ball) {
    return (ball.isWide || ball.isNoBall) ? 1 + ball.runsScored : ball.runsScored;
  }
}
