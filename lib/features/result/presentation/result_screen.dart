import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/match_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../ads/ad_service.dart';
import '../../ads/widgets/banner_ad_widget.dart';
import '../../audio/sound_service.dart';
import '../../scoring/domain/models/ball_model.dart';
import '../../scoring/domain/models/innings_model.dart';
import '../../scoring/domain/models/match_model.dart';
import '../../scoring/domain/models/player_model.dart';
import '../../scoring/presentation/active_match_provider.dart';
import '../../storage/services/match_repository.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    this.matchOverride,
    this.readOnly = false,
  });

  final MatchModel? matchOverride;
  final bool readOnly;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(adServiceProvider).showInterstitial();
      if (!widget.readOnly) {
        await ref.read(soundServiceProvider).playCrowd();
      }
    });
  }

  Future<void> _startNewMatch() async {
    ref.read(activeMatchProvider.notifier).clearMatch();
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _rematch(MatchModel source) async {
    final team1 = source.team1Players
        .asMap()
        .entries
        .map(
          (entry) => Player(
            id: const Uuid().v4(),
            name: entry.value.name,
            teamId: 'team1',
            battingPosition: entry.key + 1,
          ),
        )
        .toList();
    final team2 = source.team2Players
        .asMap()
        .entries
        .map(
          (entry) => Player(
            id: const Uuid().v4(),
            name: entry.value.name,
            teamId: 'team2',
            battingPosition: entry.key + 1,
          ),
        )
        .toList();
    final rematch = MatchModel(
      id: const Uuid().v4(),
      team1Name: source.team1Name,
      team2Name: source.team2Name,
      team1Players: team1,
      team2Players: team2,
      rules: source.rules,
      status: MatchStatus.liveFirstInnings,
      tossWinnerTeamName: source.tossWinnerTeamName,
      tossDecision: source.tossDecision,
      battingFirstTeamId: source.battingFirstTeamId,
    );
    await ref.read(matchListProvider.notifier).saveMatch(rematch);
    await ref.read(activeMatchProvider.notifier).setMatch(rematch);
    if (!mounted) return;
    context.go('/live');
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.matchOverride ?? ref.watch(activeMatchProvider);
    if (match == null) {
      return const Scaffold(body: Center(child: Text('No result available')));
    }
    final topScorer = _topScorer(match);
    final bestBowler = _bestBowler(match);
    final innings = <Innings?>[match.firstInnings, match.secondInnings];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _WinBanner(match: match),
                    const SizedBox(height: 12),
                    _SummaryCard(match: match),
                    const SizedBox(height: 12),
                    _PotmCard(topScorer: topScorer, bestBowler: bestBowler),
                    const SizedBox(height: 12),
                    _ScorecardExpansion(match: match, innings: innings),
                    const SizedBox(height: 16),
                    if (!widget.readOnly) ...<Widget>[
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _startNewMatch,
                          child: const Text('🏏 New Match'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => _rematch(match),
                          child: const Text('🔁 Rematch'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('🏠 Home'),
                        ),
                      ),
                    ] else
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Back'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(top: false, child: BannerAdWidget()),
    );
  }
}

