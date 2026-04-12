import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/match_status.dart';
import '../../multiplayer/services/host_service.dart';
import '../../scoring/domain/models/gully_rules_model.dart';
import '../../scoring/domain/models/match_model.dart';
import '../../scoring/domain/models/player_model.dart';
import '../../scoring/presentation/active_match_provider.dart';
import '../../storage/services/match_repository.dart';
import 'match_setup_notifier.dart';

class RulesConfigScreen extends ConsumerStatefulWidget {
  const RulesConfigScreen({super.key});

  @override
  ConsumerState<RulesConfigScreen> createState() => _RulesConfigScreenState();
}

class _RulesConfigScreenState extends ConsumerState<RulesConfigScreen> {
  late bool _halfCenturyRetire;
  late bool _centuryRetire;
  late bool _lastManBatsAlone;
  late bool _reEntryAllowed;
  late bool _tipOneHandOut;
  late bool _wallCatchOut;
  late bool _oneBounceCatchOut;
  late bool _noballFreeHit;
  late bool _lbwAllowed;
  late int _maxOversPerBowler;
  late bool _sixIsOut;
  late bool _enableMultiplayer;

  @override
  void initState() {
    super.initState();
    final config = ref.read(matchSetupProvider);
    _halfCenturyRetire = config.halfCenturyRetire;
    _centuryRetire = config.centuryRetire;
    _lastManBatsAlone = config.lastManBatsAlone;
    _reEntryAllowed = config.reEntryAllowed;
    _tipOneHandOut = config.tipOneHandOut;
    _wallCatchOut = config.wallCatchOut;
    _oneBounceCatchOut = config.oneBounceCatchOut;
    _noballFreeHit = config.noballFreeHit;
    _lbwAllowed = config.lbwAllowed;
    _maxOversPerBowler = config.maxOversPerBowler;
    _sixIsOut = config.sixIsOut;
    _enableMultiplayer = config.enableMultiplayer;
  }

  Future<void> _startMatch() async {
    final config = ref.read(matchSetupProvider);
    ref
        .read(matchSetupProvider.notifier)
        .updateRules(
          halfCenturyRetire: _halfCenturyRetire,
          centuryRetire: _centuryRetire,
          lastManBatsAlone: _lastManBatsAlone,
          reEntryAllowed: _reEntryAllowed,
          tipOneHandOut: _tipOneHandOut,
          wallCatchOut: _wallCatchOut,
          oneBounceCatchOut: _oneBounceCatchOut,
          noballFreeHit: _noballFreeHit,
          lbwAllowed: _lbwAllowed,
          maxOversPerBowler: _maxOversPerBowler,
          sixIsOut: _sixIsOut,
          enableMultiplayer: _enableMultiplayer,
        );

    final updated = ref.read(matchSetupProvider);
    final team1Players = updated.team1Players
        .asMap()
        .entries
        .map(
          (entry) => Player(
            id: const Uuid().v4(),
            name: entry.value,
            teamId: 'team1',
            battingPosition: entry.key + 1,
          ),
        )
        .toList();
    final team2Players = updated.team2Players
        .asMap()
        .entries
        .map(
          (entry) => Player(
            id: const Uuid().v4(),
            name: entry.value,
            teamId: 'team2',
            battingPosition: entry.key + 1,
          ),
        )
        .toList();

    final rules = GullyRules(
      halfCenturyRetire: updated.halfCenturyRetire,
      centuryRetire: updated.centuryRetire,
      lastManBatsAlone: updated.lastManBatsAlone,
      reEntryAllowed: updated.reEntryAllowed,
      tipOneHandOut: updated.tipOneHandOut,
      wallCatchOut: updated.wallCatchOut,
      oneBounceCatchOut: updated.oneBounceCatchOut,
      noballFreeHit: updated.noballFreeHit,
      lbwAllowed: updated.lbwAllowed,
      maxOversPerBowler: updated.maxOversPerBowler,
      sixIsOut: updated.sixIsOut,
      ballsPerOver: updated.ballsPerOver,
      totalOvers: updated.totalOvers,
      team1Players: updated.team1Players.length,
      team2Players: updated.team2Players.length,
    );

    final match = MatchModel(
      id: const Uuid().v4(),
      team1Name: updated.team1Name,
      team2Name: updated.team2Name,
      team1Players: team1Players,
      team2Players: team2Players,
      rules: rules,
      status: MatchStatus.liveFirstInnings,
    );

    await ref.read(matchListProvider.notifier).saveMatch(match);
    await ref.read(activeMatchProvider.notifier).setMatch(match);

    if (updated.enableMultiplayer) {
      await ref.read(hostServiceProvider).startServer(match);
      if (mounted) context.go('/host');
      return;
    }
    if (mounted) context.go('/live');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Rules')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Text(
                  'Set your gully rules — all optional',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: <Widget>[
                      const ListTile(title: Text('🏏 Batting Rules')),
                      SwitchListTile(
                        title: const Text('Retire at 50 runs'),
                        value: _halfCenturyRetire,
                        onChanged: (value) => setState(() => _halfCenturyRetire = value),
                      ),
                      SwitchListTile(
                        title: const Text('Retire at 100 runs'),
                        value: _centuryRetire,
                        onChanged: (value) => setState(() => _centuryRetire = value),
                      ),
                      SwitchListTile(
                        title: const Text('Last man bats alone'),
                        value: _lastManBatsAlone,
                        onChanged: (value) => setState(() => _lastManBatsAlone = value),
                      ),
                      SwitchListTile(
                        title: const Text('Re-entry allowed (retired batsman can return)'),
                        value: _reEntryAllowed,
                        onChanged: (value) => setState(() => _reEntryAllowed = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: <Widget>[
                      const ListTile(title: Text('🤲 Fielding Rules')),
                      SwitchListTile(
                        title: const Text('1-Tip 1-Hand = Out'),
                        value: _tipOneHandOut,
                        onChanged: (value) => setState(() => _tipOneHandOut = value),
                      ),
                      SwitchListTile(
                        title: const Text('Wall catch = Out'),
                        value: _wallCatchOut,
                        onChanged: (value) => setState(() => _wallCatchOut = value),
                      ),
                      SwitchListTile(
                        title: const Text('One-bounce catch = Out'),
                        value: _oneBounceCatchOut,
                        onChanged: (value) => setState(() => _oneBounceCatchOut = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: <Widget>[
                      const ListTile(title: Text('🎯 Bowling Rules')),
                      SwitchListTile(
                        title: const Text('No-ball gives free hit'),
                        value: _noballFreeHit,
                        onChanged: (value) => setState(() => _noballFreeHit = value),
                      ),
                      SwitchListTile(
                        title: const Text('LBW rule'),
                        value: _lbwAllowed,
                        onChanged: (value) => setState(() => _lbwAllowed = value),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: <Widget>[
                            const Expanded(child: Text('Max overs per bowler')),
                            IconButton(
                              onPressed: _maxOversPerBowler == 0
                                  ? null
                                  : () => setState(() => _maxOversPerBowler--),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$_maxOversPerBowler'),
                            IconButton(
                              onPressed: () => setState(() => _maxOversPerBowler++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: <Widget>[
                      const ListTile(title: Text('🚀 Boundary Rules')),
                      SwitchListTile(
                        title: const Text('6 = Batsman OUT (gully rule)'),
                        value: _sixIsOut,
                        onChanged: (value) => setState(() => _sixIsOut = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Enable Multiplayer (WiFi)'),
                  value: _enableMultiplayer,
                  onChanged: (value) => setState(() => _enableMultiplayer = value),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startMatch,
                    child: const Text('🏏 Start Match'),
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
