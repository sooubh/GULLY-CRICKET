import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/saved_player_model.dart';
import '../services/saved_players_service.dart';

class SavedPlayersScreen extends ConsumerStatefulWidget {
  const SavedPlayersScreen({super.key});

  @override
  ConsumerState<SavedPlayersScreen> createState() => _SavedPlayersScreenState();
}

class _SavedPlayersScreenState extends ConsumerState<SavedPlayersScreen> {
  final TextEditingController _addController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _addPlayer() async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    await ref.read(savedPlayersProvider.notifier).savePlayer(name);
    _addController.clear();
  }

  List<SavedPlayer> _filter(List<SavedPlayer> players) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return players;
    return players.where((player) => player.name.toLowerCase().contains(normalized)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final players = _filter(ref.watch(savedPlayersProvider));
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Players')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _addController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addPlayer(),
                decoration: InputDecoration(
                  hintText: 'Add player name',
                  suffixIcon: IconButton(
                    onPressed: _addPlayer,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search players',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: players.isEmpty
                    ? const Center(child: Text('No saved players'))
                    : ListView.separated(
                        itemCount: players.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final player = players[index];
                          return ListTile(
                            title: Text(
                              player.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Text(
                              'Played ${player.timesPlayed} • Runs ${player.totalRunsCareer} • Wickets ${player.totalWicketsCareer}',
                            ),
                            trailing: Wrap(
                              spacing: 0,
                              children: <Widget>[
                                IconButton(
                                  tooltip: 'Favorite',
                                  onPressed: () => ref
                                      .read(savedPlayersProvider.notifier)
                                      .toggleFavorite(player.id),
                                  icon: Icon(
                                    player.isFavorite ? Icons.star : Icons.star_border,
                                    color: player.isFavorite ? Colors.amber : null,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => ref
                                      .read(savedPlayersProvider.notifier)
                                      .deletePlayer(player.id),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
