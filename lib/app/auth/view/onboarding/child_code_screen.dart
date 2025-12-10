import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:child_track/core/widgets/common_button.dart';

class ChildCodeScreen extends StatelessWidget {
  final String childCode;

  const ChildCodeScreen({
    super.key,
    required this.childCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 80,
              ),
              const SizedBox(height: AppSizes.spacingL),
              Text(
                'Child Created Successfully!',
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingXL),
              Text(
                'Your Child Code:',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                  vertical: AppSizes.paddingM,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.info],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      childCode,
                      style: AppTextStyles.headline3.copyWith(
                        color: AppColors.surfaceColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingS),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: AppColors.surfaceColor,
                        size: 24,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: childCode));
                        AppSnackbar.showInfo(
                          context,
                          'Child code copied to clipboard!',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spacingXL),
              SizedBox(
                width: double.infinity,
                child: CommonButton(
                  text: 'Continue to Home',
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      RouteNames.home,
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

