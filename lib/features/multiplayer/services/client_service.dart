import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web_socket_channel/io.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/hive_keys.dart';
import '../../scoring/domain/models/match_model.dart';
import '../../storage/services/match_repository.dart';
import '../domain/sync_event.dart';

enum SyncStage { syncing, synced, reconnecting, failed }

class SyncStatusState {
  const SyncStatusState({
    required this.stage,
    this.scoreText,
    this.oversText,
    this.attempt,
    this.maxAttempts,
  });

  final SyncStage stage;
  final String? scoreText;
  final String? oversText;
  final int? attempt;
  final int? maxAttempts;
}

class ClientService {
  static const int _maxReconnectAttempts = 3;

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<MatchModel> _matchUpdatesController = StreamController<MatchModel>.broadcast();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  final StreamController<SyncStatusState> _syncStatusController = StreamController<SyncStatusState>.broadcast();
  ClientService(this._ref);

  final Ref _ref;
  final String _clientId = 'client_${DateTime.now().microsecondsSinceEpoch}';

  bool _isConnected = false;
  bool _manualDisconnect = false;
  bool _reconnectInProgress = false;
  bool _awaitingDebouncedState = false;
  bool _savedAnySyncedMatch = false;

  String? _hostIp;
  int _port = AppConstants.wsPort;
  String _path = AppConstants.wsPath;
  Timer? _stateDebounceTimer;
  Map<String, dynamic>? _pendingMatchStatePayload;
  MatchModel? _lastReceivedMatch;

  String? _hostDeviceName;
  int _viewerCount = 0;
  SyncStatusState _syncStatus = const SyncStatusState(stage: SyncStage.syncing);

  Stream<MatchModel> get matchUpdates => _matchUpdatesController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  Stream<SyncStatusState> get syncStatusUpdates => _syncStatusController.stream;
  bool get isConnected => _isConnected;
  MatchModel? get lastReceivedMatch => _lastReceivedMatch;
  String? get hostDeviceName => _hostDeviceName;
  int get viewerCount => _viewerCount;
  bool get hasSavedAnySyncedMatch => _savedAnySyncedMatch;
  SyncStatusState get syncStatus => _syncStatus;

  Future<void> connect(String hostIp, int port, [String? path]) async {
    _hostIp = hostIp;
    _port = port;
    if (path != null && path.isNotEmpty) _path = path;
    _manualDisconnect = false;
    _emitSyncStatus(const SyncStatusState(stage: SyncStage.syncing));
    await _connectWithRetry();
  }

