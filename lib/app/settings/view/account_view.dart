import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'widgets/section_card.dart';
import 'widgets/setting_tile.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Account'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        children: [
          SectionCard(
            child: Column(
              children: const [
                SettingTile(
                  leading: Icon(
                    Icons.email_outlined,
                    color: AppColors.textSecondary,
                  ),
                  title: 'Email',
                  subtitle: 'Not entered',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                Divider(height: 1),
                SettingTile(
                  leading: Icon(
                    Icons.brush_outlined,
                    color: AppColors.textSecondary,
                  ),
                  title: 'Theme',
                  subtitle: 'System',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          SectionCard(
            child: SettingTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: 'Delete Account',
              subtitle: ' ',
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
