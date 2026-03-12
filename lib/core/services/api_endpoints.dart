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
  static const String postAppUsage = 'app-usage';

  //parent Endpoints
  static const String getHome = 'parent/home';
  static const String getDeviceStatus = 'parent/device-status';
  static const String getScreenTime = 'parent/screentime';
  static const String getTrips = 'parent/trips';
  static const String linkChild = 'parent/link-child';
  static String getTripDetail(String tripId) => 'parent/trip/$tripId';
  static String postTripLocation(String childId) =>
      'trip-tracking/$childId/locations';
  static const String getAppUsage = 'app-usage';
  static const String getAppUsageSummary = 'app-usage/summary';

  // App Lock Endpoints
  static const String parentLockedApps = 'parent/locked-apps';
  static const String childLockedApps = 'child/locked-apps';

  // FCM Token endpoints
  static const String parentFcmToken = 'fcm-token/parent';
  static const String childFcmToken = 'fcm-token/child';

  // SOS endpoint
  static const String childSOS = 'child/sos';

  // Places & Geofence (Unified) Endpoints
  static const String places = 'places';
  static String placeDetail(String id) => 'places/$id';
  static String assignChildToPlace(String id) => 'places/$id/assign-child';
  static String unassignChildFromPlace(String id) =>
      'places/$id/unassign-child';
  static String assignAllChildrenToPlace(String id) =>
      'places/$id/assign-all-children';
}
