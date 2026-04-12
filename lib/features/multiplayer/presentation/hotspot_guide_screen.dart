import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/hive_keys.dart';

class HotspotGuideScreen extends StatelessWidget {
  const HotspotGuideScreen({super.key});

  Future<void> _completeGuide(BuildContext context) async {
    final settings = Hive.box<dynamic>(HiveKeys.settingsBox);
    await settings.put('hotspot_guide_shown', true);
    if (!context.mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotspot Setup Guide')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _GuideStep(
                title: 'Step 1: 📶 Turn on your phone\'s WiFi Hotspot',
                body: 'Settings → Network → Hotspot → Turn On',
              ),
              const _GuideStep(
                title: 'Step 2: 📱 Other phones connect to YOUR hotspot',
                body: 'They join your hotspot WiFi, not the internet',
              ),
              const _GuideStep(
                title: 'Step 3: 🏏 Start Hosting in the app',
                body: 'Tap Start Host → share QR code with viewers',
              ),
              const _GuideStep(
                title: 'Step 4: 👁 Viewers scan QR to see live score',
                body: 'They open Gully Cricket → Join → Scan QR',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _completeGuide(context),
                  child: const Text('Got it! → Start Hosting'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}
