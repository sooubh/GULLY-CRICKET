import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../ads/widgets/banner_ad_widget.dart';
import '../../scoring/domain/models/ball_model.dart';
import '../../scoring/domain/models/innings_model.dart';
import '../../scoring/domain/models/match_model.dart';
import '../../scoring/domain/models/over_model.dart';
import '../../scoring/domain/models/player_model.dart';
import '../../scoring/presentation/active_match_provider.dart';
import '../../stats/domain/stats_reports_model.dart';
import '../../stats/providers/stats_providers.dart';
import '../../storage/services/match_repository.dart';

class MatchReportScreen extends ConsumerStatefulWidget {
  const MatchReportScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<MatchReportScreen> createState() => _MatchReportScreenState();
}

class _MatchReportScreenState extends ConsumerState<MatchReportScreen> {
  String _selectedOverTeam = 'team1';

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(matchListProvider);
    final match = matches.firstWhereOrNull((m) => m.id == widget.matchId);
    if (match == null) {
      return const Scaffold(body: Center(child: Text('Match not found')));
    }

    final report = ref.watch(matchStatsReportProvider(match));
    final first = match.firstInnings;
    final second = match.secondInnings;

    final firstReport = first == null ? null : _InningsReportData.fromMatch(match, first);
    final secondReport = second == null ? null : _InningsReportData.fromMatch(match, second);

    final selectedInnings = _selectedOverTeam == 'team1'
        ? (first?.battingTeamId == 'team1' ? first : second)
        : (first?.battingTeamId == 'team2' ? first : second);

    final topScorer = _topScorer(firstReport, secondReport);
    final bestBowler = _bestBowler(firstReport, secondReport);
    final bestOver = _bestOver(match, first, second);
    final bestPartnership = report.partnerships.isEmpty
        ? null
        : (report.partnerships.toList()..sort((a, b) => b.runs.compareTo(a.runs))).first;

    return Scaffold(
      appBar: AppBar(title: const Text('Match Report')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildMatchHeader(match),
              const SizedBox(height: 12),
              if (first != null || second != null) _buildMiniScorecard(match, first, second),
              if (firstReport != null) ...<Widget>[
                const SizedBox(height: 12),
                _buildBattingSection(firstReport),
                const SizedBox(height: 12),
                _buildBowlingSection(firstReport),
              ],
              if (secondReport != null) ...<Widget>[
                const SizedBox(height: 12),
                _buildBattingSection(secondReport),
                const SizedBox(height: 12),
                _buildBowlingSection(secondReport),
              ],
              if (selectedInnings != null) ...<Widget>[
                const SizedBox(height: 12),
                _buildOverByOver(match, selectedInnings),
              ],
              const SizedBox(height: 12),
              _buildHighlights(topScorer, bestBowler, bestOver, bestPartnership),
              const SizedBox(height: 12),
              _buildRunRateChart(match, first, second),
              const SizedBox(height: 12),
              _buildWormChart(match, first, second),
              const SizedBox(height: 12),
              _buildShareButton(match, firstReport, secondReport),
              const SizedBox(height: 12),
              _buildBottomButtons(match, firstReport, secondReport),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(top: false, child: BannerAdWidget()),
    );
  }

