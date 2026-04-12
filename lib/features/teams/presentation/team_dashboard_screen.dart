import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/match_status.dart';
import '../../scoring/domain/models/innings_model.dart';
import '../../scoring/domain/models/match_model.dart';
import '../../storage/services/match_repository.dart';
import '../domain/team_model.dart';
import '../services/teams_service.dart';

class TeamDashboardScreen extends ConsumerWidget {
  const TeamDashboardScreen({
    super.key,
    required this.teamId,
  });

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsProvider);
    TeamModel? team;
    for (final item in teams) {
      if (item.id == teamId) {
        team = item;
        break;
      }
    }
    if (team == null) {
      return const Scaffold(body: Center(child: Text('Team not found')));
    }

    final matches = ref.watch(matchListProvider);
    final related = matches
        .where((match) => match.status == MatchStatus.completed && _isTeamInvolved(match, team.name))
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));

    final scores = related
        .map((match) => _teamRunsInMatch(match, team.name))
        .whereType<int>()
        .toList(growable: false);

    final avgScore = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
    final highestScore = scores.isEmpty ? 0 : scores.reduce(math.max);

    final mostPlayedOpponent = _mostPlayedOpponent(related, team.name);
    final h2h = mostPlayedOpponent == null
        ? const _H2HRecord(wins: 0, losses: 0, ties: 0)
        : _headToHead(related, team.name, mostPlayedOpponent);

    return Scaffold(
      appBar: AppBar(title: const Text('Team Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TeamHeader(team: team),
              const SizedBox(height: 12),
              _QuickStats(
                matches: team.matchesPlayed,
                wins: team.wins,
                avgScore: avgScore,
                highestScore: highestScore,
              ),
              const SizedBox(height: 12),
              _RosterSection(team: team),
              const SizedBox(height: 12),
              _RecentMatchesSection(teamName: team.name, matches: related.take(5).toList()),
              const SizedBox(height: 12),
              _PerformanceChart(scores: scores.take(10).toList().reversed.toList()),
              const SizedBox(height: 12),
              _HeadToHeadSection(opponent: mostPlayedOpponent, record: h2h),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(team.colorHex);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[color.withOpacity(0.8), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            team.shortName?.isNotEmpty == true ? team.shortName! : team.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(team.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _badge('W ${team.wins}'),
              _badge('L ${team.losses}'),
              _badge('T ${team.ties}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              SizedBox(
                height: 54,
                width: 54,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: team.winPercentage / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.white24,
                    ),
                    Center(
                      child: Text('${team.winPercentage.toStringAsFixed(0)}%'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.matches,
    required this.wins,
    required this.avgScore,
    required this.highestScore,
  });

  final int matches;
  final int wins;
  final double avgScore;
  final int highestScore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _StatCard(title: 'Matches', value: '$matches')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'Wins', value: '$wins')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'Avg Score', value: avgScore.toStringAsFixed(1))),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'Highest', value: '$highestScore')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RosterSection extends StatelessWidget {
  const _RosterSection({required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Players (${team.playerNames.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: team.playerNames.map((player) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => context.push('/player/${Uri.encodeComponent(player)}'),
                      child: Column(
                        children: <Widget>[
                          CircleAvatar(child: Text(_initials(player))),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 72,
                            child: Text(
                              player,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/teams/create?teamId=${team.id}'),
                child: const Text('Edit Roster'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentMatchesSection extends StatelessWidget {
  const _RecentMatchesSection({required this.teamName, required this.matches});

  final String teamName;
  final List<MatchModel> matches;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Recent Matches', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (matches.isEmpty)
              const Text('No match history yet')
            else
              ...matches.map((match) {
                final won = match.winnerTeamName == teamName;
                final tied = match.winnerTeamName == null;
                final chipLabel = tied ? 'T' : (won ? 'W' : 'L');
                final opponent = match.team1Name == teamName ? match.team2Name : match.team1Name;
                final result = match.winDescription ?? (tied ? 'Match tied' : 'Completed');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Chip(label: Text(chipLabel)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('vs $opponent — $result — ${_relativeTime(match.completedAt ?? match.createdAt)}'),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _PerformanceChart extends StatelessWidget {
  const _PerformanceChart({required this.scores});

  final List<int> scores;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Performance Chart', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: scores.isEmpty
                  ? const Center(child: Text('No data yet'))
                  : LineChart(
                      LineChartData(
                        lineTouchData: const LineTouchData(enabled: false),
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: math.max(1, (scores.length / 5).floorToDouble()),
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt() + 1;
                                return Text('$index', style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        minX: 0,
                        maxX: (scores.length - 1).toDouble(),
                        minY: 0,
                        maxY: (scores.reduce(math.max) + 10).toDouble(),
                        lineBarsData: <LineChartBarData>[
                          LineChartBarData(
                            spots: scores
                                .asMap()
                                .entries
                                .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
                                .toList(),
                            isCurved: true,
                            dotData: const FlDotData(show: true),
                            barWidth: 3,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadToHeadSection extends StatelessWidget {
  const _HeadToHeadSection({required this.opponent, required this.record});

  final String? opponent;
  final _H2HRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Head to Head', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (opponent == null)
              const Text('No opponent data yet')
            else ...<Widget>[
              Text('vs $opponent'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  _badge('W ${record.wins}'),
                  _badge('L ${record.losses}'),
                  _badge('T ${record.ties}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _H2HRecord {
  const _H2HRecord({required this.wins, required this.losses, required this.ties});

  final int wins;
  final int losses;
  final int ties;
}

bool _isTeamInvolved(MatchModel match, String teamName) {
  return match.team1Name == teamName || match.team2Name == teamName;
}

int? _teamRunsInMatch(MatchModel match, String teamName) {
  final innings = <Innings?>[match.firstInnings, match.secondInnings].whereType<Innings>();
  for (final inning in innings) {
    final battingName = inning.battingTeamId == 'team1' ? match.team1Name : match.team2Name;
    if (battingName == teamName) {
      return inning.totalRuns;
    }
  }
  return null;
}

String? _mostPlayedOpponent(List<MatchModel> matches, String teamName) {
  if (matches.isEmpty) return null;
  final counts = <String, int>{};
  for (final match in matches) {
    final opponent = match.team1Name == teamName ? match.team2Name : match.team1Name;
    counts.update(opponent, (value) => value + 1, ifAbsent: () => 1);
  }
  String? result;
  var maxCount = 0;
  counts.forEach((opponent, count) {
    if (count > maxCount) {
      maxCount = count;
      result = opponent;
    }
  });
  return result;
}

_H2HRecord _headToHead(List<MatchModel> matches, String teamName, String opponent) {
  var wins = 0;
  var losses = 0;
  var ties = 0;
  for (final match in matches) {
    if (!((match.team1Name == teamName && match.team2Name == opponent) ||
        (match.team1Name == opponent && match.team2Name == teamName))) {
      continue;
    }
    if (match.winnerTeamName == null) {
      ties += 1;
    } else if (match.winnerTeamName == teamName) {
      wins += 1;
    } else {
      losses += 1;
    }
  }
  return _H2HRecord(wins: wins, losses: losses, ties: ties);
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}

Widget _badge(String text) {
  return Chip(label: Text(text));
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final argb = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.tryParse(argb, radix: 16) ?? 0xFF2E7D32);
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
