import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import '../../../social_apps/view/social_apps_view.dart';

class SosView extends StatelessWidget {
  const SosView({super.key});

  @override
  Widget build(BuildContext context) {
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
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
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
                        style: AppTextStyles.headline3.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Press this button\n in emergency',
                        textAlign: TextAlign.center,
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
                  MaterialPageRoute(builder: (_) => const SocialAppsView()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
