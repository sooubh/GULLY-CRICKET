import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'match_setup_notifier.dart';

class TeamSetupScreen extends ConsumerStatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  ConsumerState<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends ConsumerState<TeamSetupScreen> {
  late List<TextEditingController> _team1Controllers;
  late List<TextEditingController> _team2Controllers;

  @override
  void initState() {
    super.initState();
    final config = ref.read(matchSetupProvider);
    _team1Controllers = _controllersFrom(config.team1Players, config.playersPerSide);
    _team2Controllers = _controllersFrom(config.team2Players, config.playersPerSide);
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
    });
  }

  void _addTeam2Player() {
    if (_team2Controllers.length >= 11) return;
    setState(() {
      _team2Controllers.add(TextEditingController());
    });
  }

  void _next() {
    final team1 = _team1Controllers
        .asMap()
        .entries
        .map((entry) => entry.value.text.trim().isEmpty ? 'Player ${entry.key + 1}' : entry.value.text.trim())
        .toList();
    final team2 = _team2Controllers
        .asMap()
        .entries
        .map((entry) => entry.value.text.trim().isEmpty ? 'Player ${entry.key + 1}' : entry.value.text.trim())
        .toList();
    if (team1.length != team2.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both teams must have equal player count')),
      );
      return;
    }
    ref.read(matchSetupProvider.notifier).updateTeamPlayers(team1Players: team1, team2Players: team2);
    context.push('/rules');
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(matchSetupProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Players')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _TeamSection(
            teamName: config.team1Name,
            controllers: _team1Controllers,
            onAddAnother: _addTeam1Player,
          ),
          const SizedBox(height: 20),
          _TeamSection(
            teamName: config.team2Name,
            controllers: _team2Controllers,
            onAddAnother: _addTeam2Player,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _next,
              child: const Text('Next: Set Rules →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection({
    required this.teamName,
    required this.controllers,
    required this.onAddAnother,
  });

  final String teamName;
  final List<TextEditingController> controllers;
  final VoidCallback onAddAnother;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(teamName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...controllers.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: 'Player ${entry.key + 1}',
                    hintText: 'Player ${entry.key + 1}',
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: controllers.length >= 11 ? null : onAddAnother,
                child: const Text('Add another player'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
