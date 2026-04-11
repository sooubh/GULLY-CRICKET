import 'package:flutter/material.dart';

import '../domain/models/player_model.dart';

class SelectBowlerScreen extends StatelessWidget {
  const SelectBowlerScreen({
    super.key,
    required this.bowlers,
    required this.title,
  });

  final List<Player> bowlers;
  final String title;

  static Future<Player?> show(
    BuildContext context, {
    required List<Player> bowlers,
    required String title,
  }) {
    return showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      builder: (context) => SelectBowlerScreen(bowlers: bowlers, title: title),
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
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final bowler = bowlers[index];
                        return ListTile(
                          title: Text(bowler.name),
                          subtitle: Text(
                            '${bowler.oversBowled}.0 overs  •  ${bowler.wicketsTaken} wkts  •  Eco ${bowler.economy.toStringAsFixed(1)}',
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
