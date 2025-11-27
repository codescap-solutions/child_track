import 'package:child_track/app/home/view/home_page.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/childapp/view_model/bloc/child_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';

class SosView extends StatelessWidget {
  const SosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => injector<ChildBloc>()..add(LoadDeviceInfo()),
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
                      'Adhvaidh',
                      style: AppTextStyles.headline5.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('154561231656456'),
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
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text('Father'),
                    const SizedBox(height: 4),
                    const Text('+91 889656 2587'),
                    const SizedBox(
                      height: AppSizes.spacingXL,
                      width: double.infinity,
                    ),
                    CommonButton(
                      text: 'Next',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      ),
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
