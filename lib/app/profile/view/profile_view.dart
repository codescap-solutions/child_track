import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'widgets/profile_form.dart';

class ProfileView extends StatelessWidget {
  final bool isEdit;
  const ProfileView({super.key, this.isEdit = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSizes.paddingXL),
          child: Column(
            children: [
              _ProfileHeader(title: isEdit ? 'Edit Profile' : 'Add Profile'),
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: ProfileForm(isEdit: isEdit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String title;
  const _ProfileHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3872F2), Color(0xFF1B47C2)],
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: AppTextStyles.headline5.copyWith(
                color: AppColors.surfaceColor,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 46,
                  backgroundImage: AssetImage(
                    'assets/images/profile_placeholder.png',
                  ),
                  backgroundColor: Colors.white,
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
