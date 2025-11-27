class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'https://naviq-server.codescap.com/api/v1/';

  // Auth Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  //child Endpoints
  static const String postDeviceInfo = 'child/device-status';
  static const String postLocation = 'child/location';
  static const String postActivity = 'child/activity';
  static const String postScreenTime = 'child/screentime';
  static const String postTripEvent = 'child/trip-event';
}
