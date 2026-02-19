import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/widgets/common_button.dart';

class AppBlockedScreen extends StatelessWidget {
  final String? appName;
  final String? packageName;

  const AppBlockedScreen({super.key, this.appName, this.packageName});

  @override
  Widget build(BuildContext context) {
    // WillPopScope is deprecated, using PopScope
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.surfaceColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 64,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXL),
                Text(
                  'App Blocked',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingM),
                Text(
                  appName != null
                      ? '$appName is currently unavailable.'
                      : 'This app is currently unavailable.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  'Your parent has restricted access to this application for now.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                CommonButton(
                  text: 'Go Back',
                  onPressed: () {
                    // Minimize the app or go home
                    SystemNavigator.pop();
                  },
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
