import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../teams/domain/team_model.dart';
import '../../teams/services/teams_service.dart';
import 'match_setup_notifier.dart';

class TeamSetupScreen extends ConsumerStatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  ConsumerState<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends ConsumerState<TeamSetupScreen> {
  static const int _maxSelectedPlayers = 15;
  late List<String> _team1Squad;
  late List<String> _team2Squad;
  late Set<String> _team1Selected;
  late Set<String> _team2Selected;

  @override
  void initState() {
    super.initState();
    final config = ref.read(matchSetupProvider);
    final teams = ref.read(teamsProvider);
    final team1Model = _findTeamByName(config.team1Name, teams);
    final team2Model = _findTeamByName(config.team2Name, teams);

    _team1Squad = _sanitizePlayers(team1Model?.playerNames ?? config.team1Players);
    _team2Squad = _sanitizePlayers(team2Model?.playerNames ?? config.team2Players);

    _team1Selected = _deriveInitialSelection(config.team1Players, _team1Squad);
    _team2Selected = _deriveInitialSelection(config.team2Players, _team2Squad);
  }

  TeamModel? _findTeamByName(String teamName, List<TeamModel> teams) {
    final target = teamName.trim().toLowerCase();
    for (final team in teams) {
      if (team.name.trim().toLowerCase() == target) {
        return team;
      }
    }
    return null;
  }

  List<String> _sanitizePlayers(List<String> players) {
    final seen = <String>{};
    final result = <String>[];
    for (final name in players) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        result.add(trimmed);
      }
    }
    return result;
  }

  Set<String> _deriveInitialSelection(List<String> preferred, List<String> squad) {
    final selected = <String>{};
    final squadLookup = <String, String>{
      for (final name in squad) name.toLowerCase(): name,
    };
    for (final player in preferred) {
      final trimmed = player.trim();
      if (trimmed.isEmpty) continue;
      final matched = squadLookup[trimmed.toLowerCase()];
      if (matched != null) {
        selected.add(matched);
      }
      if (selected.length == _maxSelectedPlayers) {
        return selected;
      }
    }
    return selected;
  }

  Future<void> _showAddPlayerDialog({required bool isTeam1}) async {
    final controller = TextEditingController();
    final teamName = isTeam1
        ? ref.read(matchSetupProvider).team1Name
        : ref.read(matchSetupProvider).team2Name;
    final addedName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Player'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Player name'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.of(context).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (!mounted || addedName == null) return;
    final saved = await _addPlayerToTeam(teamName: teamName, playerName: addedName, isTeam1: isTeam1);
    if (!saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save player to squad')));
    }
  }

  Future<bool> _addPlayerToTeam({
    required String teamName,
    required String playerName,
    required bool isTeam1,
  }) async {
    final trimmed = playerName.trim();
    if (trimmed.isEmpty) return false;
    final lookup = trimmed.toLowerCase();
    final teamsNotifier = ref.read(teamsProvider.notifier);
    final teams = ref.read(teamsProvider);
    final team = _findTeamByName(teamName, teams);
    if (team == null) return false;

    final current = _sanitizePlayers(team.playerNames);
    final exists = current.any((name) => name.toLowerCase() == lookup);
    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player already exists in squad')),
        );
      }
      return false;
    }

    final updated = team.copyWith(playerNames: <String>[...current, trimmed]);
    final saved = await teamsNotifier.saveTeam(updated);
    if (!saved) return false;
    setState(() {
      if (isTeam1) {
        _team1Squad = <String>[..._team1Squad, trimmed];
      } else {
        _team2Squad = <String>[..._team2Squad, trimmed];
      }
    });
    return true;
  }

  Future<void> _confirmDeletePlayer({
    required bool isTeam1,
    required String playerName,
  }) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove player'),
        content: Text('Remove $playerName from squad?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (shouldRemove != true || !mounted) return;

    final teamName = isTeam1
        ? ref.read(matchSetupProvider).team1Name
        : ref.read(matchSetupProvider).team2Name;
    final removed = await _removePlayerFromTeam(
      teamName: teamName,
      playerName: playerName,
      isTeam1: isTeam1,
    );
    if (!removed && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to remove player')));
    }
  }

  Future<bool> _removePlayerFromTeam({
    required String teamName,
    required String playerName,
    required bool isTeam1,
  }) async {
    final teamsNotifier = ref.read(teamsProvider.notifier);
    final teams = ref.read(teamsProvider);
    final team = _findTeamByName(teamName, teams);
    if (team == null) return false;
    final lookup = playerName.toLowerCase();

    final updatedRoster = _sanitizePlayers(team.playerNames)
        .where((name) => name.toLowerCase() != lookup)
        .toList();
    final updated = team.copyWith(playerNames: updatedRoster);
    final saved = await teamsNotifier.saveTeam(updated);
    if (!saved) return false;

    setState(() {
      if (isTeam1) {
        _team1Squad.removeWhere((name) => name.toLowerCase() == lookup);
        _team1Selected.removeWhere((name) => name.toLowerCase() == lookup);
      } else {
        _team2Squad.removeWhere((name) => name.toLowerCase() == lookup);
        _team2Selected.removeWhere((name) => name.toLowerCase() == lookup);
      }
    });
    return true;
  }

  void _toggleSelection({
    required bool isTeam1,
    required String playerName,
    required bool checked,
  }) {
    final selected = isTeam1 ? _team1Selected : _team2Selected;
    if (checked && selected.length >= _maxSelectedPlayers) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 15 players allowed')));
      return;
    }
    setState(() {
      if (isTeam1) {
        if (checked) {
          _team1Selected.add(playerName);
        } else {
          _team1Selected.remove(playerName);
        }
      } else {
        if (checked) {
          _team2Selected.add(playerName);
        } else {
          _team2Selected.remove(playerName);
        }
      }
    });
  }

  Future<void> _savePlayersAndNavigate() async {
    if (_team1Selected.length != _maxSelectedPlayers ||
        _team2Selected.length != _maxSelectedPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select exactly 15 players for each team')),
      );
      return;
    }
    final team1 = _team1Squad.where((player) => _team1Selected.contains(player)).toList();
    final team2 = _team2Squad.where((player) => _team2Selected.contains(player)).toList();
    ref.read(matchSetupProvider.notifier).updateTeamPlayers(
      team1Players: team1,
      team2Players: team2,
    );
    if (mounted) context.push('/rules');
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(matchSetupProvider);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Add Players')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView(
            children: <Widget>[
              _TeamSquadCard(
                teamName: config.team1Name,
                squad: _team1Squad,
                selected: _team1Selected,
                onToggle: (player, checked) =>
                    _toggleSelection(isTeam1: true, playerName: player, checked: checked),
                onAddNew: () => _showAddPlayerDialog(isTeam1: true),
                onDelete: (player) => _confirmDeletePlayer(isTeam1: true, playerName: player),
              ),
              const SizedBox(height: 16),
              _TeamSquadCard(
                teamName: config.team2Name,
                squad: _team2Squad,
                selected: _team2Selected,
                onToggle: (player, checked) =>
                    _toggleSelection(isTeam1: false, playerName: player, checked: checked),
                onAddNew: () => _showAddPlayerDialog(isTeam1: false),
                onDelete: (player) => _confirmDeletePlayer(isTeam1: false, playerName: player),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: Text('${config.team1Name}: ${_team1Selected.length} / 15 selected')),
                      Expanded(
                        child: Text(
                          '${config.team2Name}: ${_team2Selected.length} / 15 selected',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
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
      ),
    );
  }
}

