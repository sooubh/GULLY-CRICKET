import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants/app_constants.dart';
import '../../scoring/domain/models/match_model.dart';
import '../domain/sync_event.dart';

class HostService {
  HttpServer? _server;
  final Set<WebSocketChannel> _clients = <WebSocketChannel>{};
  Timer? _pingTimer;
  MatchModel? _latestMatch;
  String _hostIp = '0.0.0.0';
  final StreamController<int> _connectedClientsController = StreamController<int>.broadcast();

  String get hostIp => _hostIp;
  bool get isHosting => _server != null;
  int get connectedClients => _clients.length;
  Stream<int> get connectedClientsStream => _connectedClientsController.stream;

  String get qrData => buildQrData();

  String buildQrData([String? matchId]) {
    return jsonEncode(<String, dynamic>{
      'ip': _hostIp,
      'port': AppConstants.wsPort,
      'path': AppConstants.wsPath,
      'matchId': matchId ?? _latestMatch?.id,
    });
  }

  Future<void> startServer(MatchModel initialMatch) async {
    _latestMatch = initialMatch;
    final wifiIp = await NetworkInfo().getWifiIP();
    if (wifiIp != null && wifiIp.isNotEmpty) _hostIp = wifiIp;
    if (_server != null) {
      broadcastMatchState(initialMatch);
      return;
    }

    final wsHandler = webSocketHandler(_onClientConnected);
    final path = AppConstants.wsPath.startsWith('/')
        ? AppConstants.wsPath.substring(1)
        : AppConstants.wsPath;

    final handler = (Request request) {
      if (request.url.path == path) return wsHandler(request);
      return Response.notFound('Not Found');
    };

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, AppConstants.wsPort);
    _connectedClientsController.add(_clients.length);
    _startPing();
  }

  void broadcastMatchState(MatchModel match) {
    _latestMatch = match;
    _broadcast(
      SyncEvent(
        type: SyncEventType.matchState,
        payload: <String, dynamic>{'match': match.toJson()},
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> stopServer() async {
    _pingTimer?.cancel();
    _pingTimer = null;

    for (final client in _clients.toList()) {
      try {
        await client.sink.close();
      } catch (_) {}
    }
    _clients.clear();
    _connectedClientsController.add(_clients.length);

    await _server?.close(force: true);
    _server = null;
  }

  Future<void> dispose() async {
    await stopServer();
    await _connectedClientsController.close();
  }

  void _onClientConnected(WebSocketChannel channel) {
    _clients.add(channel);
    _connectedClientsController.add(_clients.length);
    _broadcast(
      SyncEvent(
        type: SyncEventType.clientJoined,
        payload: <String, dynamic>{'connectedClients': _clients.length},
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    final match = _latestMatch;
    if (match != null) {
      _sendToClient(
        channel,
        SyncEvent(
          type: SyncEventType.matchState,
          payload: <String, dynamic>{'match': match.toJson()},
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    channel.stream.listen(
      (message) => _handleClientMessage(channel, message),
      onDone: () => _onClientDisconnected(channel),
      onError: (_) => _onClientDisconnected(channel),
      cancelOnError: true,
    );
  }

  void _handleClientMessage(WebSocketChannel channel, dynamic message) {
    if (message is! String) return;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) return;
      final event = SyncEvent.fromJson(decoded);
      if (event.type != SyncEventType.ping) {
        _sendToClient(
          channel,
          SyncEvent(
            type: SyncEventType.error,
            payload: const <String, dynamic>{
              'message': 'Clients are read-only. Score updates are host-only.',
            },
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
    } catch (_) {
      _sendToClient(
        channel,
        SyncEvent(
          type: SyncEventType.error,
          payload: const <String, dynamic>{'message': 'Invalid event payload'},
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  void _onClientDisconnected(WebSocketChannel channel) {
    _clients.remove(channel);
    _connectedClientsController.add(_clients.length);
    _broadcast(
      SyncEvent(
        type: SyncEventType.clientLeft,
        payload: <String, dynamic>{'connectedClients': _clients.length},
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _broadcast(
        SyncEvent(
          type: SyncEventType.ping,
          payload: const <String, dynamic>{},
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  void _broadcast(SyncEvent event) {
    for (final client in _clients.toList()) {
      _sendToClient(client, event);
    }
  }

  void _sendToClient(WebSocketChannel channel, SyncEvent event) {
    try {
      channel.sink.add(jsonEncode(event.toJson()));
    } catch (_) {
      _clients.remove(channel);
    }
  }
}

final hostServiceProvider = Provider<HostService>((ref) {
  final service = HostService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
