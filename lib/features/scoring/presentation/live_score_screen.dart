import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/hive_keys.dart';
import '../../../core/constants/match_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../audio/sound_service.dart';
import '../../multiplayer/services/host_service.dart';
import '../domain/engines/match_engine.dart';
import '../domain/engines/rule_engine.dart';
import '../domain/models/ball_model.dart';
import '../domain/models/gully_rules_model.dart';
import '../domain/models/innings_model.dart';
import '../domain/models/match_model.dart';
import '../domain/models/player_model.dart';
import 'active_match_provider.dart';
import 'select_batsman_screen.dart';
import 'select_bowler_screen.dart';
import 'widgets/ball_timeline.dart';
import 'widgets/quick_action_bar.dart';
import 'widgets/score_pad.dart';
import 'widgets/scoreboard_header.dart';

class LiveScoreScreen extends ConsumerStatefulWidget {
  const LiveScoreScreen({super.key});

  @override
  ConsumerState<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends ConsumerState<LiveScoreScreen> {
  static const Uuid _uuid = Uuid();
  static const RuleEngine _ruleEngine = RuleEngine();
  static const MatchEngine _matchEngine = MatchEngine();
  bool _undoArmed = false;
  Timer? _undoTimer;
  Timer? _celebrationTimer;
  Timer? _wicketFlashTimer;
  OverlayEntry? _celebrationOverlay;
  bool _bootstrapped = false;
  bool _sheetOpen = false;
  bool _showWicketFlash = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapIfNeeded());
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _celebrationTimer?.cancel();
    _wicketFlashTimer?.cancel();
    _removeCelebrationOverlay();
    super.dispose();
  }

  Future<void> _bootstrapIfNeeded() async {
    if (_bootstrapped || !mounted) return;
    _bootstrapped = true;
    final match = ref.read(activeMatchProvider);
    if (match == null) return;

    var active = match;
    if (active.currentInnings == null) {
      final first = Innings(
        id: '${active.id}_innings_1',
        battingTeamId: active.battingFirstTeamId,
        bowlingTeamId: active.battingFirstTeamId == 'team1' ? 'team2' : 'team1',
        inningsNumber: 1,
      );
      final initialized = active.copyWith(
        firstInnings: first,
        status: MatchStatus.liveFirstInnings,
      );
      await ref.read(activeMatchProvider.notifier).setMatch(initialized);
      active = initialized;
    }
    await _ensureReadyForBall(active);
  }

  Future<void> _handleRun(int runs) async {
    final updated = await _recordStandardDelivery(runs: runs);
    if (updated == null) return;
    if (runs == 6) {
      await _triggerSixCelebration();
    } else if (runs == 4) {
      await _triggerFourCelebration();
    } else {
      await HapticFeedback.selectionClick();
    }
  }

  Future<MatchModel?> _recordStandardDelivery({
    int runs = 0,
    bool isWide = false,
    bool isNoBall = false,
    bool isBye = false,
    bool isLegBye = false,
  }) async {
    final match = ref.read(activeMatchProvider);
    if (match == null) return null;
    final ready = await _ensureReadyForBall(match);
    if (!ready) return null;
    final current = ref.read(activeMatchProvider);
    if (current == null) return null;
    final innings = current.currentInnings;
    if (innings == null) return null;

    final batsmanId = innings.currentBatsmanId;
    final bowlerId = innings.currentBowlerId;
    if (batsmanId == null || bowlerId == null) return null;

    final ball = _buildBall(
      match: current,
      innings: innings,
      batsmanId: batsmanId,
      bowlerId: bowlerId,
      runs: runs,
      isWide: isWide,
      isNoBall: isNoBall,
      isBye: isBye,
      isLegBye: isLegBye,
    );
    return _recordAndHandleFlow(ball: ball, preMatch: current, facedBatsmanId: batsmanId);
  }

  Future<void> _handleOut() async {
    final match = ref.read(activeMatchProvider);
    if (match == null) return;
    final ready = await _ensureReadyForBall(match);
    if (!ready) return;
    final current = ref.read(activeMatchProvider);
    if (current == null) return;
    final innings = current.currentInnings;
    if (innings == null) return;
    final batsmanId = innings.currentBatsmanId;
    final bowlerId = innings.currentBowlerId;
    if (batsmanId == null || bowlerId == null) return;

    final wicketType = await _showWicketTypePicker(current.rules);
    if (wicketType == null) return;

    if (wicketType == 'retired') {
      await ref.read(activeMatchProvider.notifier).retireBatsman(batsmanId);
      await _broadcastIfHosting();
      _showTopSnackBar('Batsman retired. Select next batsman.');
      await _selectNextBatsman(striker: true);
      return;
    }

    final ball = _buildBall(
      match: current,
      innings: innings,
      batsmanId: batsmanId,
      bowlerId: bowlerId,
      isWicket: true,
      wicketType: wicketType,
      dismissedPlayerId: batsmanId,
    );
    final updated = await _recordAndHandleFlow(
      ball: ball,
      preMatch: current,
      facedBatsmanId: batsmanId,
    );
    await _triggerWicketCelebration();
    if (updated?.currentInnings?.isCompleted != true) {
      await _selectNextBatsman(striker: true);
    }
  }

  void _showCelebration({
    required String text,
    required Color color,
    required double fontSize,
    required Duration duration,
  }) {
    _celebrationTimer?.cancel();
    _removeCelebrationOverlay();
    if (!mounted) return;
    final overlayState = Overlay.of(context);
    final topOffset = MediaQuery.of(context).size.height * 0.35;
    _celebrationOverlay = OverlayEntry(
      builder: (_) => Positioned(
        top: topOffset,
        left: 0,
        right: 0,
        child: Center(
          child: IgnorePointer(
            child: Text(
              text,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
            )
                .animate()
                .fadeIn(duration: 200.ms)
                .then(delay: duration)
                .fadeOut(duration: 300.ms),
          ),
        ),
      ),
    );
    overlayState.insert(_celebrationOverlay!);
    _celebrationTimer = Timer(duration + const Duration(milliseconds: 500), () {
      _removeCelebrationOverlay();
    });
  }

  void _removeCelebrationOverlay() {
    _celebrationOverlay?.remove();
    _celebrationOverlay = null;
  }

  void _showTopSnackBar(String message) {
    if (!mounted) return;
    final screenHeight = MediaQuery.of(context).size.height;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: screenHeight * 0.72,
            left: 16,
            right: 16,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _triggerFourCelebration() async {
    _showCelebration(
      text: 'FOUR! 🏏',
      color: AppColors.primaryGreen,
      fontSize: 48,
      duration: const Duration(milliseconds: 1500),
    );
    await HapticFeedback.mediumImpact();
    await ref.read(soundServiceProvider).playFour();
  }

  Future<void> _triggerSixCelebration() async {
    _showCelebration(
      text: 'SIX! 💥',
      color: AppColors.accentGold,
      fontSize: 60,
      duration: const Duration(milliseconds: 2000),
    );
    await ref.read(soundServiceProvider).playSix();
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      if (i < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _triggerWicketCelebration() async {
    _wicketFlashTimer?.cancel();
    if (!mounted) return;
    setState(() => _showWicketFlash = true);
    _wicketFlashTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _showWicketFlash = false);
    });
    _showCelebration(
      text: 'OUT! 🎯',
      color: AppColors.wicketRed,
      fontSize: 52,
      duration: const Duration(milliseconds: 1500),
    );
    await HapticFeedback.heavyImpact();
    await ref.read(soundServiceProvider).playWicket();
  }

  Future<void> _handleUndo() async {
    if (!_undoArmed) {
      setState(() => _undoArmed = true);
      _undoTimer?.cancel();
      _undoTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _undoArmed = false);
      });
      if (mounted) {
        _showTopSnackBar('Tap again to confirm undo');
      }
      return;
    }

    _undoTimer?.cancel();
    setState(() => _undoArmed = false);
    await ref.read(activeMatchProvider.notifier).undoLastBall();
    await _broadcastIfHosting();
  }

  Future<MatchModel?> _recordAndHandleFlow({
    required Ball ball,
    required MatchModel preMatch,
    required String facedBatsmanId,
  }) async {
    final updated = await ref.read(activeMatchProvider.notifier).recordBall(ball);
    if (updated == null) return null;
    await _broadcastIfHosting();
    final innings = updated.currentInnings;
    if (innings == null) return updated;

    if (innings.isCompleted) {
      await _handleInningsComplete(updated);
      return updated;
    }

    final beforeInnings = preMatch.currentInnings;
    if (beforeInnings != null) {
      final beforeBalls = beforeInnings.legalBallsCount();
      final afterBalls = innings.legalBallsCount();
      if (afterBalls > beforeBalls && afterBalls % updated.rules.ballsPerOver == 0) {
        await _selectNextBowler(overComplete: true);
      }

      final beforeBatter = _playerById(preMatch, beforeInnings.battingTeamId, facedBatsmanId);
      final afterBatter = _playerById(updated, innings.battingTeamId, facedBatsmanId);
      final autoRetired =
          beforeBatter != null && afterBatter != null && !beforeBatter.isRetired && afterBatter.isRetired;
      if (autoRetired) {
        _showTopSnackBar('${afterBatter.name} has retired! Select next batsman');
        await _selectNextBatsman(striker: true);
      }
    }
    return updated;
  }

  Future<void> _handleInningsComplete(MatchModel match) async {
    final innings = match.currentInnings;
    if (innings == null) return;
    if (innings.inningsNumber == 1) {
      _showTopSnackBar('Innings complete. Starting second innings...');
      final second = await ref.read(activeMatchProvider.notifier).startSecondInnings();
      if (second != null) {
        await _broadcastIfHosting();
        await _ensureReadyForBall(second);
      }
      return;
    }
    await ref.read(activeMatchProvider.notifier).completeMatch();
    await _broadcastIfHosting();
    if (mounted) context.go('/result');
  }

  Future<bool> _ensureReadyForBall(MatchModel source) async {
    var match = ref.read(activeMatchProvider) ?? source;
    var innings = match.currentInnings;
    if (innings == null) return false;

    if (innings.currentBatsmanId == null) {
      final selected = await _selectNextBatsman(striker: true);
      if (!selected) return false;
      match = ref.read(activeMatchProvider) ?? match;
      innings = match.currentInnings;
      if (innings == null) return false;
    }

    if (innings.currentNonStrikerId == null) {
      final selected = await _selectNextBatsman(striker: false);
      if (!selected) return false;
      match = ref.read(activeMatchProvider) ?? match;
      innings = match.currentInnings;
      if (innings == null) return false;
    }

    if (innings.currentBowlerId == null) {
      final selected = await _selectNextBowler();
      if (!selected) return false;
    }
    return true;
  }

  Future<bool> _selectNextBatsman({required bool striker}) async {
    if (_sheetOpen) return false;
    final match = ref.read(activeMatchProvider);
    final innings = match?.currentInnings;
    if (match == null || innings == null || !mounted) return false;

    final batting = innings.battingTeamId == 'team1' ? match.team1Players : match.team2Players;
    _sheetOpen = true;
    final selected = await SelectBatsmanScreen.show(
      context,
      battingPlayers: batting,
      strikerId: innings.currentBatsmanId,
      nonStrikerId: innings.currentNonStrikerId,
      reEntryAllowed: match.rules.reEntryAllowed,
      title: striker ? 'Select striker' : 'Select non-striker',
      onNoAvailable: () async {
        final updated = await ref.read(activeMatchProvider.notifier).triggerInningsEndIfNeeded();
        if (updated != null && updated.currentInnings?.isCompleted == true) {
          await _broadcastIfHosting();
          await _handleInningsComplete(updated);
        }
      },
    );
    _sheetOpen = false;
    if (selected == null) return false;
    await ref.read(activeMatchProvider.notifier).setBatsman(selected.id, isStriker: striker);
    await _broadcastIfHosting();
    return true;
  }

  Future<bool> _selectNextBowler({bool overComplete = false}) async {
    if (_sheetOpen) return false;
    final match = ref.read(activeMatchProvider);
    final innings = match?.currentInnings;
    if (match == null || innings == null || !mounted) return false;

    final bowling = innings.bowlingTeamId == 'team1' ? match.team1Players : match.team2Players;
    final lastBowlerId = innings.currentBowlerId;
    final eligible = _ruleEngine.eligibleBowlers(
      bowlingTeamPlayers: bowling,
      overs: innings.overs,
      rules: match.rules,
      lastBowlerId: lastBowlerId,
    );
    _sheetOpen = true;
    final selected = await SelectBowlerScreen.show(
      context,
      bowlers: eligible.isEmpty ? bowling : eligible,
      title: overComplete ? 'Over Complete — Select next bowler' : 'Select bowler',
      overs: innings.overs,
      ballsPerOver: match.rules.ballsPerOver,
    );
    _sheetOpen = false;
    if (selected == null) return false;
    await ref.read(activeMatchProvider.notifier).setBowler(selected.id);
    await _broadcastIfHosting();
    return true;
  }

  Future<String?> _showWicketTypePicker(GullyRules rules) async {
    if (!mounted) return null;
    final options = <MapEntry<String, String>>[
      const MapEntry('bowled', 'Bowled'),
      const MapEntry('caught', 'Caught'),
      const MapEntry('run_out', 'Run Out'),
      const MapEntry('stumped', 'Stumped'),
      if (rules.tipOneHandOut) const MapEntry('tip_catch', 'Tip Catch'),
      if (rules.lbwAllowed) const MapEntry('lbw', 'LBW'),
      const MapEntry('retired', 'Retired'),
    ];
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
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
            child: ListView(
              controller: scrollController,
              children: <Widget>[
                const ListTile(title: Text('Select Wicket Type')),
                ...options.map(
                  (entry) => ListTile(
                    title: Text(entry.value),
                    onTap: () => Navigator.of(context).pop(entry.key),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Ball _buildBall({
    required MatchModel match,
    required Innings innings,
    required String batsmanId,
    required String bowlerId,
    int runs = 0,
    bool isWicket = false,
    bool isWide = false,
    bool isNoBall = false,
    bool isBye = false,
    bool isLegBye = false,
    String? wicketType,
    String? dismissedPlayerId,
  }) {
    final previousBall = innings.allBalls.isEmpty ? null : innings.allBalls.last;
    final activeOver = innings.overs.isEmpty
        ? null
        : (innings.overs.last.isComplete(match.rules.ballsPerOver) ? null : innings.overs.last);
    final overNumber = activeOver?.overNumber ?? innings.overs.length;
    final ballInOver = (activeOver?.legalBallCount ?? 0) + 1;
    final deliveryRuns = (isWide || isNoBall) ? 1 + runs : runs;

    return Ball(
      id: _uuid.v4(),
      bowlerId: bowlerId,
      batsmanId: batsmanId,
      overNumber: overNumber,
      ballInOver: ballInOver,
      runsScored: runs,
      isWicket: isWicket,
      isWide: isWide,
      isNoBall: isNoBall,
      isBye: isBye,
      isLegBye: isLegBye,
      isFreeHit: _ruleEngine.isFreeHit(previousBall, match.rules),
      wicketType: wicketType,
      dismissedPlayerId: dismissedPlayerId,
      totalRunsAfterBall: innings.totalRuns + deliveryRuns,
    );
  }

  Future<void> _broadcastIfHosting() async {
    final host = ref.read(hostServiceProvider);
    final match = ref.read(activeMatchProvider);
    if (host.isHosting && match != null) {
      host.broadcastMatchState(match);
    }
  }

  Player? _playerById(MatchModel match, String teamId, String playerId) {
    final team = teamId == 'team1' ? match.team1Players : match.team2Players;
    for (final player in team) {
      if (player.id == playerId) return player;
    }
    return null;
  }

  Player? _findPlayer(List<Player> players, String? id) {
    if (id == null) return null;
    for (final player in players) {
      if (player.id == id) return player;
    }
    return null;
  }

  List<Ball> _currentOverBalls(Innings innings) {
    if (innings.overs.isEmpty) return const <Ball>[];
    for (var i = innings.overs.length - 1; i >= 0; i--) {
      if (innings.overs[i].balls.isNotEmpty) return innings.overs[i].balls;
    }
    return const <Ball>[];
  }

  _BowlerFigures _bowlerFigures(Innings innings, MatchModel match, String? bowlerId) {
    if (bowlerId == null) {
      return const _BowlerFigures(
        oversText: '0.0',
        maidens: 0,
        runs: 0,
        wickets: 0,
        economy: 0,
      );
    }
    final overs = innings.overs.where((o) => o.bowlerId == bowlerId && o.balls.isNotEmpty).toList();
    final legalBalls = overs.fold<int>(0, (sum, over) => sum + over.legalBallCount);
    final runs = overs.fold<int>(0, (sum, over) => sum + over.runsInOver);
    final wickets = overs.fold<int>(0, (sum, over) => sum + over.wicketsInOver);
    final maidens =
        overs.where((over) => over.isComplete(match.rules.ballsPerOver) && over.runsInOver == 0).length;
    final oversText = '${legalBalls ~/ match.rules.ballsPerOver}.${legalBalls % match.rules.ballsPerOver}';
    final economyRate = legalBalls == 0 ? 0.0 : (runs / legalBalls) * match.rules.ballsPerOver;
    return _BowlerFigures(
      oversText: oversText,
      maidens: maidens,
      runs: runs,
      wickets: wickets,
      economy: economyRate,
    );
  }

  Future<void> _showWifiInfo() async {
    final host = ref.read(hostServiceProvider);
    final match = ref.read(activeMatchProvider);
    if (!mounted || match == null) return;
    if (host.isHosting) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hosting Live'),
          content: Text('IP: ${host.hostIp}\nClients: ${host.connectedClients}'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Not hosting yet'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await host.startServer(match);
                    host.broadcastMatchState(match);
                    if (mounted) {
                      Navigator.of(context).pop();
                      _showTopSnackBar('Hosting started at ${host.hostIp}');
                    }
                  },
                  icon: const Icon(Icons.wifi_tethering),
                  label: const Text('Start Hosting'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(activeMatchProvider);
    if (match == null) {
      return const Scaffold(
        body: Center(child: Text('No active match')),
      );
    }
    final innings = match.currentInnings;
    if (innings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final batting = innings.battingTeamId == 'team1' ? match.team1Players : match.team2Players;
    final bowling = innings.bowlingTeamId == 'team1' ? match.team1Players : match.team2Players;
    final striker = _findPlayer(batting, innings.currentBatsmanId);
    final nonStriker = _findPlayer(batting, innings.currentNonStrikerId);
    final bowler = _findPlayer(bowling, innings.currentBowlerId);
    final bowlerFigures = _bowlerFigures(innings, match, bowler?.id);

    final allBalls = _currentOverBalls(innings);
    final partnershipInfo = _matchEngine.currentPartnership(innings);
    final partnershipText = 'Partner: ${partnershipInfo.runs}(${partnershipInfo.balls})';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            _showTopSnackBar('Menu coming soon');
                          },
                          icon: const Icon(Icons.menu),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'LIVE',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/result'),
                          icon: const Icon(Icons.bar_chart),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ScoreboardHeader(match: match, innings: innings),
                ),
                SizedBox(
                  height: 96,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Column(
                      children: <Widget>[
                        _PlayerLine(
                          icon: '🟢',
                          name: '${striker?.name ?? 'Select striker'}*',
                          stats:
                              '${striker?.runsScored ?? 0}(${striker?.ballsFaced ?? 0})  SR: ${(striker?.strikeRate ?? 0).toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 6),
                        _PlayerLine(
                          icon: '🔵',
                          name: nonStriker?.name ?? 'Select non-striker',
                          stats:
                              '${nonStriker?.runsScored ?? 0}(${nonStriker?.ballsFaced ?? 0})  SR: ${(nonStriker?.strikeRate ?? 0).toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 6),
                        _PlayerLine(
                          icon: '🎯',
                          name: bowler?.name ?? 'Select bowler',
                          stats:
                              '${bowlerFigures.oversText}-${bowlerFigures.maidens}-${bowlerFigures.runs}-${bowlerFigures.wickets}  Eco: ${bowlerFigures.economy.toStringAsFixed(1)}',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: BallTimeline(balls: allBalls),
                  ),
                ),
                Expanded(
                  child: ScorePad(
                    onRun: _handleRun,
                    onWide: () async {
                      await HapticFeedback.selectionClick();
                      await _recordStandardDelivery(isWide: true);
                    },
                    onNoBall: () async {
                      await HapticFeedback.selectionClick();
                      await _recordStandardDelivery(isNoBall: true);
                    },
                    onBye: () async {
                      await HapticFeedback.selectionClick();
                      await _recordStandardDelivery(runs: 1, isBye: true);
                    },
                    onLegBye: () async {
                      await HapticFeedback.selectionClick();
                      await _recordStandardDelivery(runs: 1, isLegBye: true);
                    },
                    onOut: _handleOut,
                    onUndo: _handleUndo,
                    undoArmed: _undoArmed,
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
                    child: QuickActionBar(
                      partnership: partnershipText,
                      onSwap: () async {
                        final strikerId = innings.currentBatsmanId;
                        final nonId = innings.currentNonStrikerId;
                        if (strikerId == null || nonId == null) return;
                        await ref.read(activeMatchProvider.notifier).swapStrike();
                        await _broadcastIfHosting();
                      },
                      onSettings: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: SafeArea(
                              child: ValueListenableBuilder<Box<dynamic>>(
                                valueListenable:
                                    Hive.box<dynamic>(
                                      HiveKeys.settingsBox,
                                    ).listenable(keys: const <String>['sound_enabled']),
                                builder: (context, settings, _) {
                                  final soundEnabled =
                                      (settings.get('sound_enabled', defaultValue: true) as bool?) ??
                                      true;
                                  return ListView(
                                    shrinkWrap: true,
                                    children: <Widget>[
                                      const ListTile(title: Text('Match Settings')),
                                      ListTile(title: Text('Overs: ${match.rules.totalOvers}')),
                                      ListTile(title: Text('Balls/Over: ${match.rules.ballsPerOver}')),
                                      ListTile(
                                        title: Text(
                                          'Players: ${match.rules.team1Players} vs ${match.rules.team2Players}',
                                        ),
                                      ),
                                      SwitchListTile(
                                        title: const Text('Sound Effects'),
                                        value: soundEnabled,
                                        onChanged: (value) async {
                                          await ref.read(soundServiceProvider).setEnabled(value);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onWifi: _showWifiInfo,
                    ),
                  ),
                ),
              ],
            ),
            if (_showWicketFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: AppColors.wicketRed.withOpacity(0.1)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({
    required this.icon,
    required this.name,
    required this.stats,
  });

  final String icon;
  final String name;
  final String stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$name   $stats',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BowlerFigures {
  const _BowlerFigures({
    required this.oversText,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });

  final String oversText;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;
}
