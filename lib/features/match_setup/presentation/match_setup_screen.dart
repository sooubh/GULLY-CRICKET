import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../teams/domain/team_model.dart';
import '../../teams/services/teams_service.dart';
import 'match_setup_notifier.dart';

class MatchSetupScreen extends ConsumerStatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  static const String _defaultTeamAName = 'Team A';
  static const String _defaultTeamBName = 'Team B';
  late final TextEditingController _team1Controller;
  late final TextEditingController _team2Controller;
  late int _totalOvers;
  late int _ballsPerOver;
  late int _team1PlayerCount;
  late int _team2PlayerCount;
  late bool _enableToss;
  String? _team1SavedId;
  String? _team2SavedId;
  List<String> _team1PresetPlayers = const <String>[];
  List<String> _team2PresetPlayers = const <String>[];

  @override
  void initState() {
    super.initState();
    final config = ref.read(matchSetupProvider);
    final team1Lookup = config.team1Name.trim().toLowerCase();
    final team2Lookup = config.team2Name.trim().toLowerCase();
    String? resolvedTeam1Name;
    String? resolvedTeam2Name;
    final teams = ref.read(teamsProvider);
    for (final team in teams) {
      if (team.name.trim().toLowerCase() == team1Lookup) {
        _team1SavedId = team.id;
        resolvedTeam1Name = team.name;
        _team1PresetPlayers = team.playerNames.where((name) => name.trim().isNotEmpty).toList();
      }
      if (team.name.trim().toLowerCase() == team2Lookup) {
        _team2SavedId = team.id;
        resolvedTeam2Name = team.name;
        _team2PresetPlayers = team.playerNames.where((name) => name.trim().isNotEmpty).toList();
      }
    }
    final team1Initial = resolvedTeam1Name ??
        (team1Lookup == _defaultTeamAName.toLowerCase() ? '' : config.team1Name);
    final team2Initial = resolvedTeam2Name ??
        (team2Lookup == _defaultTeamBName.toLowerCase() ? '' : config.team2Name);
    _team1Controller = TextEditingController(text: team1Initial);
    _team2Controller = TextEditingController(text: team2Initial);
    _totalOvers = config.totalOvers;
    _ballsPerOver = config.ballsPerOver;
    _team1PlayerCount = config.team1PlayerCount;
    _team2PlayerCount = config.team2PlayerCount;
    _enableToss = config.enableToss;
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    super.dispose();
  }

  void _handleNext() {
    final team1 = _team1Controller.text.trim();
    final team2 = _team2Controller.text.trim();
    if (team1.isEmpty || team2.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Team names cannot be empty')));
      return;
    }
    if (_team1SavedId == null || _team2SavedId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select both saved teams')));
      return;
    }
    if (team1 == team2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Both teams cannot be the same')));
      return;
    }

    final team1Players = _team1PresetPlayers.isEmpty
        ? List<String>.filled(_team1PlayerCount, '')
        : _team1PresetPlayers;
    final team2Players = _team2PresetPlayers.isEmpty
        ? List<String>.filled(_team2PlayerCount, '')
        : _team2PresetPlayers;

    final setup = ref.read(matchSetupProvider.notifier);
    setup.updateTeamPlayers(team1Players: team1Players, team2Players: team2Players);
    setup.updateBase(
      team1Name: team1,
      team2Name: team2,
      totalOvers: _totalOvers,
      ballsPerOver: _ballsPerOver,
      team1PlayerCount: _team1PlayerCount,
      team2PlayerCount: _team2PlayerCount,
      enableToss: _enableToss,
    );
    context.push('/setup/teams');
  }

  void _selectSavedTeam({required TeamModel team, required bool isTeam1}) {
    final players = team.playerNames.where((name) => name.trim().isNotEmpty).toList();
    final otherId = isTeam1 ? _team2SavedId : _team1SavedId;
    if (otherId == team.id) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Both teams cannot be the same')));
      return;
    }
    setState(() {
      if (isTeam1) {
        _team1SavedId = team.id;
        _team1Controller.text = team.name;
        _team1PresetPlayers = players;
      } else {
        _team2SavedId = team.id;
        _team2Controller.text = team.name;
        _team2PresetPlayers = players;
      }
    });
  }

  Future<void> _openTeamPicker({required bool isTeam1}) async {
    final teams = ref.read(teamsProvider);
    final selectedOtherId = isTeam1 ? _team2SavedId : _team1SavedId;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isTeam1 ? 'Select Team A' : 'Select Team B',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: teams.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('No saved teams yet. Create one below.'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: teams.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final team = teams[index];
                            final isDisabled = team.id == selectedOtherId;
                            final playerCount = team.playerNames
                                .where((name) => name.trim().isNotEmpty)
                                .length;
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isDisabled
                                    ? Theme.of(context).disabledColor.withOpacity(0.12)
                                    : null,
                              ),
                              child: ListTile(
                                minVerticalPadding: 12,
                                enabled: !isDisabled,
                                onTap: isDisabled
                                    ? null
                                    : () {
                                        Navigator.of(sheetContext).pop();
                                        _selectSavedTeam(team: team, isTeam1: isTeam1);
                                      },
                                title: Text(
                                  team.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDisabled ? Colors.grey : null,
                                  ),
                                ),
                                subtitle: Text(
                                  '$playerCount players',
                                  style: TextStyle(color: isDisabled ? Colors.grey : null),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                ListTile(
                  minVerticalPadding: 12,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(
                    Icons.add_circle_outline,
                    color: Colors.green.shade400,
                  ),
                  title: Text(
                    'Create New Team',
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/teams/create');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('New Match')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Text('Match Settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: _team1Controller,
                          readOnly: true,
                          showCursor: false,
                          onTap: () => _openTeamPicker(isTeam1: true),
                          decoration: const InputDecoration(
                            labelText: 'Team 1 Name',
                            hintText: 'Tap to select team',
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _team2Controller,
                          readOnly: true,
                          showCursor: false,
                          onTap: () => _openTeamPicker(isTeam1: false),
                          decoration: const InputDecoration(
                            labelText: 'Team 2 Name',
                            hintText: 'Tap to select team',
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const Expanded(child: Text('Total Overs')),
                    Text(_totalOvers.toString()),
                  ],
                ),
                Slider(
                  min: 1,
                  max: 20,
                  divisions: 19,
                  value: _totalOvers.toDouble(),
                  onChanged: (value) => setState(() => _totalOvers = value.round()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Expanded(child: Text('Balls per Over')),
                    Wrap(
                      spacing: 8,
                      children: <int>[4, 5, 6]
                          .map(
                            (balls) => ChoiceChip(
                              label: Text('$balls'),
                              selected: _ballsPerOver == balls,
                              onSelected: (_) => setState(() => _ballsPerOver = balls),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          const Text('Team A Players'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _team1PlayerCount > 1
                                    ? () => setState(() => _team1PlayerCount--)
                                    : null,
                              ),
                              Text(
                                '$_team1PlayerCount',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _team1PlayerCount < 11
                                    ? () => setState(() => _team1PlayerCount++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 60, color: AppColors.dotGray),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          const Text('Team B Players'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _team2PlayerCount > 1
                                    ? () => setState(() => _team2PlayerCount--)
                                    : null,
                              ),
                              Text(
                                '$_team2PlayerCount',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _team2PlayerCount < 11
                                    ? () => setState(() => _team2PlayerCount++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_team1PlayerCount != _team2PlayerCount)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '⚡ Uneven match: $_team1PlayerCount vs $_team2PlayerCount',
                      style: const TextStyle(color: AppColors.accentGold, fontSize: 12),
                    ),
                  ),
                SwitchListTile(
                  title: const Text('Enable Toss'),
                  value: _enableToss,
                  onChanged: (value) => setState(() => _enableToss = value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    child: const Text('Next: Add Players →'),
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
