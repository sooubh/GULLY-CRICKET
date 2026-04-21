import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverlayService {
  static Future<bool> hasPermission() async {
    return false;
  }

  static Future<void> requestPermission() async {
    return;
  }

  static Future<void> showOverlay(OverlayScoreData data) async {
    return;
  }

  static Future<void> updateOverlay(OverlayScoreData data) async {
    return;
  }

  static Future<void> closeOverlay() async {
    return;
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
