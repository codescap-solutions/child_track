import 'package:child_track/app/auth/view/onboarding/connect_to_parent_screen.dart';
import 'package:child_track/app/home/view/home_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'widgets/role_selector.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedRole = 'Kid';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height;

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      body: Stack(
        children: [
          // Background image with soft overlay & bottom gradient fade
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/app_intro children.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.75),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Foreground content anchored near the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL)
                  .copyWith(
                    bottom: media.padding.bottom + AppSizes.paddingXL,
                    top: AppSizes.paddingXL,
                  ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Keep content from overflowing on very small screens
                  maxWidth: 520,
                  // Leave some space for the illustration on tall screens
                  minHeight: height * 0.36,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand title
                    Text(
                      'naviQ',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingM),

                    // Description
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXL),

                    // Role selector (Kid / Parent)
                    RoleSelector(
                      selected: _selectedRole,
                      onChanged: (role) => setState(() => _selectedRole = role),
                    ),
                    const SizedBox(height: AppSizes.spacingL),

                    // Sign in link
                    Text.rich(
                      TextSpan(
                        text: 'Do you have account? ',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryColor,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(
                                  context,
                                ).pushNamed(RouteNames.login);
                              },
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.spacingXL),

                    // Continue button for navigation
                    CommonButton(
                      text: 'Continue',
                      onPressed: () {
                        if (_selectedRole == "Kid") {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ConnectToParentScreen(),
                            ),
                          );
                        } else {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (_) => const HomePage()),
                          // );
                           Navigator.of(
                                  context,
                                ).pushNamed(RouteNames.login);
                        }
                      },
                    ),
                    const SizedBox(height: AppSizes.spacingL),

                    // Small progress bar to emulate the page indicator in the mock
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
