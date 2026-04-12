import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SelectBatsmanScreen(players: available, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                        controller: scrollController,
                        itemCount: players.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final player = players[index];
                          return ListTile(
                            title: Text(
                              player.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                            subtitle: Text(player.isRetired ? 'retired' : 'available'),
                            onTap: () => Navigator.of(context).pop(player),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
