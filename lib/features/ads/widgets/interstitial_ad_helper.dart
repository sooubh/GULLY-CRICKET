import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ad_service.dart';

class InterstitialAdHelper {
  const InterstitialAdHelper._();

  static Future<void> showAfterMatch(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adServiceProvider).showInterstitial();
    } catch (_) {}
    if (!context.mounted) return;
    context.go('/result');
  }
}
