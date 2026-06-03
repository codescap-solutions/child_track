import 'dart:io';
import 'package:child_track/app/onboarding/view/onboarding_screen.dart';
import 'package:child_track/core/navigation/app_router.dart';
import 'package:flutter/services.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/childapp/view_model/bloc/child_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/services/firebase_notification_service.dart';
import 'package:child_track/core/services/lock_sync_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/socket_service.dart';
import 'package:child_track/core/services/background_location_service.dart';
import 'package:child_track/core/services/csv_file_logger.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:child_track/app/childapp/view/widgets/child_app_drawer.dart';

class SosView extends StatefulWidget {
  const SosView({super.key});

  @override
  State<SosView> createState() => _SosViewState();
}

class _SosViewState extends State<SosView> with WidgetsBindingObserver {
  late final ChildBloc _childBloc;
  bool _hasAccessibilityPermission = false;
  bool _hasLocationPermission = false;
  bool _hasNotificationPermission = false;
  bool _hasBackgroundPermission = false;

  @override
  void initState() {
    super.initState();
    _childBloc = injector<ChildBloc>();
    WidgetsBinding.instance.addObserver(this);
    _checkAccessibilityPermission();
    _checkOtherPermissions();

    // Defer heavy initialization until after the first frame to ensure smooth navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _childBloc.onInitialize();
      // Start background location service
      BackgroundLocationService().start();
      // Fetch and sync locked apps from server to native AppLockService
      injector<LockSyncService>().fetchAndSyncLockedApps();

      // PROMINENT DISCLOSURE (Google Play Accessibility API Policy)
      // Automatically show disclosure on first launch if Accessibility is not yet enabled.
      // This ensures reviewers see it without needing to tap "Enable" themselves.
      _showAccessibilityDisclosureIfNeeded();
    });
  }

  /// Show the Accessibility Service prominent disclosure automatically
  /// on first load if the permission is not yet granted.
  Future<void> _showAccessibilityDisclosureIfNeeded() async {
    final hasPermission = await injector<LockSyncService>()
        .checkAccessibilityPermission();
    if (!hasPermission && mounted) {
      // Small delay so the screen settles before the dialog appears
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        await showAccessibilityDisclosure(context);
        // Re-check permission state after dialog is dismissed
        _checkAccessibilityPermission();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.info('SosView: Lifecycle state changed to $state');
    if (state == AppLifecycleState.resumed) {
      AppLogger.info('SosView: App resumed, checking permission status...');
      // Re-sync locked apps from server. This is critical because:
      // - The FCM background handler runs in a separate Dart isolate
      //   where MethodChannel to AppLockService doesn't work.
      // - So if the parent unlocked an app while we were in background,
      //   the lock list was fetched but couldn't be sent to native.
      // - This call runs in the main isolate where the channel works.
      injector<LockSyncService>().fetchAndSyncLockedApps();
      // Check permission once with a small delay instead of polling 5 times
      // This significantly reduces the number of expensive native calls
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          AppLogger.info('SosView: Checking usage permission');
          _childBloc.add(CheckUsagePermission());
          _checkAccessibilityPermission();
          _checkOtherPermissions();
        }
      });
    }
  }

  Future<void> _checkAccessibilityPermission() async {
    final hasPermission = await injector<LockSyncService>()
        .checkAccessibilityPermission();
    if (mounted) {
      setState(() {
        _hasAccessibilityPermission = hasPermission;
      });
    }
  }

  Future<void> _checkOtherPermissions() async {
    final locStatus = await Permission.locationAlways.status;
    final locWhenInUse = await Permission.location.status;
    final notifStatus = await Permission.notification.status;
    final bgStatus = Platform.isAndroid
        ? await Permission.ignoreBatteryOptimizations.status
        : PermissionStatus.granted;

    if (mounted) {
      setState(() {
        _hasLocationPermission = locStatus.isGranted || locWhenInUse.isGranted;
        _hasNotificationPermission = notifStatus.isGranted;
        _hasBackgroundPermission = Platform.isAndroid
            ? bgStatus.isGranted
            : true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _childBloc,
      child: _SosViewContent(
        hasAccessibilityPermission: _hasAccessibilityPermission,
        hasLocationPermission: _hasLocationPermission,
        hasNotificationPermission: _hasNotificationPermission,
        hasBackgroundPermission: _hasBackgroundPermission,
      ),
    );
  }
}

// -------------------------------------------------------------------------
// PROMINENT DISCLOSURE — Accessibility Service (Google Play Policy)
// Top-level function so it can be called from both _SosViewState (auto-show
// on first load) and _SosViewContent (on "Enable" tap).
// -------------------------------------------------------------------------
Future<void> showAccessibilityDisclosure(BuildContext context) async {
  final bool? agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacingL),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(AppSizes.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.accessibility_new_rounded,
                  color: AppColors.primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),

              // Title
              Text(
                'Accessibility Service',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline6.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.spacingS),

              // Intro
              Text(
                'NaviQ requires Accessibility permissions for two core parental control features to keep your child safe.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.spacingL),

              // Feature 1: App Blocking
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.app_blocking_rounded,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Blocking',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Detects which app is on screen and blocks restricted apps to enforce limits.',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingM),

              // Feature 2: Web Filtering
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.public_off_rounded,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Web Filtering',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reads website URLs in the browser to block 18+ and adult content.',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingL),

              // Privacy Note
              Container(
                padding: const EdgeInsets.all(AppSizes.spacingS),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.privacy_tip_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: Text(
                        'NaviQ strictly uses this for safety. We do NOT read or transmit personal messages or passwords.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spacingL),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.spacingM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                      ),
                      child: Text(
                        'Later',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingM),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.spacingM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                      ),
                      child: Text(
                        'Enable',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (agreed == true && context.mounted) {
    await injector<LockSyncService>().openAccessibilitySettings();
  }
}

class PulsingSosButton extends StatefulWidget {
  final VoidCallback onTap;
  const PulsingSosButton({super.key, required this.onTap});

  @override
  State<PulsingSosButton> createState() => _PulsingSosButtonState();
}

class _PulsingSosButtonState extends State<PulsingSosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple 2
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = (_controller.value + 0.5) % 1.0;
                return Container(
                  width: 150 + (130 * progress),
                  height: 150 + (130 * progress),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF0066FF,
                    ).withValues(alpha: 0.12 * (1.0 - progress)),
                  ),
                );
              },
            ),
            // Ripple 1
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _controller.value;
                return Container(
                  width: 150 + (130 * progress),
                  height: 150 + (130 * progress),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF0066FF,
                    ).withValues(alpha: 0.22 * (1.0 - progress)),
                  ),
                );
              },
            ),
            // Central Solid SOS Button
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E60FF), Color(0xFF4C82FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E60FF).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "SOS",
                      style: GoogleFonts.manrope(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "TAP FOR HELP",
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosViewContent extends StatefulWidget {
  final bool hasAccessibilityPermission;
  final bool hasLocationPermission;
  final bool hasNotificationPermission;
  final bool hasBackgroundPermission;

  const _SosViewContent({
    required this.hasAccessibilityPermission,
    required this.hasLocationPermission,
    required this.hasNotificationPermission,
    required this.hasBackgroundPermission,
  });

  @override
  State<_SosViewContent> createState() => _SosViewContentState();
}

class _SosViewContentState extends State<_SosViewContent> {
  bool _isMomSelected = true;

  void _showDeviceInfoDialog(BuildContext context, DeviceInfo deviceInfo) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Information',
                  style: AppTextStyles.headline5.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingM),
                _buildInfoRow('Battery', '${deviceInfo.batteryPercentage}%'),
                const SizedBox(height: AppSizes.spacingS),
                _buildInfoRow('Network Status', deviceInfo.networkStatus),
                const SizedBox(height: AppSizes.spacingS),
                _buildInfoRow('Network Type', deviceInfo.networkType),
                const SizedBox(height: AppSizes.spacingS),
                _buildInfoRow('Sound Profile', deviceInfo.soundProfile),
                const SizedBox(height: AppSizes.spacingS),
                _buildInfoRow(
                  'Online Status',
                  deviceInfo.isOnline ? 'Online' : 'Offline',
                ),
                const SizedBox(height: AppSizes.spacingL),
                SizedBox(
                  width: double.infinity,
                  child: CommonButton(
                    text: 'OK',
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionItem(
    String title,
    bool isGranted,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.error_outline,
            color: isGranted ? Colors.green : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSizes.spacingS),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body2.copyWith(
                fontWeight: isGranted ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
          if (!isGranted)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Enable',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _shareLogs(BuildContext context) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preparing logs…')));

      final paths = await CsvFileLogger.instance.getAllLogPaths();
      if (!context.mounted) return;
      if (paths.isEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No log files found yet')));
        return;
      }

      final xFiles = paths.map((p) => XFile(p)).toList();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await SharePlus.instance.share(
        ShareParams(files: xFiles, subject: 'NaviQ Background Logs'),
      );
    } catch (e) {
      AppLogger.error('Share logs error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: Text(
          'Logout',
          style: AppTextStyles.headline6.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.body2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performLogout(context);
            },
            child: Text(
              'Logout',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      // Remove FCM token from server before logout
      try {
        await FirebaseNotificationService().removeTokenFromServer();
        AppLogger.info('FCM token removed from server');
      } catch (e) {
        AppLogger.error('Error removing FCM token: $e');
      }

      // Stop ChildBloc timers and tracking
      try {
        final childBloc = injector<ChildBloc>();
        childBloc.stopChildTracking();
        AppLogger.info('ChildBloc: Stopped all tracking activities');
      } catch (e) {
        AppLogger.error('Error stopping ChildBloc: $e');
      }

      // Stop background location service
      try {
        await BackgroundLocationService().stop();
        AppLogger.info('Background location service stopped');
      } catch (e) {
        // Ignore errors if service wasn't running
        AppLogger.warning('Error stopping background service: $e');
      }

      // Disconnect socket service
      final socketService = injector<SocketService>();
      if (socketService.isConnected) {
        final childId = injector<SharedPrefsService>().getString('child_id');
        if (childId != null) {
          socketService.leaveRoom(childId);
        }
        socketService.disconnect();
      }

      // Clear all user data
      final sharedPrefsService = injector<SharedPrefsService>();
      await sharedPrefsService.logout();

      // Navigate to onboarding screen and remove all previous routes
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RouteNames.onBoarding, (route) => false);
      }
    } catch (e) {
      // Even if there's an error, try to navigate to onboarding
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RouteNames.onBoarding, (route) => false);
      }
    }
  }

  Future<void> _callNumber(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(' ', '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (!await launchUrl(launchUri)) {
        AppLogger.error('Could not launch dialer');
      }
    } catch (e) {
      AppLogger.error('Error launching dialer: $e');
    }
  }

  Widget _buildContactTab({
    required bool isSelected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0066FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0066FF)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChildBloc, ChildState>(
      listenWhen: (previous, current) {
        return previous is! ChildDeviceInfoLoaded &&
            current is ChildDeviceInfoLoaded;
      },
      listener: (context, state) {
        if (state is ChildDeviceInfoLoaded) {
          _showDeviceInfoDialog(context, state.deviceInfo);
        }
      },
      child: BlocBuilder<ChildBloc, ChildState>(
        builder: (context, state) {
          final hasAccessibilityPermission = widget.hasAccessibilityPermission;
          final hasLocationPermission = widget.hasLocationPermission;
          final hasNotificationPermission = widget.hasNotificationPermission;
          final hasBackgroundPermission = widget.hasBackgroundPermission;

          final sharedPrefsService = injector<SharedPrefsService>();
          final childCode = sharedPrefsService.getString('child_code') ?? '';
          final parentPhone =
              sharedPrefsService.getString('parent_phone') ?? 'N/A';

          final momPhone = parentPhone != 'N/A'
              ? parentPhone
              : '+91 78 27 533 456';
          const dadPhone = '+91 98 76 543 210'; // Simulated Dad number

          return Scaffold(
            backgroundColor: const Color(
              0xFFF8FAFC,
            ), // very light blue/gray background
            drawer: ChildAppDrawer(
              onLogout: () => _handleLogout(context),
              onShareLogs: () => _shareLogs(context),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button
                          GestureDetector(
                            onTap: () {
                              // Navigator.of(context).maybePop();
                              AppRouter.pushAndRemoveUntil(
                                context,
                                OnboardingScreen(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF0F172A),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Back",
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Right Status Icons
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Scaffold.of(context).openDrawer(),
                                child: const Icon(
                                  Icons.wb_cloudy_outlined,
                                  color: Color(0xFF3B82F6),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  context.read<ChildBloc>().add(
                                    CheckUsagePermission(),
                                  );
                                },
                                child: const Icon(
                                  Icons.star_outline_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.auto_awesome_outlined,
                                color: Color(0xFF3B82F6),
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            childCode,
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacingM),
                          Container(
                            padding: const EdgeInsets.all(AppSizes.paddingL),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusM,
                              ),
                              border: Border.all(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.security_rounded,
                                      color: AppColors.primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: AppSizes.spacingS),
                                    Text(
                                      'App Permissions Check',
                                      style: AppTextStyles.subtitle1.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.spacingS),
                                Divider(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: AppSizes.spacingS),
                                if (Platform.isIOS) ...[
                                  _buildPermissionItem(
                                    'Location',
                                    widget.hasLocationPermission,
                                    () async {
                                      final currentStatus =
                                          await Permission.location.status;
                                      if (currentStatus.isGranted ||
                                          currentStatus.isLimited) {
                                        final statusAlways = await Permission
                                            .locationAlways
                                            .request();
                                        if (!statusAlways.isGranted) {
                                          await openAppSettings();
                                        }
                                      } else {
                                        final status = await Permission.location
                                            .request();
                                        if (status.isGranted ||
                                            status.isLimited) {
                                          final statusAlways = await Permission
                                              .locationAlways
                                              .request();
                                          if (!statusAlways.isGranted) {
                                            await openAppSettings();
                                          }
                                        } else {
                                          await openAppSettings();
                                        }
                                      }
                                    },
                                  ),
                                  _buildPermissionItem(
                                    'Screen Time & App Blocking',
                                    widget.hasAccessibilityPermission,
                                    () => showAccessibilityDisclosure(context),
                                  ),
                                  _buildPermissionItem(
                                    'Notifications',
                                    widget.hasNotificationPermission,
                                    () async {
                                      final status = await Permission
                                          .notification
                                          .request();
                                      if (!status.isGranted) {
                                        await openAppSettings();
                                      }
                                    },
                                  ),
                                ] else ...[
                                  _buildPermissionItem(
                                    'Location',
                                    widget.hasLocationPermission,
                                    () async {
                                      final status = await Permission
                                          .locationAlways
                                          .request();
                                      if (status.isPermanentlyDenied) {
                                        await openAppSettings();
                                      }
                                    },
                                  ),
                                  _buildPermissionItem(
                                    'Background Work',
                                    widget.hasBackgroundPermission,
                                    () => Permission.ignoreBatteryOptimizations
                                        .request(),
                                  ),
                                  _buildPermissionItem(
                                    'App Usage',
                                    state is ChildDeviceInfoLoaded
                                        ? state.hasUsagePermission
                                        : false,
                                    () => context.read<ChildBloc>().add(
                                      OpenUsageSettings(),
                                    ),
                                  ),
                                  _buildPermissionItem(
                                    'Accessibility',
                                    widget.hasAccessibilityPermission,
                                    // Show prominent disclosure BEFORE opening Settings
                                    // (required by Google Play Accessibility Service policy)
                                    () => showAccessibilityDisclosure(context),
                                  ),
                                  _buildPermissionItem(
                                    'Notifications',
                                    widget.hasNotificationPermission,
                                    () async {
                                      final status = await Permission
                                          .notification
                                          .request();
                                      if (status.isPermanentlyDenied) {
                                        await openAppSettings();
                                      }
                                    },
                                  ),
                                ],
                                if (Platform.isIOS) ...[
                                  const SizedBox(height: AppSizes.spacingM),
                                  StatefulBuilder(
                                    builder: (context, setLocalState) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          CommonButton(
                                            text: 'Select Apps to Track',
                                            width: double.infinity,
                                            height: 50,
                                            onPressed: () async {
                                              final scaffoldMessenger =
                                                  ScaffoldMessenger.of(context);
                                              final result =
                                                  await injector<
                                                        ChildInfoService
                                                      >()
                                                      .openFamilyActivityPicker();
                                              if (result.isNotEmpty) {
                                                final prefs =
                                                    injector<
                                                      SharedPrefsService
                                                    >();
                                                final Map<String, String>
                                                tokenMap = {};
                                                for (final item in result) {
                                                  final id =
                                                      item['id'] as String? ??
                                                      '';
                                                  final name =
                                                      item['displayName']
                                                          as String? ??
                                                      '';
                                                  if (id.isNotEmpty &&
                                                      name.isNotEmpty) {
                                                    tokenMap[id] = name;
                                                  }
                                                }
                                                await prefs.setString(
                                                  'ios_token_label_map',
                                                  tokenMap.entries
                                                      .map(
                                                        (e) =>
                                                            '${e.key}::${e.value}',
                                                      )
                                                      .join('||'),
                                                );
                                                AppLogger.info(
                                                  'Saved ${tokenMap.length} token labels to SharedPrefs',
                                                );
                                                setLocalState(
                                                  () {},
                                                ); // Refresh chips

                                                scaffoldMessenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '✅ ${result.length} apps/categories selected for tracking',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          // Show currently tracked apps/categories
                                          Builder(
                                            builder: (context) {
                                              final mapStr =
                                                  injector<SharedPrefsService>()
                                                      .getString(
                                                        'ios_token_label_map',
                                                      ) ??
                                                  '';
                                              if (mapStr.isEmpty) {
                                                return const SizedBox.shrink();
                                              }

                                              final entries =
                                                  <MapEntry<String, String>>[];
                                              for (final entry in mapStr.split(
                                                '||',
                                              )) {
                                                final parts = entry.split('::');
                                                if (parts.length == 2 &&
                                                    parts[0].isNotEmpty) {
                                                  entries.add(
                                                    MapEntry(
                                                      parts[0],
                                                      parts[1],
                                                    ),
                                                  );
                                                }
                                              }
                                              if (entries.isEmpty) {
                                                return const SizedBox.shrink();
                                              }

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: AppSizes.spacingS,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Tracked (${entries.length})',
                                                      style: AppTextStyles
                                                          .caption
                                                          .copyWith(
                                                            color: AppColors
                                                                .textSecondary,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Wrap(
                                                      spacing: 6,
                                                      runSpacing: 4,
                                                      children: entries.map((
                                                        e,
                                                      ) {
                                                        final isCategory = e.key
                                                            .startsWith(
                                                              'usage_cat_',
                                                            );
                                                        return Chip(
                                                          avatar: Icon(
                                                            isCategory
                                                                ? Icons.category
                                                                : Icons.apps,
                                                            size: 14,
                                                            color: AppColors
                                                                .primaryColor,
                                                          ),
                                                          label: Text(
                                                            e.value,
                                                            style: AppTextStyles
                                                                .caption
                                                                .copyWith(
                                                                  fontSize: 11,
                                                                ),
                                                          ),
                                                          materialTapTargetSize:
                                                              MaterialTapTargetSize
                                                                  .shrinkWrap,
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                          padding:
                                                              EdgeInsets.zero,
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(
                                            height: AppSizes.spacingS,
                                          ),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.primaryColor,
                                              side: BorderSide(
                                                color: AppColors.primaryColor
                                                    .withValues(alpha: 0.5),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                            ),
                                            icon: const Icon(
                                              Icons.analytics_outlined,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'View Diagnostic Logs',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder: (context) =>
                                                    const _DiagnosticLogsSheet(),
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              if (parentPhone != 'N/A') {
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: parentPhone,
                                );
                                try {
                                  if (!await launchUrl(launchUri)) {
                                    AppLogger.error('Could not launch dialer');
                                  }
                                } catch (e) {
                                  AppLogger.error('Error launching dialer: $e');
                                }
                              }
                            },
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF004CE8), // #004CE8
                                    Color(0xFF6F9EFF), // #6F9EFF
                                  ],
                                ),
                                shape: BoxShape.circle,
                                color: Colors.blue,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 40,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'SOS',
                                      style: AppTextStyles.headlineXL.copyWith(
                                        color: AppColors.surfaceColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Press this button\n in emergency',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.body2.copyWith(
                                        color: AppColors.surfaceColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Parent Number',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (parentPhone != 'N/A') {
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: parentPhone,
                                );
                                try {
                                  if (!await launchUrl(launchUri)) {
                                    AppLogger.error('Could not launch dialer');
                                  }
                                } catch (e) {
                                  AppLogger.error('Error launching dialer: $e');
                                }
                              }
                            },
                            child: Text(
                              parentPhone,
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: AppSizes.spacingXL,
                            width: double.infinity,
                          ),
                          Text(
                            'Naviq Dev 1.0.3(May-30)',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------------------
// DIAGNOSTIC LOGS VIEWER SHEET (iOS Background & App Activity Logs)
// -------------------------------------------------------------------------
class _DiagnosticLogsSheet extends StatefulWidget {
  const _DiagnosticLogsSheet();

  @override
  State<_DiagnosticLogsSheet> createState() => _DiagnosticLogsSheetState();
}

class _DiagnosticLogsSheetState extends State<_DiagnosticLogsSheet> {
  bool _isLoading = true;
  List<String> _appLogs = [];
  List<String> _apnsLogs = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    final csvLogs = await CsvFileLogger.instance.readLogs();
    List<String> nativeLogs = [];
    if (Platform.isIOS) {
      try {
        const channel = MethodChannel('com.truenyx.naviq/parental_control');
        final result = await channel.invokeMethod<List<dynamic>>(
          'getExtensionLogs',
        );
        if (result != null) {
          nativeLogs = result
              .map((e) => e.toString())
              .toList()
              .reversed
              .toList();
        }
      } catch (e) {
        AppLogger.error('Failed to get iOS native extension logs: $e');
      }
    }

    if (mounted) {
      setState(() {
        _appLogs = csvLogs;
        _apnsLogs = nativeLogs;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Logs?'),
        content: const Text(
          'This will delete all activity and sync diagnostics logs from this device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear Logs'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      await CsvFileLogger.instance.clearLogs();
      if (Platform.isIOS) {
        try {
          const channel = MethodChannel('com.truenyx.naviq/parental_control');
          await channel.invokeMethod<bool>('clearExtensionLogs');
        } catch (e) {
          AppLogger.error('Failed to clear iOS native logs: $e');
        }
      }

      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logs successfully cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  List<String> _filterLogs(List<String> logs) {
    if (_searchQuery.isEmpty) return logs;
    return logs
        .where((log) => log.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildAppLogItem(String rawRow) {
    final parts = rawRow.split(',');
    if (parts.length < 4) {
      return _buildRawLogItem(rawRow);
    }
    final ts = parts[0];
    final tag = parts[1];
    final level = parts[2];
    final message = parts.skip(3).join(',').replaceAll('"', '');

    Color tagColor = Colors.blue;
    if (level == 'ERROR') tagColor = Colors.red;
    if (level == 'WARNING') tagColor = Colors.orange;
    if (level.contains('OK') ||
        message.toLowerCase().contains('success') ||
        message.contains('OK'))
      tagColor = Colors.green;

    String formattedTime = ts;
    try {
      final dateTime = DateTime.parse(ts).toLocal();
      formattedTime =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
    } catch (_) {}

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied log to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: tagColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        level,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedTime,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.body2.copyWith(
                fontFamily: Platform.isIOS ? 'Courier' : 'monospace',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApnsLogItem(String rawRow) {
    final timeRegex = RegExp(r'^\[(.*?)\]');
    final match = timeRegex.firstMatch(rawRow);
    String time = "";
    String body = rawRow;
    if (match != null) {
      time = match.group(1) ?? "";
      body = rawRow.replaceFirst(timeRegex, '').trim();
    }

    Color sourceColor = AppColors.primaryColor;
    if (body.contains("AppDel")) {
      sourceColor = Colors.teal;
    }
    if (body.contains("❌") ||
        body.toLowerCase().contains("failed") ||
        body.toLowerCase().contains("error")) {
      sourceColor = Colors.red;
    } else if (body.contains("✅") ||
        body.toLowerCase().contains("ok") ||
        body.toLowerCase().contains("success")) {
      sourceColor = Colors.green;
    }

    final displayBody = body
        .replaceFirst("AppDel:", "")
        .replaceFirst("Runner:", "")
        .trim();

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: rawRow));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied log to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: sourceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    body.contains("AppDel")
                        ? "AppDelegate"
                        : "ScreenTimeExtension",
                    style: TextStyle(
                      color: sourceColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayBody,
              style: AppTextStyles.body2.copyWith(
                fontFamily: Platform.isIOS ? 'Courier' : 'monospace',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawLogItem(String rawLog) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: rawLog));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied log to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Text(
          rawLog,
          style: AppTextStyles.body2.copyWith(
            fontFamily: Platform.isIOS ? 'Courier' : 'monospace',
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Draggable Handle Indicator
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Actions Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diagnostic Logs',
                          style: AppTextStyles.headline6.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Background Sync & System Logs',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primaryColor,
                          ),
                          onPressed: _loadLogs,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: _clearLogs,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Log Tabs and List View
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: AppColors.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.primaryColor,
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [
                          Tab(text: 'App Activity'),
                          Tab(text: 'APNs & Sync'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Tab 1: App Activity Logs
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Builder(
                                    builder: (context) {
                                      final filtered = _filterLogs(_appLogs);
                                      if (filtered.isEmpty) {
                                        return _buildEmptyState(
                                          'No Activity Logs found',
                                        );
                                      }
                                      return ListView.builder(
                                        controller: scrollController,
                                        itemCount: filtered.length,
                                        itemBuilder: (context, idx) =>
                                            _buildAppLogItem(filtered[idx]),
                                      );
                                    },
                                  ),

                            // Tab 2: APNs & Sync Logs
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Builder(
                                    builder: (context) {
                                      final filtered = _filterLogs(_apnsLogs);
                                      if (filtered.isEmpty) {
                                        return _buildEmptyState(
                                          'No APNs Sync Logs found',
                                        );
                                      }
                                      return ListView.builder(
                                        controller: scrollController,
                                        itemCount: filtered.length,
                                        itemBuilder: (context, idx) =>
                                            _buildApnsLogItem(filtered[idx]),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
