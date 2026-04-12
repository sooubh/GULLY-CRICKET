import 'package:flutter/material.dart';

import '../domain/models/over_model.dart';
import '../domain/models/player_model.dart';

class SelectBowlerScreen extends StatelessWidget {
  const SelectBowlerScreen({
    super.key,
    required this.bowlers,
    required this.title,
    required this.overs,
    required this.ballsPerOver,
  });

  final List<Player> bowlers;
  final String title;
  final List<Over> overs;
  final int ballsPerOver;

  static Future<Player?> show(
    BuildContext context, {
    required List<Player> bowlers,
    required String title,
    required List<Over> overs,
    required int ballsPerOver,
  }) {
    return showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      builder: (context) => SelectBowlerScreen(
        bowlers: bowlers,
        title: title,
        overs: overs,
        ballsPerOver: ballsPerOver,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Expanded(
              child: bowlers.isEmpty
                  ? const Center(child: Text('No eligible bowler'))
                  : ListView.separated(
                      itemCount: bowlers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final bowler = bowlers[index];
                        final bowlerOvers = overs
                            .where((over) => over.bowlerId == bowler.id && over.balls.isNotEmpty)
                            .toList();
                        final legalBalls =
                            bowlerOvers.fold<int>(0, (sum, over) => sum + over.legalBallCount);
                        final oversText = '${legalBalls ~/ ballsPerOver}.${legalBalls % ballsPerOver}';
                        final wickets =
                            bowlerOvers.fold<int>(0, (sum, over) => sum + over.wicketsInOver);
                        final runs = bowlerOvers.fold<int>(0, (sum, over) => sum + over.runsInOver);
                        final eco = legalBalls == 0 ? 0 : (runs / legalBalls) * ballsPerOver;
                        return ListTile(
                          title: Text(bowler.name),
                          subtitle: Text(
                            '$oversText overs  •  $wickets wkts  •  Eco ${eco.toStringAsFixed(1)}',
                          ),
                          onTap: () => Navigator.of(context).pop(bowler),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
