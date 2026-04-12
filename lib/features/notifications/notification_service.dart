import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const int liveScoreNotifId = 1001;
  static const int matchEventNotifId = 1002;
  static const String channelId = 'gully_cricket_live';
  static const String channelName = 'Live Score';
  static const String eventsChannelId = 'gully_events';
  static const String eventsChannelName = 'Match Events';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  Future<void> initialize() async {
    _initialization ??= _initializeInternal();
    await _initialization;
  }

  Future<void> _initializeInternal() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const liveChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Live cricket score updates',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );
    const eventChannel = AndroidNotificationChannel(
      eventsChannelId,
      eventsChannelName,
      description: 'Important match moments',
      importance: Importance.high,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(liveChannel);
    await android?.createNotificationChannel(eventChannel);
  }

  Future<void> showLiveScore({
    required String team1Name,
    required String team1Score,
    required String team1Overs,
    required String? team2Score,
    required String? team2Overs,
    required String currentEvent,
    required String battingTeam,
    required String crr,
    required String? rrr,
  }) async {
    await initialize();
    final title = '$team1Name $team1Score ($team1Overs)'
        '${team2Score != null ? ' vs $team2Score (${team2Overs ?? ''})' : ''}';
    final body = currentEvent.isNotEmpty
        ? currentEvent
        : '$battingTeam batting · CRR: $crr${rrr != null ? ' · RRR: $rrr' : ''}';

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Live cricket score',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('open_app', 'Open App'),
        AndroidNotificationAction('dismiss', 'End Match', cancelNotification: true),
      ],
    );

    await _plugin.show(
      liveScoreNotifId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showMatchEvent(String title, String body) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      eventsChannelId,
      eventsChannelName,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      playSound: true,
      timeoutAfter: 4000,
    );
    await _plugin.show(
      matchEventNotifId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showMatchResult(String winner, String description) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      eventsChannelId,
      eventsChannelName,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
    );
    await _plugin.show(
      matchEventNotifId,
      '🏆 Match Complete!',
      '$winner · $description',
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelLiveScore() async {
    await initialize();
    await _plugin.cancel(liveScoreNotifId);
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});
