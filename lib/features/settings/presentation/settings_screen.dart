import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/hive_keys.dart';
import '../../audio/sound_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _notifEnabled;

  @override
  void initState() {
    super.initState();
    final settings = Hive.box<dynamic>(HiveKeys.settingsBox);
    _notifEnabled = (settings.get(HiveKeys.notifEnabled, defaultValue: true) as bool?) ?? true;
  }

  Future<void> _saveBool(String key, bool value) async {
    await Hive.box<dynamic>(HiveKeys.settingsBox).put(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final sound = ref.watch(soundServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            title: const Text('Sound Effects'),
            value: sound.isEnabled,
            onChanged: (value) => sound.setEnabled(value),
          ),
          SwitchListTile(
            title: const Text('Live Notifications'),
            value: _notifEnabled,
            onChanged: (value) async {
              setState(() => _notifEnabled = value);
              await _saveBool(HiveKeys.notifEnabled, value);
            },
          ),
        ],
      ),
    );
  }
}
