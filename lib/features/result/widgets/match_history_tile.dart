import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../scoring/domain/models/match_model.dart';

class MatchHistoryTile extends StatelessWidget {
  const MatchHistoryTile({
    super.key,
    required this.match,
    required this.onTap,
    required this.onLongPress,
  });

  final MatchModel match;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final winnerLine = '${match.winnerTeamName ?? 'Match Tied'} ${match.winDescription ?? ''}'.trim();
    final dateLine = DateFormat('dd MMM yyyy').format(match.completedAt ?? match.createdAt);
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      title: Text(
        '${match.team1Name} vs ${match.team2Name}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 4),
          Text(
            winnerLine,
            style: const TextStyle(color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 2),
          Text('$dateLine • ${match.rules.totalOvers} overs'),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
