class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'https://api.childtrack.com/v1';

  // Auth Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  // User Endpoints
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/update-profile';

  // Child Endpoints
  static const String childList = '/children';
  static const String addChild = '/children/add';
  static const String updateChild = '/children/update';
  static const String deleteChild = '/children/delete';
  static const String childDetail = '/children/detail';

  // Location Endpoints
  static const String updateLocation = '/location/update';
  static const String locationHistory = '/location/history';
  static const String liveLocation = '/location/live';

  // Attendance Endpoints
  static const String markAttendance = '/attendance/mark';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceReport = '/attendance/report';

  // Safety Endpoints
  static const String safetyAlerts = '/safety/alerts';
  static const String emergencyContacts = '/safety/emergency-contacts';
  static const String panicAlert = '/safety/panic-alert';

  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/mark-read';

  // Settings Endpoints
  static const String appSettings = '/settings/app';
  static const String privacySettings = '/settings/privacy';
  static const String notificationSettings = '/settings/notifications';
}
