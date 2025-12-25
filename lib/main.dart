import 'package:child_track/app/auth/view_model/bloc/auth_bloc.dart';
import 'package:child_track/core/services/connectivity/bloc/connectivity_bloc.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/firebase_notification_service.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/injector.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/route_names.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize dependencies
  await initializeDependencies();

  // Initialize Firebase Notification Service
  await injector<FirebaseNotificationService>().initialize();

  runApp(const ChildTrackApp());
}

class ChildTrackApp extends StatelessWidget {
  const ChildTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectivityBloc>(
          create: (context) => injector<ConnectivityBloc>(),
        ),
        BlocProvider<AuthBloc>(create: (context) => injector<AuthBloc>()),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRouter.generateRoute,
        builder: (context, widget) {
          return BlocListener<ConnectivityBloc, ConnectivityState>(
            listener: (context, state) {
              if (state is ConnectivityOffline) {
                AppSnackbar.showError(context, AppStrings.networkError);
              }
            },
            child: widget ?? const SizedBox.shrink(),
          );
        },
        // home: HomePage(),
        home: SplashScreen(),
      ),
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

final childId = injector<SharedPrefsService>().getString('child_id');
final parentId = injector<SharedPrefsService>().getString('parent_id');
    if (mounted) {
  if (parentId != null && parentId.isNotEmpty) {
    Navigator.pushReplacementNamed(context, RouteNames.home);
  } else if (childId != null && childId.isNotEmpty) {
    Navigator.pushReplacementNamed(context, RouteNames.sos);
  } else {
    Navigator.pushReplacementNamed(context, RouteNames.onBoarding);
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
