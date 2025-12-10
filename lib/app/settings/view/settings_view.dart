import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'widgets/section_card.dart';
import 'widgets/setting_tile.dart';
import 'notification_settings_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _sharedPrefsService = SharedPrefsService();
  String? _childId;

  @override
  void initState() {
    super.initState();
    _loadChildId();
  }

  void _loadChildId() {
    _childId = _sharedPrefsService.getString('child_code');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            children: [
              SectionCard(
                child: Row(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: CircleAvatar(),
                    ),
                    const SizedBox(width: AppSizes.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ananya Pandey',
                                style: AppTextStyles.subtitle1.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.edit_square,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _childId ?? 'No child connected',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 50,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              SectionCard(
                child: Column(
                  children: [
                    _toggleTile(
                      context,
                      Icons.block,
                      'Restrict from deleting',
                      'contact details of each location',
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Divider(
                        height: 1,
                        endIndent: 20,
                        indent: 20,
                      ),
                    ),
                    _toggleTile(
                      context,
                      Icons.do_not_disturb_on_outlined,
                      'Block 18plus Websites',
                      'contact details of each location',
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Divider(
                        height: 1,
                        endIndent: 20,
                        indent: 20,
                      ),
                    ),
                  ],
                ),
              ),

              SectionCard(
                child: Column(
                  children: [
                    SettingTile(
                      subtitle: 'Notification settings for the app',
                      leading: const Icon(
                        Icons.notifications_none,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Notification Settings',
                      trailing: Transform.scale(
                        alignment: Alignment.centerRight,
                        scale: 0.7,
                        child: CupertinoSwitch(value: true, onChanged: (_) {}),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsView(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Divider(
                        height: 1,
                        endIndent: 20,
                        indent: 20,
                      ),
                    ),

                    SettingTile(
                      subtitle: 'Get live location of others',
                      leading: const Icon(
                        Icons.notifications_none,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Request Loacation',
                      trailing: Transform.scale(
                        alignment: Alignment.centerRight,
                        scale: 0.7,
                        child: CupertinoSwitch(value: true, onChanged: (_) {}),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsView(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Divider(
                        height: 1,
                        endIndent: 20,
                        indent: 20,
                      ),
                    ),
                    SettingTile(
                      subtitle: 'Details contact shown in kids app',
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Divider(
                        height: 1,
                        endIndent: 20,
                        indent: 20,
                      ),
                    ),

                    SizedBox(height: 10),
                    SettingTile(
                      subtitle: 'Manage your subscription',
                      leading: const Icon(
                        Icons.family_restroom_rounded,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Subscription',
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {},
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Divider(
                        height: 1,
                        endIndent: 20,
                        indent: 20,
                      ),
                    ),
                  ],
                ),
              ),

              SectionCard(
                child: Column(
                  children: [
                    SettingTile(
                      subtitle: 'Your account details',
                      leading: const Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Account',
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {},
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Divider(
                        height: 1,
                        endIndent: 20,
                        indent: 20,
                      ),
                    ),
                    SettingTile(
                      subtitle: 'Device details',
                      leading: const Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Device',
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {},
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Divider(
                        height: 1,
                        endIndent: 20,
                        indent: 20,
                      ),
                    ),

                    SettingTile(
                      subtitle: 'Help and support',
                      leading: const Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Help',
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {},
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Divider(
                        height: 1,
                        endIndent: 20,
                        indent: 20,
                      ),
                    ),
                    SettingTile(
                      subtitle: 'About the app',
                      leading: const Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                      ),
                      title: 'About app',
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {},
                    ),
                     SettingTile(
                      subtitle: 'About the app',
                      leading: const Icon(
                        Icons.logout,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Logout',
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {
                        injector<SharedPrefsService>().logout();
                        Navigator.pushNamedAndRemoveUntil(context, RouteNames.onBoarding, (route) => false);
                      },
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

  Widget _toggleTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return SettingTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: title,
      subtitle: subtitle,

      trailing: Transform.scale(
        alignment: Alignment.centerRight,
        scale: 0.7,
        child: CupertinoSwitch(value: true, onChanged: (_) {}),
      ),
    );
  }

  /*
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
  */
}
