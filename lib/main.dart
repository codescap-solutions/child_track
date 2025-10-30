import 'package:child_track/views/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'core/di/injector.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/route_names.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'viewmodels/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await initializeDependencies();

  runApp(const ChildTrackApp());
}

class ChildTrackApp extends StatelessWidget {
  const ChildTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.generateRoute,
      home: const OnboardingScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Add a small delay for splash screen
    await Future.delayed(const Duration(seconds: 2));

    final authViewModel = GetIt.instance<AuthViewModel>();

    if (mounted) {
      if (authViewModel.isLoggedIn()) {
        Navigator.pushReplacementNamed(context, RouteNames.home);
      } else {
        Navigator.pushReplacementNamed(context, RouteNames.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.child_care,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.surfaceColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keeping children safe',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.surfaceColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.surfaceColor),
            ),
          ],
        ),
      ),
    );
  }
}