  Widget _buildMatchHeader(MatchModel match) {
    final dateText = DateFormat('dd MMM yyyy').format(match.completedAt ?? match.createdAt);
    final result = match.winnerTeamName == null
        ? '🏆 MATCH TIED'
        : '🏆 ${match.winnerTeamName!.toUpperCase()} ${match.winDescription?.toUpperCase() ?? 'WON'}';

    return Card(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: <Color>[AppColors.darkGreen, Color(0xFF0F2A13)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${match.team1Name} vs ${match.team2Name}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('COMPLETED', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
            ),
            const SizedBox(height: 8),
            Text('Date: $dateText · ${match.rules.totalOvers} Overs · Gully Rules'),
            const SizedBox(height: 2),
            const Text('Venue: —'),
            const SizedBox(height: 14),
            Center(
              child: Text(
                result,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniScorecard(MatchModel match, Innings? first, Innings? second) {
    String scoreLine(Innings? innings) {
      if (innings == null) return '-';
      final overs = _oversText(innings.legalBallsCount(), match.rules.ballsPerOver);
      final allOut = innings.wickets >= _battingTeam(match, innings).length - 1;
      return '${innings.totalRuns}/${innings.wickets}${allOut ? ' all out' : ''} ($overs ov)';
    }

    final teamAInnings = first?.battingTeamId == 'team1' ? first : second;
    final teamBInnings = first?.battingTeamId == 'team2' ? first : second;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            _miniScoreRow(match.team1Name, scoreLine(teamAInnings)),
            const SizedBox(height: 8),
            _miniScoreRow(match.team2Name, scoreLine(teamBInnings)),
          ],
        ),
      ),
    );
  }

  Widget _miniScoreRow(String team, String score) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '$team:',
            style: const TextStyle(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(score),
      ],
    );
  }

  Widget _buildBattingSection(_InningsReportData reportData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('🏏 ${reportData.battingTeamName.toUpperCase()} BATTING', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                headingRowHeight: 34,
                dataRowMinHeight: 34,
                dataRowMaxHeight: 44,
                columns: const <DataColumn>[
                  DataColumn(label: Text('Batter')),
                  DataColumn(label: Text('R')),
                  DataColumn(label: Text('B')),
                  DataColumn(label: Text('4s')),
                  DataColumn(label: Text('6s')),
                  DataColumn(label: Text('SR')),
                  DataColumn(label: Text('Dismissal')),
                ],
                rows: <DataRow>[
                  ...reportData.batters.map(
                    (b) => DataRow(
                      cells: <DataCell>[
                        DataCell(Text(b.displayName)),
                        DataCell(Text('${b.runs}')),
                        DataCell(Text('${b.balls}')),
                        DataCell(Text('${b.fours}')),
                        DataCell(Text('${b.sixes}')),
                        DataCell(Text(b.strikeRate.toStringAsFixed(1))),
                        DataCell(Text(b.dismissal)),
                      ],
                    ),
                  ),
                  DataRow(
                    cells: <DataCell>[
                      const DataCell(Text('Extras', style: TextStyle(fontWeight: FontWeight.w700))),
                      DataCell(Text('${reportData.extrasTotal}')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      DataCell(Text(reportData.extrasBreakdown)),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w700))),
                      DataCell(Text('${reportData.innings.totalRuns}')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      DataCell(
                        Text('${reportData.innings.wickets} wkts, ${_oversText(reportData.legalBalls, reportData.ballsPerOver)} overs'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('FOW: ${reportData.fallOfWickets.isEmpty ? '-' : reportData.fallOfWickets.join(', ')}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBowlingSection(_InningsReportData reportData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('🎯 ${reportData.bowlingTeamName.toUpperCase()} BOWLING', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                headingRowHeight: 34,
                dataRowMinHeight: 34,
                dataRowMaxHeight: 42,
                columns: const <DataColumn>[
                  DataColumn(label: Text('Bowler')),
                  DataColumn(label: Text('O')),
                  DataColumn(label: Text('M')),
                  DataColumn(label: Text('R')),
                  DataColumn(label: Text('W')),
                  DataColumn(label: Text('Eco')),
                ],
                rows: reportData.bowlers
                    .map(
                      (b) => DataRow(
                        cells: <DataCell>[
                          DataCell(Text(b.name)),
                          DataCell(Text(b.oversText)),
                          DataCell(Text('${b.maidens}')),
                          DataCell(Text('${b.runs}')),
                          DataCell(Text('${b.wickets}')),
                          DataCell(Text(b.economy.toStringAsFixed(1))),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverByOver(MatchModel match, Innings innings) {
    final teamName = innings.battingTeamId == 'team1' ? match.team1Name : match.team2Name;
    final teamAName = match.team1Name;
    final teamBName = match.team2Name;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('📋 OVER BY OVER', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: SegmentedButton<String>(
                    segments: <ButtonSegment<String>>[
                      ButtonSegment<String>(value: 'team1', label: Text('$teamAName Overs')),
                      ButtonSegment<String>(value: 'team2', label: Text('$teamBName Overs')),
                    ],
                    selected: <String>{_selectedOverTeam},
                    onSelectionChanged: (set) {
                      setState(() {
                        _selectedOverTeam = set.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Showing: $teamName innings'),
            const SizedBox(height: 8),
            ...innings.overs.where((over) => over.balls.isNotEmpty).map(
              (over) {
                final bowlerName = _playerName(match, over.bowlerId);
                final scoreAfter = _scoreAfterOver(innings, over.overNumber);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Over ${over.overNumber + 1} · $bowlerName · ${over.runsInOver} runs'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: over.balls.map(_ballChip).toList(growable: false),
                      ),
                      const SizedBox(height: 6),
                      Text('Score after: $scoreAfter'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _ballChip(Ball ball) {
    final label = _ballLabel(ball);
    return CircleAvatar(
      radius: 13,
      backgroundColor: _ballColor(ball),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildHighlights(
    _TopBatter? topScorer,
    _BestBowler? bestBowler,
    _BestOver? bestOver,
    PartnershipRecord? bestPartnership,
  ) {
    Widget item(String title, String line1, String line2, {Color? color}) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(line1, style: TextStyle(color: color)),
              const SizedBox(height: 4),
              Text(line2, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('⚡ MATCH HIGHLIGHTS', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.35,
          children: <Widget>[
            item(
              '🏏 Top Scorer',
              topScorer == null ? '-' : '${topScorer.name} — ${topScorer.runs}(${topScorer.balls})',
              topScorer == null ? '-' : 'SR: ${topScorer.strikeRate.toStringAsFixed(1)}',
            ),
            item(
              '🎯 Best Bowler',
              bestBowler == null ? '-' : '${bestBowler.name} — ${bestBowler.wickets}/${bestBowler.runs}',
              bestBowler == null ? '-' : 'Eco: ${bestBowler.economy.toStringAsFixed(1)}',
            ),
            item(
              '🔥 Best Over',
              bestOver == null ? '-' : 'Over ${bestOver.overNumber} — ${bestOver.runs} runs',
              bestOver == null ? '-' : 'by ${bestOver.bowler}',
            ),
            item(
              '🤝 Best Partner',
              bestPartnership == null
                  ? '-'
                  : '${bestPartnership.batters}: ${bestPartnership.runs}(${bestPartnership.balls})',
              bestPartnership == null ? '-' : '${_ordinal(bestPartnership.forWicket)} wicket stand',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRunRateChart(MatchModel match, Innings? first, Innings? second) {
    final firstData = _runRateSpots(first, match.rules.ballsPerOver);
    final secondData = _runRateSpots(second, match.rules.ballsPerOver);
    final maxY = math.max(
      6.0,
      math.max(_maxSpotY(firstData), _maxSpotY(secondData)) + 2,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('📈 RUN RATE CHART', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: _chartTitles(),
                  lineBarsData: <LineChartBarData>[
                    LineChartBarData(
                      spots: firstData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: secondData,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
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

  Widget _buildWormChart(MatchModel match, Innings? first, Innings? second) {
    final firstData = _wormSpots(first);
    final secondData = _wormSpots(second);
    final maxY = math.max(
      6.0,
      math.max(_maxSpotY(firstData), _maxSpotY(secondData)) + 5,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('🪱 WORM CHART', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: _chartTitles(),
                  lineBarsData: <LineChartBarData>[
                    LineChartBarData(
                      spots: firstData,
                      isCurved: false,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: secondData,
                      isCurved: false,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
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

  FlTitlesData _chartTitles() {
    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(
    MatchModel match,
    _InningsReportData? firstReport,
    _InningsReportData? secondReport,
  ) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => _shareScorecard(match, firstReport, secondReport),
        icon: const Text('📤'),
        label: const Text('Share Scorecard'),
      ),
    );
  }

  Widget _buildBottomButtons(
    MatchModel match,
    _InningsReportData? firstReport,
    _InningsReportData? secondReport,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.go('/'),
            child: const Text('🏠 Home'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _rematch(match),
            child: const Text('🔁 Rematch'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _shareScorecard(match, firstReport, secondReport),
            child: const Text('📤 Share'),
          ),
        ),
      ],
    );
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
        .toList(growable: false);
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
        .toList(growable: false);

    final rematch = MatchModel(
      id: const Uuid().v4(),
      team1Name: source.team1Name,
      team2Name: source.team2Name,
      team1Players: team1,
      team2Players: team2,
      rules: source.rules,
      battingFirstTeamId: source.battingFirstTeamId,
      tossWinnerTeamName: source.tossWinnerTeamName,
      tossDecision: source.tossDecision,
    );

    await ref.read(matchListProvider.notifier).saveMatch(rematch);
    await ref.read(activeMatchProvider.notifier).setMatch(rematch);
    if (!mounted) return;
    context.go('/live');
  }

  Future<void> _shareScorecard(
    MatchModel match,
    _InningsReportData? firstReport,
    _InningsReportData? secondReport,
  ) async {
    final text = _buildShareText(match, firstReport, secondReport);
    await Share.share(text);
  }
}

String _buildShareText(MatchModel match, _InningsReportData? firstReport, _InningsReportData? secondReport) {
  final lines = <String>[
    '--- GULLY CRICKET ---',
    '${match.team1Name} ${_inningsLine(match, 'team1', firstReport, secondReport)} vs ${match.team2Name} ${_inningsLine(match, 'team2', firstReport, secondReport)}',
    match.winnerTeamName == null
        ? 'Match tied'
        : '${match.winnerTeamName} ${match.winDescription ?? 'won'}',
    '',
  ];

  if (firstReport != null) {
    lines.add('${firstReport.battingTeamName.toUpperCase()} BATTING');
    for (final batter in firstReport.batters.take(5)) {
      lines.add('${batter.displayName.padRight(12)} ${batter.runs}(${batter.balls}) SR:${batter.strikeRate.toStringAsFixed(0)} ${batter.dismissal}');
    }
    lines.add('');
  }

  if (secondReport != null) {
    lines.add('${secondReport.battingTeamName.toUpperCase()} BATTING');
    for (final batter in secondReport.batters.take(5)) {
      lines.add('${batter.displayName.padRight(12)} ${batter.runs}(${batter.balls}) SR:${batter.strikeRate.toStringAsFixed(0)} ${batter.dismissal}');
    }
    lines.add('');
  }

  lines.add('Played with Gully Cricket app');
  return lines.join('\n');
}

String _inningsLine(
  MatchModel match,
  String teamId,
  _InningsReportData? firstReport,
  _InningsReportData? secondReport,
) {
  _InningsReportData? report;
  if (firstReport?.innings.battingTeamId == teamId) report = firstReport;
  if (secondReport?.innings.battingTeamId == teamId) report = secondReport;
  if (report == null) return '-';

  final allOut = report.innings.wickets >= report.battingPlayersCount - 1;
  final suffix = allOut ? ' ao' : '';
  return '${report.innings.totalRuns}/${report.innings.wickets}$suffix (${_oversText(report.legalBalls, report.ballsPerOver)} ov)';
}

List<FlSpot> _runRateSpots(Innings? innings, int ballsPerOver) {
  if (innings == null) return const <FlSpot>[];
  var cumulativeRuns = 0;
  var cumulativeLegalBalls = 0;
  final spots = <FlSpot>[];
  for (final over in innings.overs.where((o) => o.balls.isNotEmpty)) {
    cumulativeRuns += over.runsInOver;
    cumulativeLegalBalls += over.legalBallCount;
    final runRate = cumulativeLegalBalls == 0 ? 0.0 : (cumulativeRuns / cumulativeLegalBalls) * ballsPerOver;
    spots.add(FlSpot((over.overNumber + 1).toDouble(), runRate));
  }
  return spots;
}

List<FlSpot> _wormSpots(Innings? innings) {
  if (innings == null) return const <FlSpot>[];
  var cumulativeRuns = 0;
  final spots = <FlSpot>[const FlSpot(0, 0)];
  for (final over in innings.overs.where((o) => o.balls.isNotEmpty)) {
    cumulativeRuns += over.runsInOver;
    spots.add(FlSpot((over.overNumber + 1).toDouble(), cumulativeRuns.toDouble()));
  }
  return spots;
}

double _maxSpotY(List<FlSpot> spots) {
  if (spots.isEmpty) return 0;
  return spots.map((s) => s.y).reduce(math.max);
}

String _oversText(int legalBalls, int ballsPerOver) {
  return '${legalBalls ~/ ballsPerOver}.${legalBalls % ballsPerOver}';
}

String _playerName(MatchModel match, String? playerId) {
  if (playerId == null || playerId.isEmpty) return '-';
  for (final p in <Player>[...match.team1Players, ...match.team2Players]) {
    if (p.id == playerId) return p.name;
  }
  return '-';
}

List<Player> _battingTeam(MatchModel match, Innings innings) {
  return innings.battingTeamId == 'team1' ? match.team1Players : match.team2Players;
}

String _scoreAfterOver(Innings innings, int overNumber) {
  final overs = innings.overs.where((o) => o.overNumber <= overNumber);
  var runs = 0;
  var wickets = 0;
  for (final over in overs) {
    for (final ball in over.balls) {
      runs = ball.totalRunsAfterBall > 0 ? ball.totalRunsAfterBall : runs + _deliveryRuns(ball);
      if (ball.isWicket) {
        wickets += 1;
      }
    }
  }
  return '$runs/$wickets';
}

int _deliveryRuns(Ball ball) {
  if (ball.isWide || ball.isNoBall) return 1 + ball.runsScored;
  return ball.runsScored;
}

Color _ballColor(Ball ball) {
  if (ball.isWicket) return AppColors.wicketRed;
  if (ball.isWide || ball.isNoBall) return AppColors.extraYellow;
  if (!ball.isWide && !ball.isNoBall && !ball.isBye && !ball.isLegBye && ball.runsScored == 6) {
    return AppColors.accentGold;
  }
  if (!ball.isWide && !ball.isNoBall && !ball.isBye && !ball.isLegBye && ball.runsScored == 4) {
    return Colors.greenAccent.shade700;
  }
  if (ball.runsScored == 0 && !ball.isWide && !ball.isNoBall) return AppColors.dotGray;
  return AppColors.primaryGreen;
}

String _ballLabel(Ball ball) {
  if (ball.isWicket) return 'W';
  if (ball.isWide) return 'Wd';
  if (ball.isNoBall) return 'Nb';
  if (ball.runsScored == 0) return '·';
  return '${ball.runsScored}';
}

String _ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

_TopBatter? _topScorer(_InningsReportData? first, _InningsReportData? second) {
  final batters = <_BatterRow>[...?first?.batters, ...?second?.batters];
  if (batters.isEmpty) return null;
  batters.sort((a, b) {
    final byRuns = b.runs.compareTo(a.runs);
    if (byRuns != 0) return byRuns;
    return a.balls.compareTo(b.balls);
  });
  final top = batters.first;
  return _TopBatter(name: top.name, runs: top.runs, balls: top.balls, strikeRate: top.strikeRate);
}

_BestBowler? _bestBowler(_InningsReportData? first, _InningsReportData? second) {
  final bowlers = <_BowlerRow>[...?first?.bowlers, ...?second?.bowlers];
  if (bowlers.isEmpty) return null;
  bowlers.sort((a, b) {
    final byW = b.wickets.compareTo(a.wickets);
    if (byW != 0) return byW;
    return a.runs.compareTo(b.runs);
  });
  final top = bowlers.first;
  return _BestBowler(name: top.name, wickets: top.wickets, runs: top.runs, economy: top.economy);
}

_BestOver? _bestOver(MatchModel match, Innings? first, Innings? second) {
  Over? winner;
  Innings? innings;

  for (final current in <Innings?>[first, second].whereType<Innings>()) {
    for (final over in current.overs.where((o) => o.balls.isNotEmpty)) {
      if (winner == null || over.runsInOver > winner.runsInOver) {
        winner = over;
        innings = current;
      }
    }
  }

  if (winner == null || innings == null) return null;
  return _BestOver(
    overNumber: winner.overNumber + 1,
    runs: winner.runsInOver,
    bowler: _playerName(match, winner.bowlerId),
  );
}

class _InningsReportData {
  const _InningsReportData({
    required this.innings,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.batters,
    required this.bowlers,
    required this.extrasTotal,
    required this.extrasBreakdown,
    required this.fallOfWickets,
    required this.legalBalls,
    required this.ballsPerOver,
    required this.battingPlayersCount,
  });

  final Innings innings;
  final String battingTeamName;
  final String bowlingTeamName;
  final List<_BatterRow> batters;
  final List<_BowlerRow> bowlers;
  final int extrasTotal;
  final String extrasBreakdown;
  final List<String> fallOfWickets;
  final int legalBalls;
  final int ballsPerOver;
  final int battingPlayersCount;

  factory _InningsReportData.fromMatch(MatchModel match, Innings innings) {
    final battingPlayers = innings.battingTeamId == 'team1' ? match.team1Players : match.team2Players;
    final bowlingPlayers = innings.bowlingTeamId == 'team1' ? match.team1Players : match.team2Players;
    final playersById = <String, Player>{
      for (final p in <Player>[...match.team1Players, ...match.team2Players]) p.id: p,
    };

    final allBalls = innings.allBalls;

    final batters = battingPlayers
        .where((p) => p.ballsFaced > 0 || p.runsScored > 0 || p.isOut || p.isRetired || p.isRetiredHurt)
        .map(
          (player) => _BatterRow(
            name: player.name,
            runs: player.runsScored,
            balls: player.ballsFaced,
            fours: allBalls.where((ball) => _isBoundary(ball, player.id, 4)).length,
            sixes: allBalls.where((ball) => _isBoundary(ball, player.id, 6)).length,
            strikeRate: player.strikeRate,
            notOut: !player.isOut,
            dismissal: _dismissalText(match, player),
          ),
        )
        .toList(growable: false);

    final bowlers = bowlingPlayers
        .map(
          (p) {
            final balls = allBalls.where((ball) => ball.bowlerId == p.id).toList(growable: false);
            final legalBalls = balls.where((ball) => ball.isLegalBall).length;
            final runs = balls.fold<int>(0, (sum, ball) => sum + _deliveryRuns(ball));
            final wickets = balls.where((ball) => ball.isWicket && ball.wicketType != 'run_out').length;
            final maidens = innings.overs
                .where((over) => over.bowlerId == p.id)
                .where((over) => over.isComplete(match.rules.ballsPerOver) && over.runsInOver == 0)
                .length;
            final economy = legalBalls == 0 ? 0.0 : (runs / legalBalls) * match.rules.ballsPerOver;
            return _BowlerRow(
              name: p.name,
              oversText: _oversText(legalBalls, match.rules.ballsPerOver),
              maidens: maidens,
              runs: runs,
              wickets: wickets,
              economy: economy,
            );
          },
        )
        .where((row) => row.runs > 0 || row.wickets > 0 || row.oversText != '0.0')
        .toList(growable: false);

    final wides = allBalls.where((ball) => ball.isWide).fold<int>(0, (sum, ball) => sum + 1 + ball.runsScored);
    final noBalls = allBalls.where((ball) => ball.isNoBall).fold<int>(0, (sum, ball) => sum + 1 + ball.runsScored);
    final byes = allBalls.where((ball) => ball.isBye).fold<int>(0, (sum, ball) => sum + ball.runsScored);
    final legByes = allBalls.where((ball) => ball.isLegBye).fold<int>(0, (sum, ball) => sum + ball.runsScored);

    final extrasParts = <String>[];
    if (wides > 0) extrasParts.add('${wides}wd');
    if (noBalls > 0) extrasParts.add('${noBalls}nb');
    if (byes > 0) extrasParts.add('${byes}b');
    if (legByes > 0) extrasParts.add('${legByes}lb');

    final fow = <String>[];
    var wicketNo = 0;
    for (final ball in allBalls.where((b) => b.isWicket)) {
      wicketNo += 1;
      final dismissedId = ball.dismissedPlayerId ?? ball.batsmanId;
      final name = playersById[dismissedId]?.name ?? 'Batter';
      final overBall = '${ball.overNumber + 1}.${ball.ballInOver}';
      final score = ball.totalRunsAfterBall;
      fow.add('$wicketNo-$score ($name, $overBall)');
    }

    return _InningsReportData(
      innings: innings,
      battingTeamName: innings.battingTeamId == 'team1' ? match.team1Name : match.team2Name,
      bowlingTeamName: innings.bowlingTeamId == 'team1' ? match.team1Name : match.team2Name,
      batters: batters,
      bowlers: bowlers,
      extrasTotal: wides + noBalls + byes + legByes,
      extrasBreakdown: extrasParts.isEmpty ? '(0)' : '(${extrasParts.join(', ')})',
      fallOfWickets: fow,
      legalBalls: allBalls.where((ball) => ball.isLegalBall).length,
      ballsPerOver: match.rules.ballsPerOver,
      battingPlayersCount: battingPlayers.length,
    );
  }
}

class _BatterRow {
  const _BatterRow({
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
    required this.notOut,
    required this.dismissal,
  });

  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;
  final bool notOut;
  final String dismissal;

  String get displayName => notOut ? '$name *' : name;
}

class _BowlerRow {
  const _BowlerRow({
    required this.name,
    required this.oversText,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });

  final String name;
  final String oversText;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;
}

class _TopBatter {
  const _TopBatter({required this.name, required this.runs, required this.balls, required this.strikeRate});

  final String name;
  final int runs;
  final int balls;
  final double strikeRate;
}

class _BestBowler {
  const _BestBowler({
    required this.name,
    required this.wickets,
    required this.runs,
    required this.economy,
  });

  final String name;
  final int wickets;
  final int runs;
  final double economy;
}

class _BestOver {
  const _BestOver({required this.overNumber, required this.runs, required this.bowler});

  final int overNumber;
  final int runs;
  final String bowler;
}

bool _isBoundary(Ball ball, String batsmanId, int runs) {
  return ball.batsmanId == batsmanId && !ball.isWide && !ball.isBye && !ball.isLegBye && ball.runsScored == runs;
}

String _dismissalText(MatchModel match, Player player) {
  if (player.isRetiredHurt) return 'retired hurt';
  if (player.isRetired) return 'retired';
  if (!player.isOut) return 'not out';

  final allPlayers = <Player>[...match.team1Players, ...match.team2Players];
  final bowlerName = allPlayers.firstWhereOrNull((p) => p.id == player.dismissedBy)?.name;
  final type = (player.wicketType ?? 'out').replaceAll('_', ' ');
  if (bowlerName == null || bowlerName.isEmpty) return type;
  if (type.startsWith('caught')) return 'c ? b $bowlerName';
  if (type == 'run out') return 'run out';
  return '$type b $bowlerName';
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
