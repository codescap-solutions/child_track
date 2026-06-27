import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/parser_utils.dart';
import 'package:child_track/core/utils/app_logger.dart';

class TrackingConfigService {
  final DioClient _dio;
  final SharedPrefsService _prefs;

  TrackingConfigService({
    required DioClient dio,
    required SharedPrefsService prefs,
  })  : _dio = dio,
        _prefs = prefs;

  double get stopRadius => _prefs.getDouble('tracking_stop_radius') ?? 30.0;
  int get stopDuration => _prefs.getInt('tracking_stop_duration') ?? 120;
  double get speedThreshold => _prefs.getDouble('tracking_speed_threshold') ?? 0.28;
  double get geofenceRadius => _prefs.getDouble('tracking_geofence_radius') ?? 150.0;

  Future<void> fetchConfigFromServer() async {
    try {
      final response = await _dio.get('child/tracking-config');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        if (data['stopRadius'] != null) {
          await _prefs.setDouble('tracking_stop_radius', safeToDouble(data['stopRadius']));
        }
        if (data['stopDuration'] != null) {
          await _prefs.setInt('tracking_stop_duration', safeToInt(data['stopDuration']));
        }
        if (data['speedThreshold'] != null) {
          await _prefs.setDouble('tracking_speed_threshold', safeToDouble(data['speedThreshold']));
        }
        if (data['geofenceRadius'] != null) {
          await _prefs.setDouble('tracking_geofence_radius', safeToDouble(data['geofenceRadius']));
        }
      }
    } catch (e) {
      AppLogger.info('Tracking config fetch failed/unsupported, using fallback defaults: $e');
    }
  }
}
