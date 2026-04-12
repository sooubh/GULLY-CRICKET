import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_alert_window/system_alert_window.dart' as saw;

class OverlayService {
  static Future<bool> hasPermission() async {
    final allowed = await saw.SystemAlertWindow.checkPermissions(prefMode: saw.SystemWindowPrefMode.OVERLAY);
    return allowed ?? false;
  }

  static Future<void> requestPermission() async {
    await saw.SystemAlertWindow.requestPermissions(prefMode: saw.SystemWindowPrefMode.OVERLAY);
  }

  static Future<void> showOverlay(OverlayScoreData data) async {
    if (!await hasPermission()) return;
    final header = _buildHeader(data);
    final body = _buildBody(data);
    await saw.SystemAlertWindow.showSystemWindow(
      height: 72,
      width: 240,
      header: header,
      body: body,
      gravity: saw.SystemWindowGravity.TOP,
      notificationTitle: 'Live Score',
      notificationBody: '${data.battingTeam}: ${data.score}',
      prefMode: saw.SystemWindowPrefMode.OVERLAY,
    );
  }

  static Future<void> updateOverlay(OverlayScoreData data) async {
    if (!await hasPermission()) return;
    final header = _buildHeader(data);
    final body = _buildBody(data);
    await saw.SystemAlertWindow.updateSystemWindow(
      height: 72,
      width: 240,
      header: header,
      body: body,
      gravity: saw.SystemWindowGravity.TOP,
      notificationTitle: 'Live Score',
      notificationBody: '${data.battingTeam}: ${data.score}',
      prefMode: saw.SystemWindowPrefMode.OVERLAY,
    );
  }

  static Future<void> closeOverlay() async {
    await saw.SystemAlertWindow.closeSystemWindow(prefMode: saw.SystemWindowPrefMode.OVERLAY);
  }

  static saw.SystemWindowHeader _buildHeader(OverlayScoreData data) {
    return saw.SystemWindowHeader(
      title: saw.SystemWindowText(
        text: '${data.battingTeam}: ${data.score}',
        fontSize: 14,
        textColor: Colors.white,
        fontWeight: saw.FontWeight.BOLD,
      ),
      subTitle: saw.SystemWindowText(
        text: '${data.overs} ov · CRR: ${data.crr}${data.rrr == null ? '' : ' · RRR: ${data.rrr}'}',
        fontSize: 11,
        textColor: Colors.white70,
      ),
      padding: saw.SystemWindowPadding.setSymmetricPadding(12, 8),
      decoration: saw.SystemWindowDecoration(
        startColor: const Color(0xFF1B5E20),
        endColor: const Color(0xFF0D1117),
        borderRadius: 12.0,
      ),
    );
  }

  static saw.SystemWindowBody _buildBody(OverlayScoreData data) {
    final rows = <saw.EachRow>[
      saw.EachRow(
        columns: <saw.EachColumn>[
          saw.EachColumn(
            text: saw.SystemWindowText(
              text: data.batsmenInfo,
              fontSize: 11,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    ];
    if (data.currentEvent.isNotEmpty) {
      rows.add(
        saw.EachRow(
          columns: <saw.EachColumn>[
            saw.EachColumn(
              text: saw.SystemWindowText(
                text: data.currentEvent,
                fontSize: 11,
                textColor: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return saw.SystemWindowBody(
      rows: rows,
      padding: saw.SystemWindowPadding(left: 12, right: 12, bottom: 8, top: 4),
    );
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
