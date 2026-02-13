import 'package:child_track/app/settings/view/account_view.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/models/child_profile.dart';
import 'package:child_track/core/services/background_location_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/section_card.dart';
import 'widgets/setting_tile.dart';
import 'notification_settings_view.dart';
import '../../addplace/add_and_saveplace.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _sharedPrefsService = SharedPrefsService();
  String? _childId;
  String? _childName;
  bool _restrictDeletion = false;
  bool _block18Plus = false;
  bool _notificationSettings = true;
  bool _isExpanded = false;
  List<ChildProfile> _children = [];

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

  void _loadChildData() {
    _childId = _sharedPrefsService.getString('child_code');
    _childName = _sharedPrefsService.getString('child_name');
    _restrictDeletion = _sharedPrefsService.getBool('restrict_deletion');
    _block18Plus = _sharedPrefsService.getBool('block_18plus');
    _notificationSettings = _sharedPrefsService.getBool(
      'notification_settings',
      defaultValue: true,
    );
    _children = _sharedPrefsService.getChildren();
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _childName ?? 'Child',
                                    style: AppTextStyles.subtitle1.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.edit_square,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Child code $_childId",
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          icon: AnimatedRotation(
                            duration: const Duration(milliseconds: 300),
                            turns: _isExpanded ? 0.5 : 0,
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 32,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isExpanded) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      ..._buildInactiveChildTiles(),
                      _buildAddChildTile(),
                    ],
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
                      _restrictDeletion,
                      (value) async {
                        await _sharedPrefsService.setBool(
                          'restrict_deletion',
                          value,
                        );
                        setState(() => _restrictDeletion = value);
                      },
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
                      _block18Plus,
                      (value) async {
                        if (Theme.of(context).platform == TargetPlatform.iOS) {
                          // Redirection logic for iOS would go here
                          // For now, just toggling and persisting
                        }
                        await _sharedPrefsService.setBool(
                          'block_18plus',
                          value,
                        );
                        setState(() => _block18Plus = value);
                      },
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
                        child: CupertinoSwitch(
                          value: _notificationSettings,
                          onChanged: (value) async {
                            await _sharedPrefsService.setBool(
                              'notification_settings',
                              value,
                            );
                            setState(() => _notificationSettings = value);
                          },
                        ),
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
                      title: 'Request Location',
                      trailing: TextButton(
                        onPressed: () {
                          // Logical trigger for location ping
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Requesting location ping...'),
                            ),
                          );
                        },
                        child: Text(
                          'PING',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
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
                      onTap: () {
                        // Navigation to Emergency Contacts view
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Emergency Contacts feature coming soon',
                            ),
                          ),
                        );
                      },
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
                      onTap: () {
                        // Navigation to Subscription view
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Subscription management by parent'),
                          ),
                        );
                      },
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
                      subtitle: 'Manage your saved locations',
                      leading: const Icon(
                        Icons.bookmark_border,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Saved Places',
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddandSavePlace(),
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

                    // SettingTile(
                    //   subtitle: 'Your account details',
                    //   leading: const Icon(
                    //     Icons.person,
                    //     color: AppColors.textSecondary,
                    //   ),
                    //   title: 'Account',
                    //   trailing: const Icon(
                    //     Icons.arrow_forward_ios,
                    //     size: 16,
                    //     color: AppColors.textSecondary,
                    //   ),
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const AccountView(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.all(8.0),
                    //   child: const Divider(
                    //     height: 1,
                    //     endIndent: 20,
                    //     indent: 20,
                    //   ),
                    // ),
                    // SettingTile(
                    //   subtitle: 'Device details',
                    //   leading: const Icon(
                    //     Icons.person,
                    //     color: AppColors.textSecondary,
                    //   ),
                    //   title: 'Device',
                    //   trailing: const Icon(
                    //     Icons.arrow_forward_ios,
                    //     size: 16,
                    //     color: AppColors.textSecondary,
                    //   ),
                    //   onTap: () {},
                    // ),

                    // Padding(
                    //   padding: const EdgeInsets.all(8.0),
                    //   child: const Divider(
                    //     height: 1,
                    //     endIndent: 20,
                    //     indent: 20,
                    //   ),
                    // ),
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
                      onTap: () => _showHelpOptions(context),
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
                      onTap: () => _showAboutAppDialog(context),
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
                      subtitle: 'Delete Account',
                      leading: const Icon(
                        Icons.delete_outline,
                        color: AppColors.textSecondary,
                      ),
                      title: 'Delete Account',
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => _showDeleteAccountDialog(context),
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
                      subtitle: 'Logout the app',
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
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          RouteNames.onBoarding,
                          (route) => false,
                        );
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

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This will permanently delete your account and associated data.\n\n"
          "You will be redirected to a deletion request form.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _openDeleteForm();
            },
            child: const Text(
              "Continue",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeleteForm() async {
    final Uri url = Uri.parse(
      "https://docs.google.com/forms/d/e/1FAIpQLSdmxHaRpEqVL1ACZWxk35c9dxvIc6evS-pBfHNc-hHdPJHdfg/viewform",
    );

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not open delete account form');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _showHelpOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.email, color: Color(0xFF2E7D32)),
                ),
                title: const Text('Email Support'),
                subtitle: const Text('info.truenyx@gmail.com'),
                onTap: () {
                  Navigator.pop(context);
                  _launchContactUrl(
                    Uri(scheme: 'mailto', path: 'info.truenyx@gmail.com'),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.phone, color: Color(0xFF1565C0)),
                ),
                title: const Text('Call Support'),
                subtitle: const Text('+91 90371 62751'),
                onTap: () {
                  Navigator.pop(context);
                  _launchContactUrl(Uri(scheme: 'tel', path: '+919037162751'));
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'NaviQ',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.child_care, color: Colors.white, size: 32),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Keeping children safe and parents connected.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        const Text(
          '© 2026 CodeScap Solutions',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _launchContactUrl(Uri url) async {
    try {
      if (!await launchUrl(url)) {
        if (mounted) {
          AppSnackbar.showError(context, 'Could not launch action');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Error: $e');
      }
    }
  }

  Widget _toggleTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SettingTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: title,
      subtitle: subtitle,
      trailing: Transform.scale(
        alignment: Alignment.centerRight,
        scale: 0.7,
        child: CupertinoSwitch(value: value, onChanged: onChanged),
      ),
    );
  }

  List<Widget> _buildInactiveChildTiles() {
    final inactiveChildren = _children
        .where((e) => e.childId != _childId)
        .toList();

    return inactiveChildren.map((child) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _showSwitchConfirmation(child),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.containerBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: Colors.white.withAlpha(50)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    size: 20,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.childName,
                        style: AppTextStyles.subtitle2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Code: ${child.childId}",
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.swap_horiz,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAddChildTile() {
    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, RouteNames.addChild);
        _loadChildData();
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              "Add New Child",
              style: AppTextStyles.subtitle2.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSwitchConfirmation(ChildProfile targetChild) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Profile?'),
        content: Text(
          'Tracking will pause for $_childName and activate for ${targetChild.childName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _handleSwitch(targetChild);
    }
  }

  Future<void> _handleSwitch(ChildProfile child) async {
    try {
      AppSnackbar.showLoading(context, 'Switching child identity...');

      // 1. Stop background services
      await BackgroundLocationService().stop();
      AppLogger.info('Multi-Child: Stopped background services');

      // 2. Perform switch in storage (Update token, IDs, last_active)
      await _sharedPrefsService.switchChild(child.childId);
      AppLogger.info('Multi-Child: Storage updated for ${child.childId}');

      // 3. Re-initialize state
      _loadChildData();

      // 4. Restart services
      await BackgroundLocationService().start();
      AppLogger.info('Multi-Child: Restarted background services');

      if (mounted) {
        // Clear loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        AppSnackbar.showSuccess(context, 'Identity active: ${child.childName}');
      }
    } catch (e) {
      AppLogger.error('Switch failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        AppSnackbar.showError(context, 'Failed to switch profile');
      }
    }
  }
}
