import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'widgets/social_app_item.dart';

class SocialAppsView extends StatelessWidget {
  const SocialAppsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Scroll'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.spacingM),
              const _PeriodTabs(),
              const SizedBox(height: AppSizes.spacingL),
              const _ScreenTimeHeader(),
              const SizedBox(height: AppSizes.spacingM),
              const _FilterTabs(),
              const SizedBox(height: AppSizes.spacingS),
              Expanded(
                child: ListView(
                  children: const [
                    SocialAppItem(
                      icon: AssetImage('assets/images/youtube.png'),
                      name: 'Youtube',
                      usage: '1 hr 25 min',
                      isLocked: false,
                    ),
                    SocialAppItem(
                      icon: AssetImage('assets/images/instagram.png'),
                      name: 'Instagram',
                      usage: '57 min',
                      isLocked: false,
                    ),
                    SocialAppItem(
                      icon: AssetImage('assets/images/facebook.png'),
                      name: 'Facebook',
                      usage: '32 min',
                      isLocked: true,
                    ),
                    SocialAppItem(
                      icon: AssetImage('assets/images/whatsapp.png'),
                      name: 'WhatsApp',
                      usage: '17 min',
                      isLocked: false,
                    ),
                    SocialAppItem(
                      icon: AssetImage('assets/images/uber.png'),
                      name: 'Uber',
                      usage: '12 min',
                      isLocked: true,
                    ),
                    SocialAppItem(
                      icon: AssetImage('assets/images/gamepad.png'),
                      name: 'Game 01',
                      usage: '1 hr 2 min',
                      isLocked: false,
                    ),
                    SocialAppItem(
                      icon: AssetImage('assets/images/gamepad.png'),
                      name: 'Game 02',
                      usage: '43 min',
                      isLocked: false,
                    ),
                    SocialAppItem(
                      icon: AssetImage('assets/images/gamepad.png'),
                      name: 'Game 03',
                      usage: '23 min',
                      isLocked: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs();

  @override
  Widget build(BuildContext context) {
    final selectedStyle = AppTextStyles.subtitle2.copyWith(
      color: AppColors.surfaceColor,
      fontWeight: FontWeight.w600,
    );
    final unselectedStyle = AppTextStyles.subtitle2.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabChip(
          label: 'Yesterday',
          selected: false,
          textStyle: unselectedStyle,
        ),
        const SizedBox(width: AppSizes.spacingS),
        _TabChip(label: 'Today', selected: true, textStyle: selectedStyle),
        const SizedBox(width: AppSizes.spacingS),
        _TabChip(label: 'Week', selected: false, textStyle: unselectedStyle),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final TextStyle textStyle;
  const _TabChip({
    required this.label,
    required this.selected,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryColor : AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primaryColor : AppColors.borderColor,
        ),
      ),
      child: Text(label, style: textStyle),
    );
  }
}

class _ScreenTimeHeader extends StatelessWidget {
  const _ScreenTimeHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Screentime',
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('02 hrs', style: AppTextStyles.headline5),
                  ],
                ),
                const SizedBox(width: AppSizes.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.6,
                          minHeight: 8,
                          backgroundColor: AppColors.borderColor,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '40% lesser this last week',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingM),
            CommonButton(
              text: 'Block Everything temporarily',
              onPressed: () {},
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs();

  @override
  Widget build(BuildContext context) {
    TextStyle style(bool active) => AppTextStyles.caption.copyWith(
      color: active ? AppColors.surfaceColor : AppColors.textSecondary,
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
    );
    Widget chip(String label, bool active) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryColor : AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? AppColors.primaryColor : AppColors.borderColor,
        ),
      ),
      child: Text(label, style: style(active)),
    );

    return Row(
      children: [
        chip('All', true),
        const SizedBox(width: AppSizes.spacingS),
        chip('Active', false),
        const SizedBox(width: AppSizes.spacingS),
        chip('Blocked (0)', false),
      ],
    );
  }
}
