import 'dart:math' as math;
import 'package:child_track/core/utils/structured_logger.dart';
import 'package:child_track/core/utils/parser_utils.dart';

/// Physically-correct 2-D Kalman Filter designed for GPS latitude and longitude tracking.
/// Models movement states, dynamically adjusts noise covariance based on velocity,
/// rejects GPS jump outliers, and recovers gracefully on persistent anomalies.
class KalmanFilter2D {
  double? _lat; // Filtered Latitude (degrees)
  double? _lng; // Filtered Longitude (degrees)

  double _pLat = 1e-7; // Latitude error covariance (degrees^2)
  double _pLng = 1e-7; // Longitude error covariance (degrees^2)

  DateTime? _lastTimestamp;
  int _consecutiveOutliers = 0;
  static const int _maxConsecutiveOutliers = 3;

  double? get filteredLat => _lat;
  double? get filteredLng => _lng;

  /// Smooths raw GPS coordinates using a heading-aware and speed-aware Kalman Filter.
  /// Handles dynamic noise adjustment, outlier rejection, and GPS jump recovery.
  (double, double) update({
    required double measurementLat,
    required double measurementLng,
    required double accuracyMeters,
    required double speedMps,
    required double headingDegrees,
    required DateTime timestamp,
  }) {
    if (_lat == null || _lng == null || _lastTimestamp == null) {
      // First measurement — trust completely
      _lat = measurementLat;
      _lng = measurementLng;
      _lastTimestamp = timestamp;
      _consecutiveOutliers = 0;
      return (_lat!, _lng!);
    }

    final double dt = timestamp.difference(_lastTimestamp!).inMilliseconds / 1000.0;
    _lastTimestamp = timestamp;

    if (dt <= 0) {
      return (_lat!, _lng!);
    }

    // 1. Outlier Detection (GPS Jump Rejection)
    final double dist = _haversine(_lat!, _lng!, measurementLat, measurementLng);
    if (dist > 150.0 && accuracyMeters > 5.0) {
      _consecutiveOutliers++;
      if (_consecutiveOutliers < _maxConsecutiveOutliers) {
        StructuredLogger.log(
          LogTag.TRIP,
          '[Kalman] Outlier rejected: dist=${dist.toStringAsFixed(1)}m, accuracy=${accuracyMeters.toStringAsFixed(1)}m. Count=$_consecutiveOutliers',
        );
        return (_lat!, _lng!); // Reject and return last state
      } else {
        // Too many consecutive outliers — reset to latest point
        StructuredLogger.log(
          LogTag.TRIP,
          '[Kalman] Too many consecutive outliers. Resetting filter state to new coordinates.',
        );
        _lat = measurementLat;
        _lng = measurementLng;
        _consecutiveOutliers = 0;
        return (_lat!, _lng!);
      }
    }
    _consecutiveOutliers = 0;

    // 2. Prediction Step (Heading & Speed Aware)
    final double latRad = _deg2rad(_lat!);
    final double headingRad = _deg2rad(headingDegrees);

    // Convert speed/heading to delta coordinates in degrees
    final double dLatMeters = speedMps * math.cos(headingRad) * dt;
    final double dLngMeters = speedMps * math.sin(headingRad) * dt;

    final double dLatDeg = dLatMeters / 111111.0;
    final double dLngDeg = dLngMeters / (111111.0 * math.cos(latRad));

    final double latPred = _lat! + dLatDeg;
    final double lngPred = _lng! + dLngDeg;

    // 3. Dynamic Process Noise Covariance (Q) Adjustment
    // Lower noise when stationary to lock coordinates; higher noise when moving
    final double qBase = 1e-10;
    final double qLat = qBase + (speedMps * 1e-11);
    final double qLng = qBase + (speedMps * 1e-11);

    final double pLatPred = _pLat + qLat;
    final double pLngPred = _pLng + qLng;

    // 4. Dynamic Measurement Noise Covariance (R) in degrees squared
    final double rLat = math.pow(accuracyMeters / 111111.0, 2).toDouble();
    final double rLng = math.pow(accuracyMeters / (111111.0 * math.cos(latRad)), 2).toDouble();

    // 5. Update Step (Kalman Gain & State Correction)
    final double kLat = pLatPred / (pLatPred + rLat);
    final double kLng = pLngPred / (pLngPred + rLng);

    _lat = latPred + kLat * (measurementLat - latPred);
    _lng = lngPred + kLng * (measurementLng - lngPred);

    _pLat = (1 - kLat) * pLatPred;
    _pLng = (1 - kLng) * pLngPred;

    return (_lat!, _lng!);
  }

  void reset() {
    _lat = null;
    _lng = null;
    _lastTimestamp = null;
    _pLat = 1e-7;
    _pLng = 1e-7;
    _consecutiveOutliers = 0;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _deg2rad(double deg) => deg * math.pi / 180;
}

/// Applies [KalmanFilter2D] to a stream of GPS points and returns smoothed coordinates.
class KalmanFilterService {
  final KalmanFilter2D _filter2d = KalmanFilter2D();

  /// Smooth a single (lat, lng) reading.
  (double, double) smooth(
    double lat,
    double lng, {
    double? accuracy,
    double? speedMps,
    double? headingDegrees,
    DateTime? timestamp,
  }) {
    return _filter2d.update(
      measurementLat: lat,
      measurementLng: lng,
      accuracyMeters: accuracy ?? 15.0,
      speedMps: speedMps ?? 0.0,
      headingDegrees: headingDegrees ?? 0.0,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Batch-smooth a list of raw points.
  List<Map<String, dynamic>> smoothBatch(
    List<Map<String, dynamic>> rawPoints,
  ) {
    return rawPoints.map((pt) {
      final lat = safeToDouble(pt['lat']);
      final lng = safeToDouble(pt['lng']);
      final accuracy = safeToDoubleNullable(pt['accuracy']);
      final speed = safeToDoubleNullable(pt['speed']);
      final heading = safeToDoubleNullable(pt['heading']);
      final timestamp = pt['timestamp'] != null
          ? (pt['timestamp'] is String 
              ? DateTime.parse(pt['timestamp'] as String) 
              : pt['timestamp'] as DateTime)
          : null;
      final (sLat, sLng) = smooth(
        lat,
        lng,
        accuracy: accuracy,
        speedMps: speed,
        headingDegrees: heading,
        timestamp: timestamp,
      );
      return {...pt, 'lat': sLat, 'lng': sLng};
    }).toList();
  }

  /// Smooth a list of LatLng-like objects for polyline rendering.
  List<(double, double)> smoothRoute(
    List<(double lat, double lng, double? accuracy)> points,
  ) {
    return points.map((pt) {
      final (sLat, sLng) = smooth(pt.$1, pt.$2, accuracy: pt.$3);
      return (sLat, sLng);
    }).toList();
  }

  void reset() {
    _filter2d.reset();
  }

  /// Detect if a point is a GPS jump (outlier).
  bool isOutlier(double lat, double lng, {double maxMeters = 150.0}) {
    final fLat = _filter2d.filteredLat;
    final fLng = _filter2d.filteredLng;
    if (fLat == null || fLng == null) return false;

    final dist = _haversine(fLat, fLng, lat, lng);
    return dist > maxMeters;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in metres
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * math.pi / 180;
}
