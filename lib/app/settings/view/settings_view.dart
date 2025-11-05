import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'widgets/section_card.dart';
import 'widgets/setting_tile.dart';
import 'notification_settings_view.dart';
import 'subscription_view.dart';
import 'about_view.dart';
import 'account_view.dart';
import 'devices_view.dart';
import 'help_view.dart';
import '../../profile/view/profile_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Settings'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            children: [
              SectionCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.security,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ensure Better Protection',
                            style: AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'at half price of a family meal',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Know More'),
                    ),
                  ],
                ),
              ),

              SectionCard(
                child: Column(
                  children: [
                    _toggleTile(context, Icons.block, 'Restrict from deleting'),
                    const Divider(height: 1),
                    _toggleTile(
                      context,
                      Icons.do_not_disturb_on_outlined,
                      'Block 18plus Websites',
                    ),
                    const Divider(height: 1),
                    SettingTile(
                      leading: const Icon(
                        Icons.family_restroom_rounded,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Emergency Contacts',
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              SectionCard(
                child: Column(
                  children: [
                    SettingTile(
                      leading: const Icon(
                        Icons.notifications_none,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Notification Settings',
                      trailing: Switch(value: true, onChanged: (_) {}),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsView(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _linkTile(
                      context,
                      Icons.credit_card,
                      'Subscription',
                      const SubscriptionView(),
                    ),
                    const Divider(height: 1),
                    _linkTile(
                      context,
                      Icons.person_outline,
                      'Account',
                      const AccountView(),
                    ),
                  ],
                ),
              ),

              SectionCard(
                child: Column(
                  children: [
                    _linkTile(
                      context,
                      Icons.devices_other,
                      'Devices',
                      const DevicesView(),
                    ),
                    const Divider(height: 1),
                    _linkTile(
                      context,
                      Icons.help_outline,
                      'Help',
                      const HelpView(),
                    ),
                    const Divider(height: 1),
                    _linkTile(
                      context,
                      Icons.info_outline,
                      'About App',
                      const AboutView(),
                    ),
                  ],
                ),
              ),

              SectionCard(
                child: _linkTile(
                  context,
                  Icons.person,
                  'Profile',
                  const ProfileView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleTile(BuildContext context, IconData icon, String title) {
    return SettingTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: title,
      trailing: Switch(value: true, onChanged: (_) {}),
    );
  }

  Widget _linkTile(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) {
    return SettingTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: title,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
