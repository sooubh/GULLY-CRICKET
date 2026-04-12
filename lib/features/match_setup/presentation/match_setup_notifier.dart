import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/match_config.dart';

final matchSetupProvider = StateNotifierProvider<MatchSetupNotifier, MatchConfig>((ref) {
  return MatchSetupNotifier();
});

class MatchSetupNotifier extends StateNotifier<MatchConfig> {
  MatchSetupNotifier() : super(const MatchConfig());

  void updateBase({
    required String team1Name,
    required String team2Name,
    required int totalOvers,
    required int ballsPerOver,
    required int team1PlayerCount,
    required int team2PlayerCount,
    required bool enableToss,
  }) {
    state = state.copyWith(
      team1Name: team1Name,
      team2Name: team2Name,
      totalOvers: totalOvers,
      ballsPerOver: ballsPerOver,
      team1PlayerCount: team1PlayerCount,
      team2PlayerCount: team2PlayerCount,
      enableToss: enableToss,
      team1Players: _ensurePlayers(state.team1Players, team1PlayerCount),
      team2Players: _ensurePlayers(state.team2Players, team2PlayerCount),
    );
  }

  void updateTeamPlayers({
    required List<String> team1Players,
    required List<String> team2Players,
  }) {
    state = state.copyWith(
      team1Players: team1Players,
      team2Players: team2Players,
      team1PlayerCount: team1Players.length,
      team2PlayerCount: team2Players.length,
    );
  }

  void updateRules({
    required bool halfCenturyRetire,
    required bool centuryRetire,
    required bool lastManBatsAlone,
    required bool reEntryAllowed,
    required bool tipOneHandOut,
    required bool wallCatchOut,
    required bool oneBounceCatchOut,
    required bool noballFreeHit,
    required bool lbwAllowed,
    required int maxOversPerBowler,
    required bool sixIsOut,
    required bool enableMultiplayer,
  }) {
    state = state.copyWith(
      halfCenturyRetire: halfCenturyRetire,
      centuryRetire: centuryRetire,
      lastManBatsAlone: lastManBatsAlone,
      reEntryAllowed: reEntryAllowed,
      tipOneHandOut: tipOneHandOut,
      wallCatchOut: wallCatchOut,
      oneBounceCatchOut: oneBounceCatchOut,
      noballFreeHit: noballFreeHit,
      lbwAllowed: lbwAllowed,
      maxOversPerBowler: maxOversPerBowler,
      sixIsOut: sixIsOut,
      enableMultiplayer: enableMultiplayer,
    );
  }

  List<String> _ensurePlayers(List<String> players, int count) {
    final next = List<String>.from(players);
    while (next.length < count) {
      next.add('');
    }
    if (next.length > count) {
      return next.take(count).toList();
    }
    return next;
  }
}
