import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class FlipSoundPlayer {
  FlipSoundPlayer({this.poolSize = 3, this.volume = 0.6})
    : // Path as it appears in pubspec.yaml / to rootBundle:
      bundlePath = 'assets/audio/flip_sound.mp3',
      // Path relative to the assets/ root, which is what AssetSource wants:
      assetPath = 'audio/flip_sound.mp3',
      _players = List.generate(poolSize, (_) => AudioPlayer());

  final int poolSize;
  final double volume;

  /// Full path from project root — used to verify the asset is bundled.
  final String bundlePath;

  /// Path relative to `assets/` — what audioplayers' AssetSource expects.
  final String assetPath;

  final List<AudioPlayer> _players;
  int _next = 0;
  bool _ready = false;

  /// When false, [play] does nothing. Toggled by the speaker button in the UI.
  bool enabled = true;

  Future<void> init() async {
    if (_ready) return;

    // 1) Verify the asset is actually bundled.
    try {
      await rootBundle.load(bundlePath);
      debugPrint('[FlipSound] ✅ asset found at "$bundlePath"');
    } catch (e) {
      debugPrint('[FlipSound] ❌ asset NOT found at "$bundlePath": $e');
      debugPrint(
        '[FlipSound]    Check pubspec.yaml "flutter: assets:" '
        'and run `flutter clean && flutter pub get`.',
      );
      return;
    }

    // 2) Configure each player and await the setup.
    for (var i = 0; i < _players.length; i++) {
      final p = _players[i];
      try {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(volume);
        debugPrint('[FlipSound] player #$i ready (lowLatency, vol=$volume)');
      } catch (e) {
        debugPrint('[FlipSound] player #$i setup failed: $e');
      }
    }

    _ready = true;
    debugPrint('[FlipSound] init complete (${_players.length} players)');
  }

  Future<void> play() async {
    // Mute is a fast, synchronous check — no need to touch the players.
    if (!enabled) return;

    if (!_ready) {
      debugPrint('[FlipSound] play() called before init() — calling init now');
      await init();
      if (!_ready) return; // init failed; don't try to play
    }

    final player = _players[_next];
    final idx = _next;
    _next = (_next + 1) % _players.length;

    try {
      await player.stop();
      debugPrint('[FlipSound] playing "$assetPath" on player $idx');
      await player.play(AssetSource(assetPath));
    } catch (e, st) {
      debugPrint('[FlipSound] ❌ play() failed: $e');
      debugPrint('$st');
    }
  }

  /// Immediately silences any currently-playing flip sound. Called when the
  /// user toggles mute, so a half-played sound doesn't keep going.
  Future<void> stopAll() async {
    for (final p in _players) {
      try {
        await p.stop();
      } catch (_) {}
    }
  }

  void dispose() {
    for (final player in _players) {
      unawaited(player.dispose());
    }
  }
}
