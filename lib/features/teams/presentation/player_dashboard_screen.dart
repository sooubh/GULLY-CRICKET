import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../stats/providers/stats_providers.dart';

class PlayerDashboardScreen extends ConsumerWidget {
  const PlayerDashboardScreen({
    super.key,
    required this.playerName,
  });

  final String playerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(playerStatsProvider(playerName));

    return Scaffold(
      appBar: AppBar(title: Text(playerName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Section(
            title: 'Batting',
            lines: <String>[
              'Matches: ${stats.matches}',
              'Innings: ${stats.innings}',
              'Runs: ${stats.totalRuns}',
              'High score: ${stats.highScore}',
              'Average: ${stats.battingAverage.toStringAsFixed(2)}',
              'Strike rate: ${stats.strikeRate.toStringAsFixed(2)}',
              '50s/100s: ${stats.fifties}/${stats.hundreds}',
              '4s/6s: ${stats.fours}/${stats.sixes}',
            ],
          ),
          _Section(
            title: 'Bowling',
            lines: <String>[
              'Balls: ${stats.ballsBowled}',
              'Wickets: ${stats.wickets}',
              'Runs conceded: ${stats.runsConceded}',
              'Best: ${stats.bestBowling}',
              'Economy: ${stats.economy.toStringAsFixed(2)}',
            ],
          ),
          _Section(
            title: 'Results',
            lines: <String>[
              'Wins/Losses/Ties: ${stats.wins}/${stats.losses}/${stats.ties}',
              'Win %: ${stats.winPercentage.toStringAsFixed(1)}',
              'Form: ${stats.formString.isEmpty ? '-' : stats.formString}',
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...lines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(line),
                )),
          ],
        ),
      ),
    );
  }
}
