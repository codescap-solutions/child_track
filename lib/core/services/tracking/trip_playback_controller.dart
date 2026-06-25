import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Controls animated marker playback along a trip route.
///
/// Features:
///   • play / pause / replay
///   • variable speed (0.5×, 1×, 2×, 4×)
///   • current position + progress (0.0–1.0) via [ValueListenable]s
class TripPlaybackController {
  final List<LatLng> _route;

  // Playback state
  final ValueNotifier<LatLng> positionNotifier;
  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<double> speedNotifier = ValueNotifier(1.0);

  // Supported playback speeds
  static const List<double> supportedSpeeds = [0.5, 1.0, 2.0, 5.0, 10.0];

  Timer? _timer;
  int _currentIndex = 0;

  /// Approximate frame interval at 1× speed (milliseconds per point).
  static const int _baseIntervalMs = 500;

  TripPlaybackController({required List<LatLng> route})
      : _route = route,
        positionNotifier = ValueNotifier(
          route.isNotEmpty ? route.first : const LatLng(0, 0),
        );

  bool get isPlaying => isPlayingNotifier.value;
  double get progress => progressNotifier.value;
  double get speed => speedNotifier.value;
  LatLng get currentPosition => positionNotifier.value;
  bool get isAtEnd => _currentIndex >= _route.length - 1;
  bool get hasRoute => _route.length > 1;

  // ── Controls ─────────────────────────────────────────────────────────────

  void play() {
    if (!hasRoute || isAtEnd) return;
    isPlayingNotifier.value = true;
    _startTimer();
  }

  void pause() {
    isPlayingNotifier.value = false;
    _timer?.cancel();
    _timer = null;
  }

  void replay() {
    _currentIndex = 0;
    positionNotifier.value = _route.first;
    progressNotifier.value = 0.0;
    play();
  }

  void setSpeed(double s) {
    assert(supportedSpeeds.contains(s));
    speedNotifier.value = s;
    if (isPlaying) {
      _timer?.cancel();
      _startTimer();
    }
  }

  void seekTo(double progress) {
    pause();
    _currentIndex =
        ((progress.clamp(0.0, 1.0)) * (_route.length - 1)).round();
    positionNotifier.value = _route[_currentIndex];
    progressNotifier.value = progress;
  }

  void dispose() {
    _timer?.cancel();
    positionNotifier.dispose();
    progressNotifier.dispose();
    isPlayingNotifier.dispose();
    speedNotifier.dispose();
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  void _startTimer() {
    final intervalMs = (_baseIntervalMs / speedNotifier.value).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_currentIndex >= _route.length - 1) {
        pause();
        return;
      }
      _currentIndex++;
      positionNotifier.value = _route[_currentIndex];
      progressNotifier.value = _currentIndex / (_route.length - 1);
    });
  }
}
