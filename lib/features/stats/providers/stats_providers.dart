import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scoring/domain/models/match_model.dart';
import '../../storage/services/match_repository.dart';
import '../domain/player_stats_model.dart';
import '../domain/stats_reports_model.dart';
import '../services/stats_calculator.dart';

final statsCalculatorProvider = Provider<StatsCalculator>((_) => const StatsCalculator());

final playerStatsProvider = Provider.family<PlayerStats, String>((ref, playerName) {
  final allMatches = ref.watch(matchListProvider);
  return ref.watch(statsCalculatorProvider).calculateForPlayer(playerName, allMatches);
});

final teamStatsProvider = Provider.family<List<PlayerStats>, String>((ref, teamName) {
  final allMatches = ref.watch(matchListProvider);
  return ref.watch(statsCalculatorProvider).calculateForTeam(teamName, allMatches);
});

final matchStatsReportProvider = Provider.family<MatchStatsReport, MatchModel>((ref, match) {
  return ref.watch(statsCalculatorProvider).calculateMatchReport(match);
});

class H2HQuery {
  const H2HQuery({
    required this.team1,
    required this.team2,
  });

  final String team1;
  final String team2;
}

final headToHeadProvider = Provider.family<HeadToHead, H2HQuery>((ref, query) {
  final allMatches = ref.watch(matchListProvider);
  return ref.watch(statsCalculatorProvider).calculateH2H(query.team1, query.team2, allMatches);
});