class _WinBanner extends StatelessWidget {
  const _WinBanner({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final description = match.winDescription ?? 'Match completed';
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.darkGreen, Colors.black],
          ),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 16,
              left: 18,
              child: const Text('✨', style: TextStyle(fontSize: 18))
                  .animate(onPlay: (controller) => controller.repeat())
                  .moveY(begin: 0, end: -6, duration: 1200.ms)
                  .then()
                  .moveY(begin: -6, end: 0, duration: 1200.ms),
            ),
            Positioned(
              top: 42,
              right: 24,
              child: const Text('🎉', style: TextStyle(fontSize: 16))
                  .animate(onPlay: (controller) => controller.repeat())
                  .moveY(begin: 0, end: -10, duration: 1100.ms)
                  .then()
                  .moveY(begin: -10, end: 0, duration: 900.ms),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text('🏆', style: TextStyle(fontSize: 64))
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                          duration: 650.ms,
                        ),
                    const SizedBox(height: 8),
                    Text(
                      match.winnerTeamName ?? 'Match Tied',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 48,
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w700,
                          ),
                    ).animate().shimmer(color: AppColors.accentGold, duration: 900.ms),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().shimmer(color: Colors.white24, duration: 1200.ms),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final first = match.firstInnings;
    final second = match.secondInnings;
    final formatDate = DateFormat('dd MMM yyyy, hh:mm a').format(match.completedAt ?? match.createdAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _summaryRow(
              context,
              match.team1Name,
              first == null ? '-' : '${first.score} in ${_oversText(first, match.rules.ballsPerOver)}',
            ),
            const SizedBox(height: 8),
            _summaryRow(
              context,
              match.team2Name,
              second == null ? '-' : '${second.score} in ${_oversText(second, match.rules.ballsPerOver)}',
            ),
            const Divider(height: 20),
            Text('Match type: ${match.rules.totalOvers} overs per side'),
            const SizedBox(height: 4),
            Text('Date: $formatDate'),
          ],
        ),
      ),
    );
  }
}

class _PotmCard extends StatelessWidget {
  const _PotmCard({
    required this.topScorer,
    required this.bestBowler,
  });

