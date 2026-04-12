import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/match_status.dart';
import '../../storage/services/match_repository.dart';
import '../domain/engines/match_engine.dart';
import '../domain/engines/rule_engine.dart';
import '../domain/models/ball_model.dart';
import '../domain/models/match_model.dart';

final activeMatchProvider = StateNotifierProvider<ActiveMatchNotifier, MatchModel?>((ref) {
  return ActiveMatchNotifier(ref);
});

class ActiveMatchNotifier extends StateNotifier<MatchModel?> {
  ActiveMatchNotifier(this._ref) : super(null);

  final Ref _ref;
  final MatchEngine _engine = const MatchEngine();
  final RuleEngine _ruleEngine = const RuleEngine();

  Future<void> setMatch(MatchModel match) async {
    state = match;
    await _persist(match);
  }

  Future<MatchModel?> recordBall(Ball ball) async {
    final match = state;
    if (match == null) return null;
    final updated = _engine.recordBall(match, ball);
    state = updated;
    await _persist(updated);
    return updated;
  }

  Future<MatchModel?> undoLastBall() async {
    final match = state;
    if (match == null) return null;
    final updated = _engine.undoLastBall(match);
    state = updated;
    await _persist(updated);
    return updated;
  }

  Future<MatchModel?> setBatsman(String playerId, {required bool isStriker}) async {
    final match = state;
    if (match == null) return null;
    final updated = _engine.setBatsman(match, playerId, isStriker);
    state = updated;
    await _persist(updated);
    return updated;
  }

  Future<MatchModel?> setBowler(String playerId) async {
    final match = state;
    if (match == null) return null;
    final updated = _engine.setBowler(match, playerId);
    state = updated;
    await _persist(updated);
    return updated;
  }

  Future<MatchModel?> swapStrike() async {
    final match = state;
    final innings = match?.currentInnings;
    if (match == null || innings == null) return null;
    final striker = innings.currentBatsmanId;
    final nonStriker = innings.currentNonStrikerId;
    if (striker == null || nonStriker == null) return null;

    var updated = _engine.setBatsman(match, nonStriker, true);
    updated = _engine.setBatsman(updated, striker, false);
    state = updated;
    await _persist(updated);
    return updated;
  }

  Future<MatchModel?> retireBatsman(String playerId, {bool isHurt = false}) async {
    final match = state;
    if (match == null) return null;
    final updated = _engine.retireBatsman(match, playerId, isHurt);
    state = updated;
    await _persist(updated);
    return updated;
  }

  Future<MatchModel?> startSecondInnings() async {
    final match = state;
    if (match == null) return null;
    final updated = _engine.startSecondInnings(match).copyWith(status: MatchStatus.liveSecondInnings);
    state = updated;
    await _persist(updated);
    return updated;
  }

  Future<MatchModel?> completeMatch() async {
    final match = state;
    if (match == null) return null;
    final updated = _engine.completeMatch(match);
    state = updated;
    await _persist(updated);
    return updated;
  }

  Future<MatchModel?> triggerInningsEndIfNeeded() async {
    final match = state;
    final innings = match?.currentInnings;
    if (match == null || innings == null) return null;
    final battingPlayers = innings.battingTeamId == 'team1' ? match.team1Players : match.team2Players;
    final endReason = _ruleEngine.checkInningsEnd(
      innings: innings,
      rules: match.rules,
      battingPlayers: battingPlayers,
      target: innings.inningsNumber == 2 ? match.target : null,
    );
    if (endReason == null) return match;
    final updatedInnings = innings.copyWith(isCompleted: true);
    final updated = innings.inningsNumber == 1
        ? match.copyWith(firstInnings: updatedInnings)
        : match.copyWith(secondInnings: updatedInnings);
    state = updated;
    await _persist(updated);
    return updated;
  }

  void clearMatch() {
    state = null;
  }

  Future<void> _persist(MatchModel match) async {
    await _ref.read(matchListProvider.notifier).saveMatch(match);
  }
}
