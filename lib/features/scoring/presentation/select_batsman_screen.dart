import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/models/player_model.dart';

class SelectBatsmanScreen extends StatelessWidget {
  const SelectBatsmanScreen({
    super.key,
    required this.players,
    required this.strikerId,
    required this.nonStrikerId,
    required this.reEntryAllowed,
    required this.title,
  });

  final List<Player> players;
  final String? strikerId;
  final String? nonStrikerId;
  final bool reEntryAllowed;
  final String title;

  static Future<Player?> show(
    BuildContext context, {
    required List<Player> battingPlayers,
    required String? strikerId,
    required String? nonStrikerId,
    required bool reEntryAllowed,
    required String title,
    required Future<void> Function() onNoAvailable,
  }) async {
    final available = battingPlayers.where(
      (player) => !player.isOut && !(player.isRetired && !reEntryAllowed) && !player.isRetiredHurt,
    );
    if (available.isEmpty) {
      await onNoAvailable();
      return null;
    }

    return showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SelectBatsmanScreen(
        players: battingPlayers,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        reEntryAllowed: reEntryAllowed,
        title: title,
      ),
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
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final alreadyOnPitch = player.id == strikerId || player.id == nonStrikerId;
                    final availableByStatus =
                        !player.isOut && !player.isRetiredHurt && (!player.isRetired || reEntryAllowed);
                    final isSelectable = !alreadyOnPitch && availableByStatus;
                    final status = player.isRetiredHurt || player.isOut
                        ? 'Out'
                        : player.isRetired
                        ? (reEntryAllowed ? 'Retired (recall)' : 'Retired')
                        : 'Not out';
                    return ListTile(
                      title: Text(
                        player.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                      subtitle: Text(status),
                      trailing: alreadyOnPitch ? const Text('Batting') : null,
                      enabled: isSelectable,
                      onTap: isSelectable ? () => Navigator.of(context).pop(player) : null,
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
