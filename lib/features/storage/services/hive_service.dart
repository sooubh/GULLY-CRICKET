import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/hive_keys.dart';
import '../../../core/constants/match_status.dart';
import '../../scoring/domain/models/match_model.dart';

class HiveService {
  const HiveService();

  Box<MatchModel> get _matchBox => Hive.box<MatchModel>(HiveKeys.matchBox);

  Future<void> saveMatch(MatchModel match) async {
    await _matchBox.put(match.id, match);
  }

  MatchModel? getMatch(String id) {
    return _matchBox.get(id);
  }

  List<MatchModel> getAllMatches() {
    final matches = _matchBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches;
  }

  Future<void> deleteMatch(String id) async {
    await _matchBox.delete(id);
  }

  List<MatchModel> getCompletedMatches() {
    return _matchBox.values.where((m) => m.status == MatchStatus.completed).toList();
  }

  List<MatchModel> getLiveMatches() {
    return _matchBox.values
        .where(
          (m) => m.status == MatchStatus.liveFirstInnings || m.status == MatchStatus.liveSecondInnings,
        )
        .toList();
  }
}
