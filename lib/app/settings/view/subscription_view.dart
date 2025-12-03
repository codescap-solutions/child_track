import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'widgets/section_card.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Subscription'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        children: [
          Row(
            children: [
              Expanded(child: _planTab('Monthly', true)),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(child: _planTab('Yearly', false)),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          SectionCard(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.borderColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
            child: Text(
              'cancel at anytime  Terms & Privacy Policy',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SectionCard(child: _featuresTable()),
        ],
      ),
    );
  }

  Widget _planTab(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryColor : AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? AppColors.primaryColor : AppColors.borderColor,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.subtitle2.copyWith(
          color: selected ? AppColors.surfaceColor : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _featuresTable() {
    final features = [
      'Real-time Tracking',
      'Geofences (3)',
      'SOS Alert',
      'Battery & Network',
      'Weather Report',
      'Movement Report',
      'Location History',
      'Movement Alerts',
      'Steps Tracker',
      'Linked guardians',
      'Email Support',
      'Social Media Usage',
    ];
    return Column(
      children: features
          .map(
            (f) => Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(f)),
                    Container(
                      width: 60,
                      height: 24,
                      color: const Color(0xFFEAF0FF),
                    ),
                  ],
                ),
                if (f != features.last) const Divider(height: 16),
              ],
            ),
          )
          .toList(),
    );
  }
}
