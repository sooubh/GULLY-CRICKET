import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../players/domain/saved_player_model.dart';
import '../../players/services/saved_players_service.dart';
import '../domain/team_model.dart';
import '../services/teams_service.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({
    super.key,
    this.teamId,
  });

  final String? teamId;

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _shortNameController;
  late final TextEditingController _searchController;
  final List<TextEditingController> _playerControllers = <TextEditingController>[];
  final List<bool> _saveToggles = <bool>[];

  static const List<String> _presetColors = <String>[
    '#2E7D32',
    '#1565C0',
    '#C62828',
    '#EF6C00',
    '#6A1B9A',
    '#F9A825',
    '#00838F',
    '#D81B60',
  ];

  TeamModel? _editingTeam;
  String _selectedColor = _presetColors.first;
  String? _captainName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _shortNameController = TextEditingController();
    _searchController = TextEditingController();

    final teamId = widget.teamId;
    if (teamId != null && teamId.isNotEmpty) {
      _editingTeam = ref.read(teamsProvider.notifier).getTeamById(teamId);
      if (_editingTeam != null) {
        _nameController.text = _editingTeam!.name;
        _shortNameController.text = _editingTeam!.shortName ?? '';
        _selectedColor = _editingTeam!.colorHex;
        _captainName = _editingTeam!.captainName;
        for (final player in _editingTeam!.playerNames) {
          _playerControllers.add(TextEditingController(text: player));
          _saveToggles.add(false);
        }
      }
    }

    if (_playerControllers.isEmpty) {
      _playerControllers.add(TextEditingController());
      _saveToggles.add(false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _searchController.dispose();
    for (final controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveTeam() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Team name is required');
      return;
    }

    final shortName = _shortNameController.text.trim();
    if (shortName.length > 4) {
      _showSnackBar('Short name can be maximum 4 characters');
      return;
    }

    final players = _playerControllers
        .map((controller) => controller.text.trim())
        .where((player) => player.isNotEmpty)
        .toList();
    if (players.isEmpty) {
      _showSnackBar('Add at least one player');
      return;
    }

    if (_captainName != null && !players.contains(_captainName)) {
      _captainName = null;
    }

    for (final entry in _playerControllers.asMap().entries) {
      final value = entry.value.text.trim();
      if (_saveToggles[entry.key] && value.isNotEmpty) {
        await ref.read(savedPlayersProvider.notifier).savePlayer(value);
      }
    }

    final base = _editingTeam;
    final team = (base ?? TeamModel.create(name: name)).copyWith(
      name: name,
      shortName: shortName.isEmpty ? null : shortName,
      colorHex: _selectedColor,
      playerNames: players,
      captainName: _captainName,
    );

    final saved = await ref.read(teamsProvider.notifier).saveTeam(team);
    if (!saved) {
      _showSnackBar('Team with same name already exists');
      return;
    }
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/teams');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _addPlayerField() {
    if (_playerControllers.length >= 20) return;
    setState(() {
      _playerControllers.add(TextEditingController());
      _saveToggles.add(false);
    });
  }

  void _removePlayerField() {
    if (_playerControllers.length <= 1) return;
    final removed = _playerControllers.removeLast();
    _saveToggles.removeLast();
    removed.dispose();
    setState(() {
      final options = _captainOptions;
      if (_captainName != null && !options.contains(_captainName)) {
        _captainName = null;
      }
    });
  }

  void _toggleSave(int index) {
    setState(() {
      _saveToggles[index] = !_saveToggles[index];
    });
  }

  void _quickAddPlayer(SavedPlayer player) {
    final name = player.name.trim();
    if (name.isEmpty) return;
    setState(() {
      for (final controller in _playerControllers) {
        if (controller.text.trim().isEmpty) {
          controller.text = name;
          return;
        }
      }
      _playerControllers.add(TextEditingController(text: name));
      _saveToggles.add(false);
    });
  }

  List<String> get _captainOptions => _playerControllers
      .map((controller) => controller.text.trim())
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context) {
    final savedPlayers = ref.watch(savedPlayersProvider);
    final query = _searchController.text.trim().toLowerCase();
    final filteredPlayers = query.isEmpty
        ? savedPlayers
        : savedPlayers.where((player) => player.name.toLowerCase().contains(query)).toList();
    final captainOptions = _captainOptions;

    return Scaffold(
      appBar: AppBar(title: Text(_editingTeam == null ? 'Create Team' : 'Edit Team')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Team name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _shortNameController,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Short name (max 4)'),
              ),
              const SizedBox(height: 8),
              const Text('Team Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _presetColors.map((hex) {
                  final selected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _parseColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: captainOptions.contains(_captainName) ? _captainName : null,
                decoration: const InputDecoration(labelText: 'Captain'),
                items: captainOptions
                    .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                    .toList(),
                onChanged: (value) => setState(() => _captainName = value),
              ),
              const SizedBox(height: 14),
              if (savedPlayers.isNotEmpty) ...<Widget>[
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search saved players',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filteredPlayers
                        .map(
                          (player) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(player.name),
                              avatar: player.isFavorite ? const Icon(Icons.star, size: 14) : null,
                              onPressed: () => _quickAddPlayer(player),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const Text('Player roster'),
              const SizedBox(height: 8),
              ..._playerControllers.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: entry.value,
                    onChanged: (_) {
                      setState(() {
                        if (_captainName != null && !_captainOptions.contains(_captainName)) {
                          _captainName = null;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Player ${entry.key + 1}',
                      suffixIcon: IconButton(
                        tooltip: 'Save player',
                        onPressed: () => _toggleSave(entry.key),
                        icon: Icon(
                          _saveToggles[entry.key] ? Icons.bookmark : Icons.bookmark_border,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Row(
                children: <Widget>[
                  TextButton(onPressed: _addPlayerField, child: const Text('Add player')),
                  TextButton(onPressed: _removePlayerField, child: const Text('Remove last')),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveTeam,
                  child: const Text('Save Team'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final argb = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.tryParse(argb, radix: 16) ?? 0xFF2E7D32);
}
