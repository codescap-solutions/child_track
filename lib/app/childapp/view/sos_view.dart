import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/childapp/view_model/bloc/child_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/services/firebase_notification_service.dart';
import 'package:child_track/core/services/lock_sync_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
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
import 'package:cross_file/cross_file.dart';
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
    });
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
    final bgStatus = await Permission.ignoreBatteryOptimizations.status;

    if (mounted) {
      setState(() {
        _hasLocationPermission = locStatus.isGranted || locWhenInUse.isGranted;
        _hasNotificationPermission = notifStatus.isGranted;
        _hasBackgroundPermission = bgStatus.isGranted;
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

class _SosViewContent extends StatelessWidget {
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
          final sharedPrefsService = injector<SharedPrefsService>();
          final childName =
              sharedPrefsService.getString('child_name') ?? 'Child';
          final childCode = sharedPrefsService.getString('child_code') ?? '';
          final parentPhone =
              sharedPrefsService.getString('parent_phone') ?? 'N/A';

          return Scaffold(
            backgroundColor: AppColors.surfaceColor,
            drawer: ChildAppDrawer(
              onLogout: () => _handleLogout(context),
              onShareLogs: () => _shareLogs(context),
            ),
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingL,
                        vertical: AppSizes.paddingXL,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(
                                builder: (context) {
                                  return IconButton(
                                    icon: const Icon(
                                      Icons.menu,
                                      color: AppColors.primaryColor,
                                    ),
                                    onPressed: () =>
                                        Scaffold.of(context).openDrawer(),
                                  );
                                },
                              ),
                              Text(
                                childName,
                                style: AppTextStyles.headline5.copyWith(
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const SizedBox(
                                width: 48,
                              ), // Balance for centering
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
                                _buildPermissionItem(
                                  'Location',
                                  hasLocationPermission,
                                  () => Permission.locationAlways.request(),
                                ),
                                _buildPermissionItem(
                                  'Background Work',
                                  hasBackgroundPermission,
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
                                  hasAccessibilityPermission,
                                  () => injector<LockSyncService>()
                                      .openAccessibilitySettings(),
                                ),
                                _buildPermissionItem(
                                  'Notifications',
                                  hasNotificationPermission,
                                  () => Permission.notification.request(),
                                ),
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
                            'Naviq Dev 1.0.6(Apr-03)',
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
