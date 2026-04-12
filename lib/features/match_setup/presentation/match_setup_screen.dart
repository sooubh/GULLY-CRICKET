import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'match_setup_notifier.dart';

class MatchSetupScreen extends ConsumerStatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  late final TextEditingController _team1Controller;
  late final TextEditingController _team2Controller;
  late int _totalOvers;
  late int _ballsPerOver;
  late int _team1PlayerCount;
  late int _team2PlayerCount;
  late bool _enableToss;

  @override
  void initState() {
    super.initState();
    final config = ref.read(matchSetupProvider);
    _team1Controller = TextEditingController(text: config.team1Name);
    _team2Controller = TextEditingController(text: config.team2Name);
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

    ref
        .read(matchSetupProvider.notifier)
        .updateBase(
          team1Name: team1,
          team2Name: team2,
          totalOvers: _totalOvers,
          ballsPerOver: _ballsPerOver,
          team1PlayerCount: _team1PlayerCount,
          team2PlayerCount: _team2PlayerCount,
          enableToss: _enableToss,
        );
    context.push('/teams');
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
                TextField(
                  controller: _team1Controller,
                  decoration: const InputDecoration(labelText: 'Team 1 Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _team2Controller,
                  decoration: const InputDecoration(labelText: 'Team 2 Name'),
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
