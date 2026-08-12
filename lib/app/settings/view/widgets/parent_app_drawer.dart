import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_text_styles.dart';

class ParentAppDrawer extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onShareLogs;

  const ParentAppDrawer({
    super.key,
    required this.onLogout,
    required this.onShareLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.family_restroom,
                  size: 48,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'Parent App Options',
                  style: AppTextStyles.headline5.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.bug_report_outlined,
              color: AppColors.textSecondary,
            ),
            title: Text('Share Background Logs', style: AppTextStyles.body1),
            trailing: const Icon(
              Icons.share,
              size: 20,
              color: AppColors.primaryColor,
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              onShareLogs();
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              'Logout',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              onLogout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
