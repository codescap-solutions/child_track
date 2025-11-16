import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppStrings {
  // Keys
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  // App Info
  static const String appName = 'Child Track';
  static const String appTitle = 'Child Track';

  // Common Strings
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';

  // Login Screen
  static const String loginTitle = 'Welcome to Child Track';
  static const String loginSubtitle = 'Enter your phone number to continue';
  static const String phoneNumberHint = 'Enter phone number';
  static const String sendOtp = 'Send OTP';
  static const String phoneNumberRequired = 'Phone number is required';
  static const String invalidPhoneNumber = 'Please enter a valid phone number';

  // OTP Screen
  static const String otpTitle = 'Verify OTP';
  static const String otpSubtitle = 'Enter the OTP sent to your phone';
  static const String otpHint = 'Enter OTP';
  static const String verifyOtp = 'Verify OTP';
  static const String resendOtp = 'Resend OTP';
  static const String otpRequired = 'OTP is required';
  static const String invalidOtp = 'Please enter a valid OTP';
  static const String otpExpired = 'OTP has expired';

  // Home Screen
  static const String homeTitle = 'Home';
  static const String welcomeMessage = 'Welcome to Child Track';

  // Error Messages
  static const String networkError =
      'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred.';
  static const String timeoutError = 'Request timeout. Please try again.';

  // Success Messages
  static const String otpSentSuccess = 'OTP sent successfully';
  static const String otpVerifiedSuccess = 'OTP verified successfully';
  static const String loginSuccess = 'Login successful';

  // Validation Messages
  static const String fieldRequired = 'This field is required';
  static const String minLength = 'Minimum length is {count} characters';
  static const String maxLength = 'Maximum length is {count} characters';
}
