import 'package:child_track/app/auth/view/onboarding/add_kid_view.dart';
import 'package:child_track/app/childapp/view/sos_view.dart';
import 'package:child_track/app/home/view/home_page.dart';
import 'package:flutter/material.dart';
import '../../app/auth/view/login_screen.dart';
import '../../app/auth/view/otp_screen.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.addChild:
        return MaterialPageRoute(
          builder: (_) => const AddKidView(),
          settings: settings,
        );

      case RouteNames.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case RouteNames.otp:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OtpScreen(phoneNumber: args?['phoneNumber'] ?? ''),
          settings: settings,
        );

      case RouteNames.home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      case RouteNames.sos:
        return MaterialPageRoute(
          builder: (_) => const SosView(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
    }
  }
}
