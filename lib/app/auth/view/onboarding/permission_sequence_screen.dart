import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/services/location_service.dart';
import 'package:child_track/core/services/background_location_service.dart';
import 'package:child_track/core/services/device_info_service.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/app/childapp/view/sos_view.dart';

enum PermissionStep {
  location,
  notification,
  battery,
  usageData,
  accessibility,
  success,
}

class PermissionSequenceScreen extends StatefulWidget {
  const PermissionSequenceScreen({super.key});

  @override
  State<PermissionSequenceScreen> createState() => _PermissionSequenceScreenState();
}

class _PermissionSequenceScreenState extends State<PermissionSequenceScreen>
    with WidgetsBindingObserver {
  late final List<PermissionStep> _steps;
  int _currentStepIndex = 0;
  final PageController _pageController = PageController();
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Build the permission steps list dynamically based on platform
    if (Platform.isAndroid) {
      _steps = [
        PermissionStep.location,
        PermissionStep.notification,
        PermissionStep.battery,
        PermissionStep.usageData,
        PermissionStep.accessibility,
        PermissionStep.success,
      ];
    } else {
      _steps = [
        PermissionStep.location,
        PermissionStep.notification,
        PermissionStep.usageData, // Usage Data on iOS maps to Family Controls / Screen Time Access
        PermissionStep.success,
      ];
    }

    // Run initial permission check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentPermission(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCurrentPermission(silent: true);
    }
  }

  /// Automatically check if current step's permission is already granted.
  /// If it is, advance automatically (with a silent delay to feel smooth).
  Future<void> _checkCurrentPermission({bool silent = false}) async {
    if (_currentStepIndex >= _steps.length) return;
    final step = _steps[_currentStepIndex];

    bool isGranted = false;

    try {
      switch (step) {
        case PermissionStep.location:
          final permission = await Geolocator.checkPermission();
          isGranted = permission == LocationPermission.always;
          break;
        case PermissionStep.notification:
          isGranted = await Permission.notification.isGranted;
          break;
        case PermissionStep.battery:
          isGranted = await Permission.ignoreBatteryOptimizations.isGranted;
          break;
        case PermissionStep.usageData:
          isGranted = await injector<ChildInfoService>().checkUsagePermission();
          break;
        case PermissionStep.accessibility:
          isGranted = await injector<DeviceInfoService>().checkAccessibilityPermission();
          break;
        case PermissionStep.success:
          isGranted = true;
          break;
      }
    } catch (e) {
      AppLogger.error('Error checking permission for $step: $e');
    }

    if (isGranted && step != PermissionStep.success) {
      if (mounted) {
        if (silent) {
          // If silent, add a tiny delay to ensure smooth transition
          await Future.delayed(const Duration(milliseconds: 300));
        }
        _advanceToNextStep();
      }
    }
  }

  void _advanceToNextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _pageController.animateToPage(
        _currentStepIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _pageController.animateToPage(
        _currentStepIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _handlePermissionRequest() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    final step = _steps[_currentStepIndex];

    try {
      switch (step) {
        case PermissionStep.location:
          final locationService = LocationService();
          bool isServiceEnabled = await locationService.isLocationServiceEnabled();
          if (!isServiceEnabled) {
            await locationService.openSystemLocationSettings();
            setState(() => _isRequesting = false);
            return;
          }
          final result = await locationService.requestAlwaysAllowPermission();
          final granted = result['granted'] as bool? ?? false;
          final needsSettings = result['needsSettings'] as bool? ?? false;
          if (granted) {
            _advanceToNextStep();
          } else if (needsSettings) {
            await locationService.openLocationSettings();
          }
          break;

        case PermissionStep.notification:
          final status = await Permission.notification.request();
          if (status.isGranted) {
            _advanceToNextStep();
          } else if (status.isPermanentlyDenied) {
            await openAppSettings();
          }
          break;

        case PermissionStep.battery:
          await Permission.ignoreBatteryOptimizations.request();
          // Always advance to make it non-blocking in case of manufacturer restrictions
          _advanceToNextStep();
          break;

        case PermissionStep.usageData:
          final granted = await injector<ChildInfoService>().checkUsagePermission();
          if (granted) {
            _advanceToNextStep();
          } else {
            await injector<ChildInfoService>().openUsageSettings();
          }
          break;

        case PermissionStep.accessibility:
          final granted = await injector<DeviceInfoService>().checkAccessibilityPermission();
          if (granted) {
            _advanceToNextStep();
          } else {
            await injector<DeviceInfoService>().openAccessibilitySettings();
          }
          break;

        case PermissionStep.success:
          // Complete onboarding, start background service, navigate to SOS View
          try {
            await BackgroundLocationService().start();
            AppLogger.info('Background location service started successfully');
          } catch (e) {
            AppLogger.error('Failed to start background tracking service: $e');
          }
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SosView()),
            );
          }
          break;
      }
    } catch (e) {
      AppLogger.error('Error requesting permission for $step: $e');
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFBFCFE),
              Color(0xFFEDF4FE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAppBar(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return _buildStepContent(_steps[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
            onPressed: _goToPreviousStep,
          ),
          const Spacer(),
          Text(
            'Device Setup',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balancing spacer
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // The Success step is not counted in the progress checklist indicator
    final progressStepsCount = _steps.length - 1;
    final isSuccessStep = _steps[_currentStepIndex] == PermissionStep.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(progressStepsCount, (index) {
          Color barColor;
          if (isSuccessStep || index < _currentStepIndex) {
            barColor = const Color(0xFF0066FF); // Completed
          } else if (index == _currentStepIndex) {
            barColor = const Color(0xFF0066FF).withValues(alpha: 0.3); // Active
          } else {
            barColor = const Color(0xFFE2E8F0); // Unreached
          }

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(
                right: index == progressStepsCount - 1 ? 0 : 6,
              ),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(PermissionStep step) {
    if (step == PermissionStep.success) {
      return _buildSuccessStep();
    }

    String title;
    String subtitle;
    String label;
    String imagePath;
    String buttonText = "Allow Access";

    switch (step) {
      case PermissionStep.location:
        label = "LOCATION";
        title = "Location Access";
        subtitle = "NaviQ collects location data to enable parental monitoring and safety tracking even when the app is closed or not in use.";
        imagePath = 'assets/images/location-access device-preview (1) 1.png';
        break;
      case PermissionStep.notification:
        label = "NOTIFICATIONS";
        title = "Notification Access";
        subtitle = "Allows you to receive alerts, safety updates, and SOS notifications from your parent.";
        imagePath = 'assets/images/notification-access-device-preview 1.png';
        break;
      case PermissionStep.battery:
        label = "BATTERY MODE";
        title = "Battery Access";
        subtitle = "Enable background tracking to run uninterrupted. NaviQ needs permission to ignore battery optimizations.";
        imagePath = 'assets/images/battery_access-device-preview 1.png';
        break;
      case PermissionStep.usageData:
        label = "SCREEN LIMITS";
        title = Platform.isIOS ? "Screen Time Access" : "Usage Data Access";
        subtitle = Platform.isIOS
            ? "Enables Family Control/Screen Time to sync monitored apps and enforce app limits configured by your parent."
            : "Allows NaviQ to monitor screen time and usage statistics for safety dashboard insights.";
        imagePath = 'assets/images/usage_data-access-device-preview 1.png';
        break;
      case PermissionStep.accessibility:
        label = "APP PROTECTION";
        title = "Accessibility Access";
        subtitle = "Enables advanced safety protection, app blocking, and real-time monitoring features.";
        imagePath = 'assets/images/accebility-service-access.png';
        break;
      default:
        label = "SETUP";
        title = "";
        subtitle = "";
        imagePath = "";
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Text details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0066FF),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF62748E),
                  height: 1.4,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Centered mock/preview image
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  imagePath,
                  height: MediaQuery.of(context).size.height * 0.38,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.38,
                      width: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ),

          const Spacer(),

          // Action Button
          CommonButton(
            text: buttonText,
            onPressed: _isRequesting ? null : _handlePermissionRequest,
            isLoading: _isRequesting,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Column(
              children: [
                // Success Glow Checkmark Widget
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      width: 4,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 64,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Connected Successfully",
                  style: GoogleFonts.oswald(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Your device is now linked to your parent's dashboard. Location and safety updates are now active.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF62748E),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          CommonButton(
            text: "Let's Go",
            onPressed: _isRequesting ? null : _handlePermissionRequest,
            isLoading: _isRequesting,
          ),
        ],
      ),
    );
  }
}
