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
  static const String places = 'places';
  static const String getAppUsage = 'app-usage';
}
