enum SyncEventType {
  matchState,
  ballRecorded,
  ping,
  clientJoined,
  clientLeft,
  clientHello,
  error,
}

class SyncEvent {
  const SyncEvent({
    required this.type,
    this.payload = const <String, dynamic>{},
    required this.timestamp,
    this.senderId = 'host',
  });

  final SyncEventType type;
  final Map<String, dynamic> payload;
  final int timestamp;
  final String senderId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'payload': payload,
      'timestamp': timestamp,
      'senderId': senderId,
    };
  }

  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? SyncEventType.error.name;
    final parsedType = SyncEventType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => SyncEventType.error,
    );
    final rawPayload = json['payload'];
    return SyncEvent(
      type: parsedType,
      payload: rawPayload is Map ? Map<String, dynamic>.from(rawPayload) : const <String, dynamic>{},
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      senderId: json['senderId'] as String? ?? 'unknown',
    );
  }
}
