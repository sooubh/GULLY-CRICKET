import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/match_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../scoring/domain/models/ball_model.dart';
import '../../scoring/domain/models/innings_model.dart';
import '../../scoring/domain/models/match_model.dart';
import '../../stats/domain/player_stats_model.dart';
import '../../stats/providers/stats_providers.dart';
import '../../storage/services/match_repository.dart';
import '../domain/saved_player_model.dart';
import '../services/saved_players_service.dart';

class PlayerDashboardScreen extends ConsumerWidget {
  const PlayerDashboardScreen({
    super.key,
    required this.playerName,
  });

  final String playerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(playerStatsProvider(playerName));
    final savedPlayers = ref.watch(savedPlayersProvider);
    final allMatches = ref.watch(matchListProvider);

    final completedMatches = allMatches
        .where((match) => match.status == MatchStatus.completed)
        .toList(growable: false)
      ..sort((a, b) => (a.completedAt ?? a.createdAt).compareTo(b.completedAt ?? b.createdAt));

    final analysis = _PlayerAnalysis.build(playerName: playerName, matches: completedMatches);
    final savedPlayer = savedPlayers.where((p) => p.name == playerName).firstOrNull;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Player Profile')),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _PlayerHeader(
                          playerName: playerName,
                          stats: stats,
                          analysis: analysis,
                          savedPlayer: savedPlayer,
                        ),
                      ),
                    ),
                    const SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabHeaderDelegate(),
                    ),
                  ],
                  body: TabBarView(
                    children: <Widget>[
                      _BattingTab(stats: stats, analysis: analysis),
                      _BowlingTab(stats: stats, analysis: analysis),
                      _CareerTab(stats: stats, analysis: analysis),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({
    required this.playerName,
    required this.stats,
    required this.analysis,
    required this.savedPlayer,
  });

  final String playerName;
  final PlayerStats stats;
  final _PlayerAnalysis analysis;
  final SavedPlayer? savedPlayer;

  @override
  Widget build(BuildContext context) {
    final teamColor = _teamColor(analysis.lastTeamName);
    final lastPlayed = analysis.lastPlayedAt == null ? 'Never' : _relativeTime(analysis.lastPlayedAt!);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: <Color>[teamColor.withOpacity(0.9), teamColor.withOpacity(0.45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.black26,
            child: Text(_initials(playerName), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(
            playerName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: <Widget>[
              Text(savedPlayer?.isFavorite == true ? '⭐ Favorite' : '☆ Player'),
              Text('🏏 ${_roleLabel(stats)}'),
            ],
          ),
          const SizedBox(height: 4),
          Text('Last played: $lastPlayed'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _smallBadge('${stats.matches} matches'),
              _smallBadge('Team: ${analysis.lastTeamName ?? '-'}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TabHeaderDelegate();

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const TabBar(
        tabs: <Tab>[
          Tab(text: '🏏 Batting'),
          Tab(text: '🎯 Bowling'),
          Tab(text: '📊 Career'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _BattingTab extends StatelessWidget {
  const _BattingTab({required this.stats, required this.analysis});

  final PlayerStats stats;
  final _PlayerAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final formEntries = analysis.battingInnings.takeLast(5);
    final bars = analysis.battingInnings.takeLast(10);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: <Widget>[
        _StatsGrid(
          items: <_StatItem>[
            _StatItem(label: 'Runs', value: '${stats.totalRuns}'),
            _StatItem(label: 'Avg', value: stats.battingAverage.toStringAsFixed(1)),
            _StatItem(label: 'SR', value: stats.strikeRate.toStringAsFixed(0)),
            _StatItem(label: 'HS', value: '${stats.highScore}'),
            _StatItem(label: '50s', value: '${stats.fifties}'),
            _StatItem(label: '100s', value: '${stats.hundreds}'),
            _StatItem(label: '4s', value: '${stats.fours}'),
            _StatItem(label: '6s', value: '${stats.sixes}'),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Recent form: ${formEntries.isEmpty ? '-' : formEntries.map((e) => e.displayScore).join(' · ')}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: formEntries
                      .map(
                        (entry) => Chip(
                          label: Text(entry.displayScore),
                          backgroundColor: _scoreColor(entry.runs).withOpacity(0.20),
                          labelStyle: TextStyle(color: _scoreColor(entry.runs), fontWeight: FontWeight.w700),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _BattingBars(entries: bars),
      ],
    );
  }
}

class _BowlingTab extends StatelessWidget {
  const _BowlingTab({required this.stats, required this.analysis});

  final PlayerStats stats;
  final _PlayerAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final overs = stats.ballsBowled / standardBallsPerOver;
    final wicketsBars = analysis.matchSummaries.takeLast(10);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: <Widget>[
        _StatsGrid(
          items: <_StatItem>[
            _StatItem(label: 'Wkt', value: '${stats.wickets}'),
            _StatItem(label: 'Eco', value: stats.economy.toStringAsFixed(1)),
            _StatItem(label: 'Avg', value: stats.bowlingAverage.toStringAsFixed(1)),
            _StatItem(label: 'Best', value: stats.bestBowling),
            _StatItem(label: 'Overs', value: overs.toStringAsFixed(1)),
            _StatItem(label: 'Runs', value: '${stats.runsConceded}'),
            _StatItem(label: 'Maid', value: '${stats.maidens}'),
            _StatItem(label: '5Wkt', value: '${stats.fiveWicketHauls}'),
          ],
        ),
        const SizedBox(height: 12),
        _WicketBars(entries: wicketsBars),
      ],
    );
  }
}

class _CareerTab extends StatelessWidget {
  const _CareerTab({required this.stats, required this.analysis});

  final PlayerStats stats;
  final _PlayerAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Matches: ${stats.matches}  |  Won: ${stats.wins}  |  Win %: ${stats.winPercentage.toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                const Text('Teams played for:'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: analysis.teamsPlayedFor
                      .map((team) => Chip(label: Text(team)))
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('All-time innings', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 12,
                    headingRowHeight: 34,
                    dataRowMinHeight: 34,
                    dataRowMaxHeight: 42,
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Match')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Runs')),
                      DataColumn(label: Text('Balls')),
                      DataColumn(label: Text('SR')),
                      DataColumn(label: Text('Wickets')),
                      DataColumn(label: Text('How Out')),
                    ],
                    rows: analysis.battingInnings
                        .map(
                          (inn) => DataRow(
                            cells: <DataCell>[
                              DataCell(Text('vs ${inn.opponent}', overflow: TextOverflow.ellipsis)),
                              DataCell(Text(DateFormat('dd MMM yyyy').format(inn.date))),
                              DataCell(Text(inn.displayScore)),
                              DataCell(Text('${inn.balls}')),
                              DataCell(Text(inn.strikeRate.toStringAsFixed(1))),
                              DataCell(Text('${inn.matchWickets}')),
                              DataCell(Text(inn.howOut)),
                            ],
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Milestones', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(analysis.firstFiftyText ?? '🏆 First fifty — Not yet achieved'),
                const SizedBox(height: 6),
                Text(analysis.firstFiveWicketText ?? '🎯 First 5-wicket haul — Not yet achieved'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BattingBars extends StatelessWidget {
  const _BattingBars({required this.entries});

  final List<_BattingInningsEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Runs per match (last 10)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: entries.isEmpty
                  ? const Center(child: Text('No batting data yet'))
                  : BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt() + 1}', style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        barGroups: entries
                            .asMap()
                            .entries
                            .map(
                              (entry) => BarChartGroupData(
                                x: entry.key,
                                barRods: <BarChartRodData>[
                                  BarChartRodData(
                                    toY: entry.value.runs.toDouble(),
                                    color: _scoreColor(entry.value.runs),
                                    width: 14,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                            )
                            .toList(growable: false),
                        maxY: math.max(10, entries.map((e) => e.runs).fold<int>(0, math.max) + 10).toDouble(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WicketBars extends StatelessWidget {
  const _WicketBars({required this.entries});

  final List<_MatchSummaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Wickets per match (last 10)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: entries.isEmpty
                  ? const Center(child: Text('No bowling data yet'))
                  : BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt() + 1}', style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        barGroups: entries
                            .asMap()
                            .entries
                            .map(
                              (entry) => BarChartGroupData(
                                x: entry.key,
                                barRods: <BarChartRodData>[
                                  BarChartRodData(
                                    toY: entry.value.wickets.toDouble(),
                                    color: AppColors.primaryGreen,
                                    width: 14,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                            )
                            .toList(growable: false),
                        maxY: math.max(2, entries.map((e) => e.wickets).fold<int>(0, math.max) + 1).toDouble(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(item.label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(item.value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _PlayerAnalysis {
  const _PlayerAnalysis({
    required this.battingInnings,
    required this.matchSummaries,
    required this.teamsPlayedFor,
    required this.lastPlayedAt,
    required this.lastTeamName,
    required this.firstFiftyText,
    required this.firstFiveWicketText,
  });

  final List<_BattingInningsEntry> battingInnings;
  final List<_MatchSummaryEntry> matchSummaries;
  final List<String> teamsPlayedFor;
  final DateTime? lastPlayedAt;
  final String? lastTeamName;
  final String? firstFiftyText;
  final String? firstFiveWicketText;

  factory _PlayerAnalysis.build({required String playerName, required List<MatchModel> matches}) {
    final battingInnings = <_BattingInningsEntry>[];
    final matchSummaries = <_MatchSummaryEntry>[];
    final teams = <String>{};

    String? firstFiftyText;
    String? firstFiveWicketText;
    DateTime? lastPlayed;
    String? lastTeam;

    for (final match in matches) {
      final teamInfo = _playerTeamInfo(match, playerName);
      if (teamInfo == null) {
        continue;
      }

      final date = match.completedAt ?? match.createdAt;
      if (lastPlayed == null || date.isAfter(lastPlayed)) {
        lastPlayed = date;
        lastTeam = teamInfo.teamName;
      }
      teams.add(teamInfo.teamName);

      var wicketsInMatch = 0;
      final inningsList = <Innings?>[match.firstInnings, match.secondInnings];

      for (final innings in inningsList.whereType<Innings>()) {
        final playerIds = teamInfo.playerIds;
        final battingSideName = innings.battingTeamId == 'team1' ? match.team1Name : match.team2Name;

        if (battingSideName == teamInfo.teamName) {
          final balls = innings.allBalls.where((ball) => playerIds.contains(ball.batsmanId)).toList();
          final dismissBall = innings.allBalls.where((ball) => ball.isWicket).firstWhereOrNull(
                (ball) => playerIds.contains(ball.dismissedPlayerId ?? ball.batsmanId),
              );
          final played = balls.isNotEmpty || dismissBall != null;
          if (played) {
            final runs = balls.fold<int>(0, (sum, ball) => sum + _battingRuns(ball));
            final faced = balls.where((ball) => ball.isLegalBall).length;
            final strikeRate = faced == 0 ? 0.0 : (runs / faced) * 100;
            final notOut = dismissBall == null;
            final howOut = notOut ? 'Not out' : _dismissalLabel(dismissBall!);
            final opponent = teamInfo.opponent;
            final wicketsInInnings = innings.allBalls
                .where((ball) => playerIds.contains(ball.bowlerId) && ball.isWicket && ball.wicketType != 'run_out')
                .length;
            wicketsInMatch += wicketsInInnings;

            final entry = _BattingInningsEntry(
              date: date,
              opponent: opponent,
              runs: runs,
              balls: faced,
              strikeRate: strikeRate,
              notOut: notOut,
              howOut: howOut,
              matchWickets: 0,
            );
            battingInnings.add(entry);

            if (firstFiftyText == null && runs >= 50) {
              firstFiftyText = '🏆 First fifty — Match vs $opponent — ${DateFormat('dd MMM yyyy').format(date)}';
            }
          }
        } else {
          final wicketsInInnings = innings.allBalls
              .where((ball) => teamInfo.playerIds.contains(ball.bowlerId) && ball.isWicket && ball.wicketType != 'run_out')
              .length;
          wicketsInMatch += wicketsInInnings;
        }
      }

      matchSummaries.add(
        _MatchSummaryEntry(
          date: date,
          opponent: teamInfo.opponent,
          wickets: wicketsInMatch,
        ),
      );
      if (firstFiveWicketText == null && wicketsInMatch >= 5) {
        firstFiveWicketText =
            '🎯 First 5-wicket haul — Match vs ${teamInfo.opponent} — ${DateFormat('dd MMM yyyy').format(date)}';
      }
    }

    battingInnings.sort((a, b) => a.date.compareTo(b.date));
    matchSummaries.sort((a, b) => a.date.compareTo(b.date));

    // Backfill match wickets per batting innings by match date/opponent proximity.
    final summaryByDateOpponent = <String, int>{
      for (final summary in matchSummaries) '${summary.date.toIso8601String()}_${summary.opponent}': summary.wickets,
    };
    final battingWithWickets = battingInnings
        .map(
          (entry) => entry.copyWith(
            matchWickets: summaryByDateOpponent['${entry.date.toIso8601String()}_${entry.opponent}'] ?? 0,
          ),
        )
        .toList(growable: false);

    return _PlayerAnalysis(
      battingInnings: battingWithWickets,
      matchSummaries: matchSummaries,
      teamsPlayedFor: teams.toList(growable: false),
      lastPlayedAt: lastPlayed,
      lastTeamName: lastTeam,
      firstFiftyText: firstFiftyText,
      firstFiveWicketText: firstFiveWicketText,
    );
  }
}

class _PlayerTeamInfo {
  const _PlayerTeamInfo({
    required this.teamName,
    required this.opponent,
    required this.playerIds,
  });

  final String teamName;
  final String opponent;
  final Set<String> playerIds;
}

_PlayerTeamInfo? _playerTeamInfo(MatchModel match, String playerName) {
  final team1Ids = match.team1Players.where((p) => p.name == playerName).map((p) => p.id).toSet();
  final team2Ids = match.team2Players.where((p) => p.name == playerName).map((p) => p.id).toSet();

  if (team1Ids.isNotEmpty) {
    return _PlayerTeamInfo(teamName: match.team1Name, opponent: match.team2Name, playerIds: team1Ids);
  }
  if (team2Ids.isNotEmpty) {
    return _PlayerTeamInfo(teamName: match.team2Name, opponent: match.team1Name, playerIds: team2Ids);
  }
  return null;
}

int _battingRuns(Ball ball) {
  if (ball.isWide || ball.isBye || ball.isLegBye) {
    return 0;
  }
  return ball.runsScored;
}

String _dismissalLabel(Ball ball) {
  final type = ball.wicketType;
  if (type == null || type.isEmpty) {
    return 'Out';
  }
  return type.replaceAll('_', ' ');
}

class _BattingInningsEntry {
  const _BattingInningsEntry({
    required this.date,
    required this.opponent,
    required this.runs,
    required this.balls,
    required this.strikeRate,
    required this.notOut,
    required this.howOut,
    required this.matchWickets,
  });

  final DateTime date;
  final String opponent;
  final int runs;
  final int balls;
  final double strikeRate;
  final bool notOut;
  final String howOut;
  final int matchWickets;

  String get displayScore => notOut ? '$runs*' : '$runs';

  _BattingInningsEntry copyWith({int? matchWickets}) {
    return _BattingInningsEntry(
      date: date,
      opponent: opponent,
      runs: runs,
      balls: balls,
      strikeRate: strikeRate,
      notOut: notOut,
      howOut: howOut,
      matchWickets: matchWickets ?? this.matchWickets,
    );
  }
}

class _MatchSummaryEntry {
  const _MatchSummaryEntry({
    required this.date,
    required this.opponent,
    required this.wickets,
  });

  final DateTime date;
  final String opponent;
  final int wickets;
}

Widget _smallBadge(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: Colors.black26,
    ),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}

String _roleLabel(PlayerStats stats) {
  if (stats.totalRuns >= 150 && stats.wickets >= 8) {
    return 'All-rounder';
  }
  if (stats.wickets >= stats.matches && stats.wickets > 0) {
    return 'Bowler';
  }
  if (stats.totalRuns > 0) {
    return 'Batter';
  }
  return 'Player';
}

Color _teamColor(String? teamName) {
  final key = (teamName ?? '').toLowerCase();
  if (key.contains('green')) return AppColors.primaryGreen;
  if (key.contains('blue')) return const Color(0xFF1565C0);
  if (key.contains('red')) return const Color(0xFFC62828);
  if (key.contains('orange')) return const Color(0xFFEF6C00);
  if (key.contains('purple')) return const Color(0xFF6A1B9A);
  if (key.contains('yellow')) return const Color(0xFFF9A825);
  if (key.contains('pink')) return const Color(0xFFD81B60);
  if (key.contains('cyan')) return const Color(0xFF00838F);
  return AppColors.darkGreen;
}

Color _scoreColor(int score) {
  if (score == 0) return Colors.red;
  if (score <= 15) return Colors.orange;
  if (score <= 29) return Colors.yellow.shade700;
  if (score <= 49) return Colors.lightGreen;
  return Colors.greenAccent.shade400;
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) {
    return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
  }
  if (diff.inHours > 0) {
    return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
  }
  if (diff.inMinutes > 0) {
    return diff.inMinutes == 1 ? '1 minute ago' : '${diff.inMinutes} minutes ago';
  }
  return 'Just now';
}

extension _IterableFirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}

extension _TakeLastExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count <= 0 || isEmpty) return <T>[];
    if (length <= count) return List<T>.from(this);
    return sublist(length - count);
  }
}
