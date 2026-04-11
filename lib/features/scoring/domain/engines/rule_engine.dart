import '../models/ball_model.dart';
import '../models/gully_rules_model.dart';
import '../models/innings_model.dart';
import '../models/over_model.dart';
import '../models/player_model.dart';

class RuleEngine {
  const RuleEngine();

  // Returns true if this ball type is allowed as a wicket given current rules.
  bool isWicketTypeAllowed(String wicketType, GullyRules rules) {
    // Always-allowed dismissal types.
    if (wicketType == 'bowled' ||
        wicketType == 'caught' ||
        wicketType == 'run_out' ||
        wicketType == 'stumped') {
      return true;
    }

    // Rule-gated dismissal types.
    if (wicketType == 'tip_catch') return rules.tipOneHandOut;
    if (wicketType == 'wall_catch') return rules.wallCatchOut;
    if (wicketType == 'one_bounce') return rules.oneBounceCatchOut;
    if (wicketType == 'lbw') return rules.lbwAllowed;

    // Unknown wicket types are disallowed by default.
    return false;
  }

  // Returns true if batsman must retire now.
  bool shouldRetire(Player batsman, GullyRules rules) {
    if (rules.halfCenturyRetire && batsman.runsScored >= 50) return true;
    if (rules.centuryRetire && batsman.runsScored >= 100) return true;
    return false;
  }

  // Returns true if the previous ball means this ball is a free hit.
  bool isFreeHit(Ball? previousBall, GullyRules rules) {
    if (!rules.noballFreeHit) return false;
    if (previousBall == null) return false;
    return previousBall.isNoBall;
  }

  // Returns true if strike should rotate (odd runs or end of over).
  bool shouldRotateStrike(int runsScored, bool isEndOfOver) {
    if (isEndOfOver) return true;
    return runsScored % 2 != 0;
  }

  // Check if innings is over — return reason string or null.
  String? checkInningsEnd({
    required Innings innings,
    required GullyRules rules,
    required List<Player> battingPlayers,
    int? target,
  }) {
    // Count unavailable batters for last-man-standing style rules.
    final unavailableBatters =
        battingPlayers.where((p) => p.isOut || p.isRetired || p.isRetiredHurt).length;

    // End for normal rules when batting unit has no legal next pair.
    if (!rules.lastManBatsAlone && innings.wickets >= (rules.totalPlayers - 1)) {
      return 'all_out';
    }

    // End for last-man rule once all partners except one are unavailable.
    if (rules.lastManBatsAlone && unavailableBatters >= (rules.totalPlayers - 1)) {
      return 'all_out';
    }

    // End if configured overs quota has been completed.
    if (innings.completedOvers(rules.ballsPerOver) >= rules.totalOvers) {
      return 'overs_complete';
    }

    // End chase as soon as target is reached/passed.
    if (target != null && innings.inningsNumber == 2 && innings.totalRuns >= target) {
      return 'target_reached';
    }

    return null;
  }

  // Check if a bowler has exceeded max overs.
  bool bowlerExceededMaxOvers(String bowlerId, List<Over> overs, GullyRules rules) {
    if (rules.maxOversPerBowler == 0) return false;
    final bowled = overs.where((o) => o.bowlerId == bowlerId).length;
    return bowled >= rules.maxOversPerBowler;
  }

  // Returns list of eligible bowlers.
  List<Player> eligibleBowlers({
    required List<Player> bowlingTeamPlayers,
    required List<Over> overs,
    required GullyRules rules,
    String? lastBowlerId,
  }) {
    return bowlingTeamPlayers.where((p) {
      // Prevent consecutive overs by same bowler.
      if (p.id == lastBowlerId) return false;
      // Enforce per-bowler over cap.
      return !bowlerExceededMaxOvers(p.id, overs, rules);
    }).toList();
  }
}
