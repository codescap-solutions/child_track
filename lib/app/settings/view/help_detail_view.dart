import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/widgets/common_button.dart';

class HelpDetailView extends StatelessWidget {
  final String title;
  const HelpDetailView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Help'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F0FF),
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.desktop_mac_rounded,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: AppSizes.spacingM),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _getHelpContent(title),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              CommonButton(
                text: 'Chat With Us',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat support coming soon')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHelpContent(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('location') || lowerTitle.contains('troubleshoot') || lowerTitle.contains('gps')) {
      return 'If you are experiencing location tracking issues, please ensure that GPS/Location services are enabled on the target device, background app refresh is permitted, and the device has a stable internet connection.\n\nIf the issue persists, try restarting the app or checking the device\'s battery saver settings, which may restrict background tracking.';
    } else if (lowerTitle.contains('cancel') || lowerTitle.contains('subscription') || lowerTitle.contains('billing')) {
      return 'To manage or cancel your subscription, go to Settings > Subscription. From there, you can view your current plan details, update billing information, or cancel your active subscription.\n\nIf you subscribed via Google Play Store or Apple App Store, you must manage it directly through your store account settings.';
    } else if (lowerTitle.contains('add') || lowerTitle.contains('member') || lowerTitle.contains('account') || lowerTitle.contains('start')) {
      return 'You can add a new family member by navigating to the Family section in the main menu, tapping \'Add Member\', and selecting their role. If they are a kid, you can create their profile and share the generated link or pairing code to connect their device.';
    } else if (lowerTitle.contains('privacy') || lowerTitle.contains('security')) {
      return 'Your privacy and security are our top priorities. Location data is securely encrypted and only accessible by authorized family members. You can review and adjust sharing permissions anytime in the privacy settings.';
    } else {
      return 'For support or detailed guidance regarding "$title", please review our online documentation or tap the button below to start a conversation with our support team.';
    }
  }
}
