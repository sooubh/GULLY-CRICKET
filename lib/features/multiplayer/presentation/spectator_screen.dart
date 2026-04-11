import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../scoring/domain/models/ball_model.dart';
import '../../scoring/domain/models/innings_model.dart';
import '../../scoring/domain/models/match_model.dart';
import '../../scoring/domain/models/player_model.dart';
import '../../scoring/presentation/widgets/ball_timeline.dart';
import '../../scoring/presentation/widgets/scoreboard_header.dart';
import '../services/client_service.dart';

class SpectatorScreen extends ConsumerWidget {
  const SpectatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientServiceProvider);
    return Scaffold(
      body: StreamBuilder<MatchModel>(
        stream: client.matchUpdates,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final match = snapshot.data!;
          final innings = match.currentInnings;
          if (innings == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final batting = innings.battingTeamId == 'team1' ? match.team1Players : match.team2Players;
          final bowling = innings.bowlingTeamId == 'team1' ? match.team1Players : match.team2Players;
          final striker = _findPlayer(batting, innings.currentBatsmanId);
          final nonStriker = _findPlayer(batting, innings.currentNonStrikerId);
          final bowler = _findPlayer(bowling, innings.currentBowlerId);
          final figures = _bowlerFigures(innings, match, bowler?.id);
          final overBalls = _currentOverBalls(innings);

          return SafeArea(
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Text('Connected to host'),
                ),
                StreamBuilder<bool>(
                  stream: client.connectionStatus,
                  initialData: client.isConnected,
                  builder: (context, state) {
                    if (state.data == true) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      color: Colors.orange.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: <Widget>[
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          const Text('⚠️ Reconnecting...'),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: <Widget>[
                      const Spacer(),
                      const _LiveViewBadge(),
                    ],
                  ),
                ),
                ScoreboardHeader(match: match, innings: innings),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      _PlayerLine(
                        icon: '🟢',
                        name: '${striker?.name ?? '-'}*',
                        stats:
                            '${striker?.runsScored ?? 0}(${striker?.ballsFaced ?? 0})  SR: ${(striker?.strikeRate ?? 0).toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 6),
                      _PlayerLine(
                        icon: '🔵',
                        name: nonStriker?.name ?? '-',
                        stats:
                            '${nonStriker?.runsScored ?? 0}(${nonStriker?.ballsFaced ?? 0})  SR: ${(nonStriker?.strikeRate ?? 0).toStringAsFixed(0)}',
                      ),
                      const Divider(height: 18),
                      _PlayerLine(
                        icon: '🎯',
                        name: bowler?.name ?? '-',
                        stats:
                            '${figures.oversText}-${figures.maidens}-${figures.runs}-${figures.wickets}  Eco: ${figures.economy.toStringAsFixed(1)}',
                      ),
                    ],
                  ),
                ),
                BallTimeline(balls: overBalls),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LiveViewBadge extends StatelessWidget {
  const _LiveViewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fade(begin: 0.3, end: 1, duration: 700.ms),
          const SizedBox(width: 8),
          const Text('👁 LIVE VIEW'),
        ],
      ),
    );
  }
}

Player? _findPlayer(List<Player> players, String? id) {
  if (id == null) return null;
  for (final player in players) {
    if (player.id == id) return player;
  }
  return null;
}

List<Ball> _currentOverBalls(Innings innings) {
  if (innings.overs.isEmpty) return const <Ball>[];
  for (var i = innings.overs.length - 1; i >= 0; i--) {
    if (innings.overs[i].balls.isNotEmpty) return innings.overs[i].balls;
  }
  return const <Ball>[];
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
  final economy = legalBalls == 0 ? 0 : (runs / legalBalls) * match.rules.ballsPerOver;
  return _BowlerFigures(
    oversText: oversText,
    maidens: maidens,
    runs: runs,
    wickets: wickets,
    economy: economy,
  );
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({
    required this.icon,
    required this.name,
    required this.stats,
  });

  final String icon;
  final String name;
  final String stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$name   $stats',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
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