  final Player? topScorer;
  final Player? bestBowler;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Player of the Match', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              'Highest scorer: ${topScorer?.name ?? '-'} | ${topScorer?.runsScored ?? 0}(${topScorer?.ballsFaced ?? 0}) | SR ${(topScorer?.strikeRate ?? 0).toStringAsFixed(1)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Best bowler: ${bestBowler?.name ?? '-'} | ${bestBowler?.wicketsTaken ?? 0}/${bestBowler?.runsConceded ?? 0} | Eco ${(bestBowler?.economy ?? 0).toStringAsFixed(1)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorecardExpansion extends StatelessWidget {
  const _ScorecardExpansion({
    required this.match,
    required this.innings,
  });

  final MatchModel match;
  final List<Innings?> innings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text('View Full Scorecard ▼'),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: innings.whereType<Innings>().map((inn) {
          final batting = inn.battingTeamId == 'team1' ? match.team1Players : match.team2Players;
          final bowling = inn.bowlingTeamId == 'team1' ? match.team1Players : match.team2Players;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Divider(),
              Text(
                '${inn.battingTeamId == 'team1' ? match.team1Name : match.team2Name} Innings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 32,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 40,
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('R')),
                    DataColumn(label: Text('B')),
                    DataColumn(label: Text('4s')),
                    DataColumn(label: Text('6s')),
                    DataColumn(label: Text('SR')),
                    DataColumn(label: Text('Dismissal')),
                  ],
                  rows: batting
                      .where((p) => p.ballsFaced > 0 || p.isOut || p.isRetired || p.runsScored > 0)
                      .map(
                        (p) => DataRow(
                          cells: <DataCell>[
                            DataCell(Text(p.name)),
                            DataCell(Text('${p.runsScored}')),
                            DataCell(Text('${p.ballsFaced}')),
                            DataCell(Text('${_boundaryCount(inn, p.id, 4)}')),
                            DataCell(Text('${_boundaryCount(inn, p.id, 6)}')),
                            DataCell(Text(p.strikeRate.toStringAsFixed(1))),
                            DataCell(Text(_dismissalText(match, p))),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 32,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 40,
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('O')),
                    DataColumn(label: Text('M')),
                    DataColumn(label: Text('R')),
                    DataColumn(label: Text('W')),
                    DataColumn(label: Text('Eco')),
                  ],
                  rows: bowling
                      .where((p) => p.oversBowled > 0 || p.runsConceded > 0 || p.wicketsTaken > 0)
                      .map(
                        (p) {
                          final figures = _bowlerFigures(inn, match, p.id);
                          return DataRow(
                            cells: <DataCell>[
                              DataCell(Text(p.name)),
                              DataCell(Text(figures.oversText)),
                              DataCell(Text('${figures.maidens}')),
                              DataCell(Text('${figures.runs}')),
                              DataCell(Text('${figures.wickets}')),
                              DataCell(Text(figures.economy.toStringAsFixed(1))),
                            ],
                          );
                        },
                      )
                      .toList(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

String _oversText(Innings innings, int ballsPerOver) {
  final balls = innings.legalBallsCount();
  return '${balls ~/ ballsPerOver}.${balls % ballsPerOver}';
}

Widget _summaryRow(BuildContext context, String teamName, String summary) {
  return Row(
    children: <Widget>[
      Expanded(
        child: Text(
          teamName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      Text(summary),
    ],
  );
}

Player? _topScorer(MatchModel match) {
  final players = <Player>[...match.team1Players, ...match.team2Players];
  if (players.isEmpty) return null;
  players.sort((a, b) => b.runsScored.compareTo(a.runsScored));
  return players.first;
}

Player? _bestBowler(MatchModel match) {
  final players = <Player>[...match.team1Players, ...match.team2Players];
  if (players.isEmpty) return null;
  players.sort((a, b) {
    final byWickets = b.wicketsTaken.compareTo(a.wicketsTaken);
    if (byWickets != 0) return byWickets;
    return a.runsConceded.compareTo(b.runsConceded);
  });
  return players.first;
}

int _boundaryCount(Innings innings, String playerId, int runs) {
  return innings.allBalls
      .where(
        (ball) =>
            ball.batsmanId == playerId &&
            !ball.isWide &&
            !ball.isBye &&
            !ball.isLegBye &&
            ball.runsScored == runs,
      )
      .length;
}

String _dismissalText(MatchModel match, Player player) {
  if (player.isRetiredHurt) return 'Retired hurt';
  if (player.isRetired) return 'Retired';
  if (!player.isOut) return 'Not out';
  final bowler = [...match.team1Players, ...match.team2Players]
      .firstWhere(
        (p) => p.id == player.dismissedBy,
        orElse: () => Player(id: '', name: '', teamId: ''),
      )
      .name;
  if (player.wicketType == null || player.wicketType!.isEmpty) return 'Out';
  return ' ${player.wicketType} ${bowler.isEmpty ? '' : 'b $bowler'}'.trim();
}

_BowlerFigures _bowlerFigures(Innings innings, MatchModel match, String? bowlerId) {
  if (bowlerId == null) {
    return const _BowlerFigures(
      oversText: '0.0',
      maidens: 0,
      runs: 0,
      wickets: 0,
      economy: 0,
    );
  }

  final bowlerOvers = innings.overs.where((o) => o.bowlerId == bowlerId && o.balls.isNotEmpty).toList();
  final legalBalls = bowlerOvers.fold<int>(0, (sum, over) => sum + over.legalBallCount);
  final runs = bowlerOvers.fold<int>(0, (sum, over) => sum + over.runsInOver);
  final wickets = bowlerOvers.fold<int>(0, (sum, over) => sum + over.wicketsInOver);
  final maidens = bowlerOvers
      .where((over) => over.isComplete(match.rules.ballsPerOver) && over.runsInOver == 0)
      .length;
  final oversText = '${legalBalls ~/ match.rules.ballsPerOver}.${legalBalls % match.rules.ballsPerOver}';
  final economy = legalBalls == 0 ? 0.0 : (runs / legalBalls) * match.rules.ballsPerOver;
  return _BowlerFigures(
    oversText: oversText,
    maidens: maidens,
    runs: runs,
    wickets: wickets,
    economy: economy,
  );
}

class _BowlerFigures {
  const _BowlerFigures({
    required this.oversText,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });

  final String oversText;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;
}
