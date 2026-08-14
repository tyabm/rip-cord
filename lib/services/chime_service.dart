import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Soft chime for breath phase cues (local asset only).
class ChimeService {
  ChimeService() : _player = AudioPlayer();

  final AudioPlayer _player;
  bool _ready = false;

  Future<void> ensureReady() async {
    if (_ready) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.45);
      _ready = true;
    } catch (e) {
      debugPrint('ChimeService init failed: $e');
    }
  }

  Future<void> playBreathChime() async {
    try {
      await ensureReady();
      await _player.stop();
      await _player.play(AssetSource('sounds/breath_chime.wav'));
    } catch (e) {
      debugPrint('Chime play failed: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
