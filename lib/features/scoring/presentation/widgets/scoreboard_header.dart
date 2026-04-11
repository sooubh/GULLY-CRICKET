import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/innings_model.dart';
import '../../domain/models/match_model.dart';

class ScoreboardHeader extends StatelessWidget {
  const ScoreboardHeader({
    super.key,
    required this.match,
    required this.innings,
  });

  final MatchModel match;
  final Innings innings;

  @override
  Widget build(BuildContext context) {
    final isTeam1Batting = innings.battingTeamId == 'team1';
    final battingTeamName = isTeam1Batting ? match.team1Name : match.team2Name;
    final legalBalls = innings.legalBallsCount();
    final ballsPerOver = match.rules.ballsPerOver;
    final overText = '${legalBalls ~/ ballsPerOver}.${legalBalls % ballsPerOver}';
    final crr = legalBalls == 0 ? 0 : (innings.totalRuns / legalBalls) * ballsPerOver;

    final target = innings.inningsNumber == 2 ? match.target : null;
    final ballsRemaining = (match.rules.totalOvers * ballsPerOver) - legalBalls;
    final safeBallsRemaining = ballsRemaining < 0 ? 0 : ballsRemaining;
    final runsNeeded = target == null ? 0 : (target - innings.totalRuns).clamp(0, 9999);
    final rrr = safeBallsRemaining == 0 ? 0 : (runsNeeded / safeBallsRemaining) * ballsPerOver;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$battingTeamName: ${innings.score}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text('● $overText Overs   •   CRR: ${crr.toStringAsFixed(1)}'),
          if (target != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Target: $target  |  Need: $runsNeeded off $safeBallsRemaining  |  RRR: ${rrr.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
