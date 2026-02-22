class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'https://naviq-server.codescap.com/api/v1/';

  // Auth Endpoints
  static const String sendOtp = 'users/request-otp';
  static const String verifyOtp = 'users/verify-otp';
  static const String registerUser = 'users';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  //child Endpoints
  static const String childLogin = 'child/login';
  static const String createChild = 'child/create';
  static const String postDeviceInfo = 'child/device-status';
  static const String postLocation = 'child/location';
  static const String postActivity = 'child/activity';
  static const String postScreenTime = 'child/screentime';
  static const String getAvailableIcons = 'child/available-icons';
  static const String uploadIcons = 'child/upload-icons';

  //parent Endpoints
  static const String getHome = 'parent/home';
  static const String getDeviceStatus = 'parent/device-status';
  static const String getScreenTime = 'parent/screentime';
  static const String getTrips = 'parent/trips';
  static const String linkChild = 'parent/link-child';
  static String getTripDetail(String tripId) => 'parent/trip/$tripId';
  static String postTripLocation(String childId) =>
      'trip-tracking/$childId/locations';

  // Batch location upload
  // TODO: Switch to 'child/$childId/locations' once backend implements the new endpoint
  static String postBatchLocations(String childId) =>
      'trip-tracking/$childId/locations';

  // Manual trip end
  static String patchTrip(String childId, String tripId) =>
      'child/$childId/trips/$tripId';

  static const String places = 'places';
  static const String getAppUsage = 'app-usage';

  // FCM Token endpoints
  static const String parentFcmToken = 'fcm-token/parent';
  static const String childFcmToken = 'fcm-token/child';

  // SOS endpoint
  static const String childSOS = 'child/sos';

  // Geofence Endpoints
  static const String geofences = 'geofences';
  static String geofenceDetail(String id) => 'geofences/$id';
  static String geofenceLock(String id) => 'geofences/$id/lock';
}
