import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/childapp/view_model/bloc/child_bloc.dart';
import 'package:child_track/core/di/injector.dart';
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
import 'package:child_track/core/navigation/route_names.dart';

class SosView extends StatefulWidget {
  const SosView({super.key});

  @override
  State<SosView> createState() => _SosViewState();
}

class _SosViewState extends State<SosView> {
  late final ChildBloc _childBloc;

  @override
  void initState() {
    super.initState();
    _childBloc = injector<ChildBloc>();
    _childBloc.onInitialize();
    // Start background location service
    BackgroundLocationService().start();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _childBloc,
      child: const _SosViewContent(),
    );
  }
}

class _SosViewContent extends StatelessWidget {
  const _SosViewContent();

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

          return Scaffold(
            backgroundColor: AppColors.surfaceColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                  vertical: AppSizes.paddingXL,
                ),
                child: Column(
                  children: [
                    Text(
                      childName,
                      style: AppTextStyles.headline5.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      childCode,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Container(
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
                            color: Colors.blueAccent.withValues(alpha: 0.3),
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
                            Text(
                              '+91 889656 2587',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.surfaceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),

                    const SizedBox(
                      height: AppSizes.spacingXL,
                      width: double.infinity,
                    ),
                    CommonButton(
                      height: 50,
                      text: 'Logout',
                      onPressed: () => _handleLogout(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
