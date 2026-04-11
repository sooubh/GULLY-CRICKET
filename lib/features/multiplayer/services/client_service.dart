import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';

import '../../../core/constants/app_constants.dart';
import '../../scoring/domain/models/match_model.dart';
import '../domain/sync_event.dart';

class ClientService {
  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<MatchModel> _matchUpdatesController =
      StreamController<MatchModel>.broadcast();
  bool _isConnected = false;
  bool _manualDisconnect = false;
  bool _reconnectInProgress = false;
  String? _hostIp;
  int _port = AppConstants.wsPort;

  Stream<MatchModel> get matchUpdates => _matchUpdatesController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String hostIp, int port) async {
    _hostIp = hostIp;
    _port = port;
    _manualDisconnect = false;
    await _connectWithRetry();
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _isConnected = false;
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
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          await _connectOnce(_hostIp!, _port);
          return;
        } catch (_) {
          _isConnected = false;
          if (attempt == 3 || _manualDisconnect) return;
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
      path: AppConstants.wsPath,
    );
    final channel = IOWebSocketChannel.connect(uri);
    _channel = channel;
    _subscription = channel.stream.listen(
      _handleMessage,
      onDone: _handleDisconnect,
      onError: (_) => _handleDisconnect(),
      cancelOnError: true,
    );
    _isConnected = true;
  }

  void _handleMessage(dynamic message) {
    if (message is! String) return;
    try {
      final raw = jsonDecode(message);
      if (raw is! Map<String, dynamic>) return;
      final event = SyncEvent.fromJson(raw);
      if (event.type == SyncEventType.matchState) {
        final matchRaw = event.payload['match'];
        if (matchRaw is Map) {
          _matchUpdatesController.add(
            MatchModel.fromJson(Map<String, dynamic>.from(matchRaw)),
          );
        }
      }
    } catch (_) {}
  }

  void _handleDisconnect() {
    _isConnected = false;
    if (_manualDisconnect) return;
    unawaited(_connectWithRetry());
  }

  Future<void> dispose() async {
    await disconnect();
    await _matchUpdatesController.close();
  }
}

final clientServiceProvider = Provider<ClientService>((ref) {
  final service = ClientService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
