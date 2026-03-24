import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/index.dart';

/// Toggles and persists whether the emergency alarm should play sound.
class AudioSettingsNotifier extends StateNotifier<bool> {
  AudioSettingsNotifier() : super(false) {
    _loadFromHive();
  }

  void _loadFromHive() {
    state = HiveService.getAudioEnabled();
  }

  Future<void> toggle() async {
    final newState = !state;
    await HiveService.saveAudioEnabled(newState);
    state = newState;
  }
}

final audioSettingsProvider =
    StateNotifierProvider<AudioSettingsNotifier, bool>((ref) {
  return AudioSettingsNotifier();
});
