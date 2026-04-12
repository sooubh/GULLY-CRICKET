import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/hive_keys.dart';

const _soundEnabledKey = 'sound_enabled';

class SoundService {
  SoundService() : _player = AudioPlayer();

  final AudioPlayer _player;

  Box<dynamic> get _settingsBox => Hive.box(HiveKeys.settingsBox);

  bool get isEnabled => (_settingsBox.get(_soundEnabledKey, defaultValue: true) as bool?) ?? true;

  Future<void> setEnabled(bool enabled) async {
    await _settingsBox.put(_soundEnabledKey, enabled);
  }

  Future<void> playFour() => _play('sounds/four.mp3');
  Future<void> playSix() => _play('sounds/six.mp3');
  Future<void> playWicket() => _play('sounds/wicket.mp3');
  Future<void> playCrowd() => _play('sounds/crowd.mp3');

  Future<void> _play(String assetPath) async {
    if (!isEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});