class _TeamSquadCard extends StatelessWidget {
  const _TeamSquadCard({
    required this.teamName,
    required this.squad,
    required this.selected,
    required this.onToggle,
    required this.onAddNew,
    required this.onDelete,
  });

  final String teamName;
  final List<String> squad;
  final Set<String> selected;
  final void Function(String playerName, bool checked) onToggle;
  final VoidCallback onAddNew;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final isComplete = selected.length == _TeamSetupScreenState._maxSelectedPlayers;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    teamName,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isComplete ? Colors.green.withOpacity(0.15) : null,
                  ),
                  child: Text(
                    '${selected.length} / 15 selected',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isComplete ? Colors.green.shade700 : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isComplete)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Squad complete!',
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 8),
            if (squad.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('No players in squad yet. Add one below.'),
                ),
              )
            else
              ...squad.map((player) {
                final checked = selected.contains(player);
                final disabled = !checked && isComplete;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: disabled ? Theme.of(context).disabledColor.withOpacity(0.12) : null,
                  ),
                  child: CheckboxListTile(
                    value: checked,
                    onChanged: (value) => onToggle(player, value ?? false),
                    title: Text(
                      player,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: disabled ? Colors.grey : null,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    secondary: IconButton(
                      onPressed: () => onDelete(player),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove player',
                    ),
                  ),
                );
              }),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddNew,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add New Player'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