  Future<void> retryNow() async {
    if (_hostIp == null || _hostIp!.isEmpty) return;
    _manualDisconnect = false;
    _emitSyncStatus(const SyncStatusState(stage: SyncStage.reconnecting, attempt: 1, maxAttempts: 3));
    await _connectWithRetry();
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _setConnection(false);
    _stateDebounceTimer?.cancel();
    _stateDebounceTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> _connectWithRetry() async {
    if (_hostIp == null || _hostIp!.isEmpty) return;
    if (_reconnectInProgress) return;
    _reconnectInProgress = true;
    try {
      for (var attempt = 1; attempt <= _maxReconnectAttempts; attempt++) {
        try {
          _emitSyncStatus(
            SyncStatusState(
              stage: attempt == 1 ? SyncStage.syncing : SyncStage.reconnecting,
              attempt: attempt,
              maxAttempts: _maxReconnectAttempts,
              scoreText: _syncStatus.scoreText,
              oversText: _syncStatus.oversText,
            ),
          );
          await _connectOnce(_hostIp!, _port);
          return;
        } catch (_) {
          _setConnection(false);
          if (attempt == _maxReconnectAttempts || _manualDisconnect) {
            _emitSyncStatus(
              SyncStatusState(
                stage: SyncStage.failed,
                scoreText: _syncStatus.scoreText,
                oversText: _syncStatus.oversText,
              ),
            );
            return;
          }
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    } finally {
      _reconnectInProgress = false;
    }
  }

  Future<void> _connectOnce(String hostIp, int port) async {
    await _subscription?.cancel();
    await _channel?.sink.close();

    final uri = Uri(
      scheme: 'ws',
      host: hostIp,
      port: port,
      path: _path,
    );
    final channel = IOWebSocketChannel.connect(uri);
    _channel = channel;
    _subscription = channel.stream.listen(
      (message) => unawaited(_handleMessage(message)),
      onDone: _handleDisconnect,
      onError: (_) => _handleDisconnect(),
      cancelOnError: true,
    );

    final lastBalls = _lastReceivedMatch?.currentInnings?.allBalls;
    final lastKnownBallId = (lastBalls == null || lastBalls.isEmpty) ? null : lastBalls.last.id;
    channel.sink.add(
      jsonEncode(<String, dynamic>{
        'type': 'client_hello',
        'lastBallId': lastKnownBallId,
        'clientId': _clientId,
      }),
    );
    _setConnection(true);
  }

  Future<void> _handleMessage(dynamic message) async {
    if (message is! String) return;
    try {
      final raw = jsonDecode(message);
      if (raw is! Map<String, dynamic>) return;
      final event = SyncEvent.fromJson(raw);
      switch (event.type) {
        case SyncEventType.matchState:
          await _onMatchState(event.payload);
          break;
        case SyncEventType.ballRecorded:
          _onBallRecorded(event.payload);
          break;
        case SyncEventType.error:
          _emitSyncStatus(
            SyncStatusState(
              stage: SyncStage.failed,
              scoreText: _syncStatus.scoreText,
              oversText: _syncStatus.oversText,
            ),
          );
          break;
        case SyncEventType.ping:
        case SyncEventType.clientJoined:
        case SyncEventType.clientLeft:
        case SyncEventType.clientHello:
          break;
      }
    } catch (_) {}
  }

  Future<void> _onMatchState(Map<String, dynamic> payload) async {
    _pendingMatchStatePayload = payload;
    _hostDeviceName = payload['hostDeviceName'] as String?;
    _viewerCount = (payload['viewerCount'] as num?)?.toInt() ?? _viewerCount;
    final isFullSync = payload['isFullSync'] as bool? ?? false;
    if (_awaitingDebouncedState && !isFullSync) {
      _stateDebounceTimer?.cancel();
      _stateDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        unawaited(_applyPendingMatchState());
      });
      return;
    }
    await _applyPendingMatchState();
  }

  void _onBallRecorded(Map<String, dynamic> payload) {
    final summaryRaw = payload['matchSummary'];
    if (summaryRaw is Map) {
      final summary = Map<String, dynamic>.from(summaryRaw);
      _emitSyncStatus(
        SyncStatusState(
          stage: SyncStage.syncing,
          scoreText: summary['score'] as String?,
          oversText: summary['overs'] as String?,
        ),
      );
      _awaitingDebouncedState = true;
      _stateDebounceTimer?.cancel();
      _stateDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _awaitingDebouncedState = false;
      });
    }
  }

  Future<void> _applyPendingMatchState() async {
    final payload = _pendingMatchStatePayload;
    _pendingMatchStatePayload = null;
    _awaitingDebouncedState = false;
    if (payload == null) return;
    final matchRaw = payload['match'];
    if (matchRaw is! Map) return;
    final match = MatchModel.fromJson(Map<String, dynamic>.from(matchRaw));
    await _saveMatchLocally(match);
    _lastReceivedMatch = match;
    _matchUpdatesController.add(match);
    final innings = match.currentInnings;
    _emitSyncStatus(
      SyncStatusState(
        stage: SyncStage.synced,
        scoreText: innings == null ? '0/0' : '${innings.totalRuns}/${innings.wickets}',
        oversText: innings == null
            ? '0.0'
            : '${innings.legalBallsCount() ~/ match.rules.ballsPerOver}.${innings.legalBallsCount() % match.rules.ballsPerOver}',
      ),
    );
  }

  Future<void> _saveMatchLocally(MatchModel match) async {
    final localMatch = match.copyWith(id: match.id);
    await _ref.read(matchListProvider.notifier).saveMatch(localMatch);
    final settings = Hive.box<dynamic>(HiveKeys.settingsBox);
    await settings.put('received_via_sync_${match.id}', true);
    _savedAnySyncedMatch = true;
  }

  void _handleDisconnect() {
    _setConnection(false);
    if (_manualDisconnect) return;
    unawaited(_connectWithRetry());
  }

  void _setConnection(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    _connectionStatusController.add(value);
  }

  void _emitSyncStatus(SyncStatusState status) {
    _syncStatus = status;
    _syncStatusController.add(status);
  }

  Future<void> dispose() async {
    _stateDebounceTimer?.cancel();
    await disconnect();
    await _syncStatusController.close();
    await _connectionStatusController.close();
    await _matchUpdatesController.close();
  }
}

final clientServiceProvider = Provider<ClientService>((ref) {
  final service = ClientService(ref);
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
