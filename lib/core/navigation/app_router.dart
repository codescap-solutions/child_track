import 'package:child_track/app/auth/view/onboarding/add_kid_view.dart';
import 'package:child_track/app/auth/view/onboarding/child_code_screen.dart';
import 'package:child_track/app/childapp/view/sos_view.dart';
import 'package:child_track/app/home/view/home_page.dart';
import 'package:child_track/app/home/view/trips_view.dart';
import 'package:child_track/app/onboarding/view/onboarding_screen.dart';
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
      case RouteNames.onBoarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );



      case RouteNames.childCode:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChildCodeScreen(
            childId: args?['childId'] ?? '',
            childCode: args?['childCode'] ?? '',
          ),
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


      case RouteNames.trips:
        return MaterialPageRoute(
          builder: (_) => const TripsView(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
    }
  }

  static void push(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  static void pushReplacement(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  static void pushAndRemoveUntil(BuildContext context, Widget widget) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => widget),
      (route) => false,
    );
  }

  static void pop(BuildContext context) {
    Navigator.pop(context);
  }
}
