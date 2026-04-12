import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/match_status.dart';
import '../../../core/constants/hive_keys.dart';
import '../../scoring/domain/models/match_model.dart';
import '../domain/team_model.dart';

class TeamMatchSummary {
  const TeamMatchSummary({
    required this.team,
    required this.matches,
    required this.lastPlayedAt,
  });

  final TeamModel team;
  final List<MatchModel> matches;
  final DateTime? lastPlayedAt;
}

class TeamsService {
  Box<TeamModel> get _box => Hive.box<TeamModel>(HiveKeys.teamsBox);

  List<TeamModel> getAllTeams() {
    final teams = _box.values.toList();
    teams.sort(_sortTeams);
    return teams;
  }

  TeamModel? getTeamById(String id) => _box.get(id);

  Future<bool> saveTeam(TeamModel team) async {
    final name = team.name.trim();
    if (name.isEmpty) return false;
    final duplicate = _box.values.any(
      (item) => item.id != team.id && item.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) return false;
    await _box.put(team.id, team);
    return true;
  }

  Future<void> deleteTeam(String id) async {
    await _box.delete(id);
  }

  Future<void> toggleFavorite(String id) async {
    final team = _box.get(id);
    if (team == null) return;
    await _box.put(id, team.copyWith(isFavorite: !team.isFavorite));
  }

  Future<void> refreshStatsFromMatches(List<MatchModel> matches) async {
    final completed = matches
        .where((match) => match.status == MatchStatus.completed)
        .toList(growable: false);
    for (final team in _box.values) {
      var played = 0;
      var wins = 0;
      var losses = 0;
      var ties = 0;
      for (final match in completed) {
        final involved = match.team1Name == team.name || match.team2Name == team.name;
        if (!involved) continue;
        played += 1;
        if (match.winnerTeamName == null) {
          ties += 1;
        } else if (match.winnerTeamName == team.name) {
          wins += 1;
        } else {
          losses += 1;
        }
      }
      final updated = team.copyWith(matchesPlayed: played, wins: wins, losses: losses, ties: ties);
      await _box.put(team.id, updated);
    }
  }

  TeamMatchSummary summaryForTeam(TeamModel team, List<MatchModel> matches) {
    final related = matches
        .where(
          (match) =>
              match.status == MatchStatus.completed &&
              (match.team1Name == team.name || match.team2Name == team.name),
        )
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));

    final lastPlayedAt = related.isEmpty ? null : (related.first.completedAt ?? related.first.createdAt);
    return TeamMatchSummary(team: team, matches: related, lastPlayedAt: lastPlayedAt);
  }

  int _sortTeams(TeamModel a, TeamModel b) {
    if (a.isFavorite && !b.isFavorite) return -1;
    if (!a.isFavorite && b.isFavorite) return 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}

final teamsServiceProvider = Provider<TeamsService>((_) => TeamsService());

final teamsProvider = StateNotifierProvider<TeamsNotifier, List<TeamModel>>((ref) {
  final service = ref.watch(teamsServiceProvider);
  return TeamsNotifier(service);
});

class TeamsNotifier extends StateNotifier<List<TeamModel>> {
  TeamsNotifier(this._service) : super(const <TeamModel>[]) {
    _listenable = Hive.box<TeamModel>(HiveKeys.teamsBox).listenable();
    _listenable.addListener(_reload);
    _reload();
  }

  final TeamsService _service;
  late final ValueListenable<Box<TeamModel>> _listenable;

  void _reload() {
    state = _service.getAllTeams();
  }

  TeamModel? getTeamById(String id) => _service.getTeamById(id);

  Future<bool> saveTeam(TeamModel team) async {
    final saved = await _service.saveTeam(team);
    return saved;
  }

  Future<void> deleteTeam(String id) async {
    await _service.deleteTeam(id);
  }

  Future<void> toggleFavorite(String id) async {
    await _service.toggleFavorite(id);
  }

  Future<void> syncStatsWithMatches(List<MatchModel> matches) async {
    await _service.refreshStatsFromMatches(matches);
  }

  TeamMatchSummary summaryForTeam(TeamModel team, List<MatchModel> matches) {
    return _service.summaryForTeam(team, matches);
  }

  @override
  void dispose() {
    _listenable.removeListener(_reload);
    super.dispose();
  }
}
