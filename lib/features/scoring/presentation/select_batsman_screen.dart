import 'package:flutter/material.dart';

import '../domain/models/player_model.dart';

class SelectBatsmanScreen extends StatelessWidget {
  const SelectBatsmanScreen({
    super.key,
    required this.players,
    required this.title,
  });

  final List<Player> players;
  final String title;

  static Future<Player?> show(
    BuildContext context, {
    required List<Player> battingPlayers,
    required String? strikerId,
    required String? nonStrikerId,
    required bool reEntryAllowed,
    required String title,
  }) {
    final available = battingPlayers.where((player) {
      final alreadyOnPitch = player.id == strikerId || player.id == nonStrikerId;
      final availableByStatus =
          !player.isOut && !player.isRetiredHurt && (!player.isRetired || reEntryAllowed);
      return !alreadyOnPitch && availableByStatus;
    }).toList();

    return showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      builder: (context) => SelectBatsmanScreen(players: available, title: title),
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
              child: players.isEmpty
                  ? const Center(child: Text('No available batsman'))
                  : ListView.separated(
                      itemCount: players.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return ListTile(
                          title: Text(player.name),
                          subtitle: Text(player.isRetired ? 'retired' : 'available'),
                          onTap: () => Navigator.of(context).pop(player),
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
