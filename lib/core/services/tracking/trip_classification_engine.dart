import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:child_track/core/services/tracking/activity_recognition_service.dart';
import 'package:child_track/core/utils/structured_logger.dart';

/// Hybrid trip-mode classification engine.
///
/// Fuses GPS speed, Activity Recognition confidence, heading variance and
/// accelerometer patterns to produce a final [NaviQActivityType] with a
/// [double] confidence score (0.0–1.0).
///
/// Replaces the old speed-only threshold logic.
class TripClassificationEngine {
  // Weights for each signal source
  static const double _wGps = 0.45;
  static const double _wAr = 0.40;
  static const double _wHeading = 0.15;

  // Upper GPS-speed bound (m/s) for "walking" to remain physically
  // plausible — same boundary _classifyFromGps already uses for the
  // walking/running split. A confident Activity Recognition "walking"
  // vote can otherwise out-score a correctly-classified high-speed GPS
  // vote in the weighted sum below (093RTB incident, 2026-08-01: AR
  // apparently misfired "walking" while GPS speed implied ~27.6 km/h, and
  // nothing in the fusion vetoed that combination).
  static const double _walkingMaxSpeedMps = 2.0;

  // Rolling window for heading-variance calculation
  final List<double> _recentHeadings = [];
  static const int _headingWindowSize = 8;

  /// Classify movement from the current GPS position and AR state.
  ///
  /// Returns a [ClassificationResult] with the best-guess mode and confidence.
  ClassificationResult classify({
    required Position position,
    required ActivityState arState,
  }) {
    final gpsPrediction = _classifyFromGps(position.speed);
    final arPrediction = _classifyFromAr(arState);
    final headingPrediction = _classifyFromHeading(position.heading);

    // Weighted score per type
    final scores = <NaviQActivityType, double>{};
    _addWeighted(scores, gpsPrediction, _wGps);
    _addWeighted(scores, arPrediction, _wAr);
    _addWeighted(scores, headingPrediction, _wHeading);

    // Pick winner
    NaviQActivityType bestType = NaviQActivityType.unknown;
    double bestScore = 0;
    scores.forEach((type, score) {
      if (score > bestScore) {
        bestScore = score;
        bestType = type;
      }
    });

    // Physical-plausibility cap: a confident AR "walking" vote plus
    // ambiguous heading variance can numerically out-score a correctly
    // classified high-speed GPS vote above — nothing else in the weighted
    // sum treats "walking" as disqualified once GPS speed makes it
    // physically impossible. Don't discard the point; fall through to
    // what GPS speed alone indicates instead.
    if (bestType == NaviQActivityType.walking &&
        position.speed >= _walkingMaxSpeedMps) {
      bestType = gpsPrediction.type;
      bestScore = gpsPrediction.confidence;
    }

    // Clamp confidence
    final confidence = bestScore.clamp(0.0, 1.0);

    StructuredLogger.log(
      LogTag.TRIP,
      '[Class] GPS=${gpsPrediction.type.name}(${gpsPrediction.confidence.toStringAsFixed(2)}) '
      'AR=${arPrediction.type.name}(${arPrediction.confidence.toStringAsFixed(2)}) '
      '→ ${bestType.name}(${confidence.toStringAsFixed(2)})',
    );

    return ClassificationResult(type: bestType, confidence: confidence);
  }

  // ── GPS speed → prediction ──────────────────────────────────────────────

  _Prediction _classifyFromGps(double speedMs) {
    if (speedMs < 0) speedMs = 0;

    if (speedMs < 0.5) {
      return _Prediction(NaviQActivityType.stationary, 0.9);
    } else if (speedMs < 2.0) {
      return _Prediction(NaviQActivityType.walking, 0.8);
    } else if (speedMs < 4.0) {
      // Ambiguous: could be running or fast cycling
      return _Prediction(NaviQActivityType.running, 0.6);
    } else if (speedMs < 7.0) {
      return _Prediction(NaviQActivityType.cycling, 0.7);
    } else {
      return _Prediction(NaviQActivityType.vehicle, 0.9);
    }
  }

  // ── Activity Recognition → prediction ───────────────────────────────────

  _Prediction _classifyFromAr(ActivityState ar) {
    return _Prediction(ar.type, ar.confidence);
  }

  // ── Heading variance → prediction ───────────────────────────────────────

  _Prediction _classifyFromHeading(double heading) {
    if (heading < 0) return _Prediction(NaviQActivityType.unknown, 0.0);

    _recentHeadings.add(heading);
    if (_recentHeadings.length > _headingWindowSize) {
      _recentHeadings.removeAt(0);
    }

    if (_recentHeadings.length < 4) {
      return _Prediction(NaviQActivityType.unknown, 0.0);
    }

    final variance = _headingVariance(_recentHeadings);

    if (variance < 15) {
      // Very consistent heading → vehicle or cycling on road
      return _Prediction(NaviQActivityType.vehicle, 0.6);
    } else if (variance < 40) {
      return _Prediction(NaviQActivityType.cycling, 0.5);
    } else {
      // High variance → walking/running turns
      return _Prediction(NaviQActivityType.walking, 0.5);
    }
  }

  static double _headingVariance(List<double> headings) {
    final mean = headings.reduce((a, b) => a + b) / headings.length;
    final squaredDiffs =
        headings.map((h) => math.pow(h - mean, 2)).reduce((a, b) => a + b);
    return squaredDiffs / headings.length;
  }

  static void _addWeighted(
    Map<NaviQActivityType, double> scores,
    _Prediction p,
    double weight,
  ) {
    scores[p.type] = (scores[p.type] ?? 0.0) + p.confidence * weight;
  }

  void reset() => _recentHeadings.clear();
}

// ── Internal helpers ────────────────────────────────────────────────────────

class _Prediction {
  final NaviQActivityType type;
  final double confidence;
  const _Prediction(this.type, this.confidence);
}

class ClassificationResult {
  final NaviQActivityType type;
  final double confidence;
  const ClassificationResult({required this.type, required this.confidence});

  /// Map to the BgTripMode enum used by the legacy state machine.
  BgTripMode get legacyMode {
    switch (type) {
      case NaviQActivityType.walking:
      case NaviQActivityType.running:
        return BgTripMode.walking;
      case NaviQActivityType.cycling:
      case NaviQActivityType.vehicle:
        return BgTripMode.vehicle;
      default:
        return BgTripMode.unknown;
    }
  }

  /// Human-readable ride mode string for API payload.
  String get rideModeString {
    switch (type) {
      case NaviQActivityType.walking:
        return 'walking';
      case NaviQActivityType.running:
        return 'running';
      case NaviQActivityType.cycling:
        return 'cycling';
      case NaviQActivityType.vehicle:
        return 'vehicle';
      case NaviQActivityType.stationary:
        return 'stationary';
      default:
        return 'unknown';
    }
  }
}

// Re-export so callers don't need separate imports
enum BgTripMode { unknown, walking, vehicle }
