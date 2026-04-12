import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_alert_window/system_alert_window.dart' as saw;

class OverlayService {
  static const int _overlayHeight = 72;
  static const int _overlayWidth = 240;

  static Future<bool> hasPermission() async {
    final allowed = await saw.SystemAlertWindow.checkPermissions(prefMode: saw.SystemWindowPrefMode.OVERLAY);
    return allowed ?? false;
  }

  static Future<void> requestPermission() async {
    await saw.SystemAlertWindow.requestPermissions(prefMode: saw.SystemWindowPrefMode.OVERLAY);
  }

  static Future<void> showOverlay(OverlayScoreData data) async {
    if (!await hasPermission()) return;
    await saw.SystemAlertWindow.showSystemWindow(
      height: _overlayHeight,
      width: _overlayWidth,
      gravity: saw.SystemWindowGravity.TOP,
      notificationTitle: 'Live Score',
      notificationBody: _notificationBody(data),
      prefMode: saw.SystemWindowPrefMode.OVERLAY,
    );
  }

  static Future<void> updateOverlay(OverlayScoreData data) async {
    if (!await hasPermission()) return;
    await saw.SystemAlertWindow.updateSystemWindow(
      height: _overlayHeight,
      width: _overlayWidth,
      gravity: saw.SystemWindowGravity.TOP,
      notificationTitle: 'Live Score',
      notificationBody: _notificationBody(data),
      prefMode: saw.SystemWindowPrefMode.OVERLAY,
    );
  }

  static Future<void> closeOverlay() async {
    await saw.SystemAlertWindow.closeSystemWindow(prefMode: saw.SystemWindowPrefMode.OVERLAY);
  }

  static String _notificationBody(OverlayScoreData data) {
    final rateText = '${data.overs} ov · CRR: ${data.crr}${data.rrr == null ? '' : ' · RRR: ${data.rrr}'}';
    final eventText = data.currentEvent.isEmpty ? '' : '\n${data.currentEvent}';
    return '${data.battingTeam}: ${data.score}\n$rateText\n${data.batsmenInfo}$eventText';
  }
}

class OverlayScoreData {
  const OverlayScoreData({
    required this.battingTeam,
    required this.score,
    required this.overs,
    required this.crr,
    required this.rrr,
    required this.batsmenInfo,
    required this.currentEvent,
  });

  final String battingTeam;
  final String score;
  final String overs;
  final String crr;
  final String? rrr;
  final String batsmenInfo;
  final String currentEvent;
}

final overlayActiveProvider = StateProvider<bool>((_) => false);
