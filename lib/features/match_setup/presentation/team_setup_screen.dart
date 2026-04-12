import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../players/domain/saved_player_model.dart';
import '../../players/services/saved_players_service.dart';
import 'match_setup_notifier.dart';

class TeamSetupScreen extends ConsumerStatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  ConsumerState<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends ConsumerState<TeamSetupScreen> {
  late List<TextEditingController> _team1Controllers;
  late List<TextEditingController> _team2Controllers;
  late List<bool> _team1SaveToggles;
  late List<bool> _team2SaveToggles;
  String _team1SearchQuery = '';
  String _team2SearchQuery = '';

  @override
  void initState() {
    super.initState();
    final config = ref.read(matchSetupProvider);
    _team1Controllers = _controllersFrom(config.team1Players, config.team1PlayerCount);
    _team2Controllers = _controllersFrom(config.team2Players, config.team2PlayerCount);
    _team1SaveToggles = List<bool>.filled(_team1Controllers.length, false);
    _team2SaveToggles = List<bool>.filled(_team2Controllers.length, false);
  }

  List<TextEditingController> _controllersFrom(List<String> players, int fallbackCount) {
    if (players.isNotEmpty) {
      return players.map((name) => TextEditingController(text: name)).toList();
    }
    return List<TextEditingController>.generate(
      fallbackCount,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in _team1Controllers) {
      controller.dispose();
    }
    for (final controller in _team2Controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTeam1Player() {
    if (_team1Controllers.length >= 11) return;
    setState(() {
      _team1Controllers.add(TextEditingController());
      _team1SaveToggles.add(false);
    });
  }

  void _addTeam2Player() {
    if (_team2Controllers.length >= 11) return;
    setState(() {
      _team2Controllers.add(TextEditingController());
      _team2SaveToggles.add(false);
    });
  }

  void _removeTeam1Player() {
    if (_team1Controllers.length <= 1) return;
    final removed = _team1Controllers.last;
    setState(() {
      _team1Controllers.removeLast();
      _team1SaveToggles.removeLast();
    });
    removed.dispose();
  }

  void _removeTeam2Player() {
    if (_team2Controllers.length <= 1) return;
    final removed = _team2Controllers.last;
    setState(() {
      _team2Controllers.removeLast();
      _team2SaveToggles.removeLast();
    });
    removed.dispose();
  }

  void _toggleTeam1Save(int index) {
    if (index < 0 || index >= _team1SaveToggles.length) return;
    setState(() => _team1SaveToggles[index] = !_team1SaveToggles[index]);
  }

  void _toggleTeam2Save(int index) {
    if (index < 0 || index >= _team2SaveToggles.length) return;
    setState(() => _team2SaveToggles[index] = !_team2SaveToggles[index]);
  }

  void _quickAddTeam1Player(SavedPlayer player) {
    _quickAddPlayer(
      playerName: player.name,
      controllers: _team1Controllers,
      saveToggles: _team1SaveToggles,
    );
  }

  void _quickAddTeam2Player(SavedPlayer player) {
    _quickAddPlayer(
      playerName: player.name,
      controllers: _team2Controllers,
      saveToggles: _team2SaveToggles,
    );
  }

  void _quickAddPlayer({
    required String playerName,
    required List<TextEditingController> controllers,
    required List<bool> saveToggles,
  }) {
    final trimmed = playerName.trim();
    if (trimmed.isEmpty) return;
    var added = false;
    setState(() {
      for (final controller in controllers) {
        if (controller.text.trim().isEmpty) {
          controller.text = trimmed;
          added = true;
          return;
        }
      }
      if (controllers.length < 11) {
        controllers.add(TextEditingController(text: trimmed));
        saveToggles.add(false);
        added = true;
        return;
      }
    });
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 11 players allowed per team')),
      );
    }
  }

  Future<void> _savePlayersAndNavigate() async {
    final team1 = _team1Controllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final team2 = _team2Controllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (team1.isEmpty || team2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each team must have at least one player name')),
      );
      return;
    }

    final savedPlayers = ref.read(savedPlayersProvider.notifier);
    for (final entry in _team1Controllers.asMap().entries) {
      if (_team1SaveToggles[entry.key]) {
        await savedPlayers.savePlayer(entry.value.text.trim());
      }
    }
    for (final entry in _team2Controllers.asMap().entries) {
      if (_team2SaveToggles[entry.key]) {
        await savedPlayers.savePlayer(entry.value.text.trim());
      }
    }

    ref.read(matchSetupProvider.notifier).updateTeamPlayers(team1Players: team1, team2Players: team2);
    if (mounted) context.push('/rules');
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(matchSetupProvider);
    final savedPlayers = ref.watch(savedPlayersProvider);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Add Players')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                _TeamSection(
                  teamName: config.team1Name,
                  controllers: _team1Controllers,
                  saveToggles: _team1SaveToggles,
                  onToggleSave: _toggleTeam1Save,
                  onAddAnother: _addTeam1Player,
                  onRemoveLast: _removeTeam1Player,
                  savedPlayers: savedPlayers,
                  searchQuery: _team1SearchQuery,
                  onSearchChanged: (value) => setState(() => _team1SearchQuery = value),
                  onQuickAdd: _quickAddTeam1Player,
                ),
                const SizedBox(height: 20),
                _TeamSection(
                  teamName: config.team2Name,
                  controllers: _team2Controllers,
                  saveToggles: _team2SaveToggles,
                  onToggleSave: _toggleTeam2Save,
                  onAddAnother: _addTeam2Player,
                  onRemoveLast: _removeTeam2Player,
                  savedPlayers: savedPlayers,
                  searchQuery: _team2SearchQuery,
                  onSearchChanged: (value) => setState(() => _team2SearchQuery = value),
                  onQuickAdd: _quickAddTeam2Player,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _savePlayersAndNavigate,
                    child: const Text('Next: Set Rules →'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection({
    required this.teamName,
    required this.controllers,
    required this.saveToggles,
    required this.onToggleSave,
    required this.onAddAnother,
    required this.onRemoveLast,
    required this.savedPlayers,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onQuickAdd,
  });

  final String teamName;
  final List<TextEditingController> controllers;
  final List<bool> saveToggles;
  final ValueChanged<int> onToggleSave;
  final VoidCallback onAddAnother;
  final VoidCallback onRemoveLast;
  final List<SavedPlayer> savedPlayers;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SavedPlayer> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final filteredPlayers = query.isEmpty
        ? savedPlayers
        : savedPlayers.where((player) => player.name.toLowerCase().contains(query)).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
              Text(
                teamName,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            if (savedPlayers.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              TextField(
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search saved players',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quick add saved players',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filteredPlayers
                      .map(
                        (player) => ActionChip(
                          label: Text(player.name),
                          avatar: player.isFavorite ? const Icon(Icons.star, size: 16) : null,
                          onPressed: () => onQuickAdd(player),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ...controllers.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: 'Player ${entry.key + 1}',
                    hintText: 'Player ${entry.key + 1}',
                    suffixIcon: IconButton(
                      onPressed: () => onToggleSave(entry.key),
                      tooltip: 'Save player for future matches',
                      icon: Icon(
                        saveToggles[entry.key] ? Icons.bookmark : Icons.bookmark_border,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: <Widget>[
                  TextButton(
                    onPressed: controllers.length >= 11 ? null : onAddAnother,
                    child: const Text('Add another player'),
                  ),
                  TextButton(
                    onPressed: controllers.length <= 1 ? null : onRemoveLast,
                    child: const Text('Remove last player'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
