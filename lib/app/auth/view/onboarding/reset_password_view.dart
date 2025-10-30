import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/widgets/common_textfield.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();
  bool _hide1 = true;
  bool _hide2 = true;

  @override
  void dispose() {
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reset Password',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  'It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXL),
                CommonTextField(
                  controller: _pass1,
                  hintText: 'New Password',
                  obscureText: _hide1,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hide1 ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _hide1 = !_hide1),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingM),
                CommonTextField(
                  controller: _pass2,
                  hintText: 'Confirm Password',
                  obscureText: _hide2,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hide2 ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _hide2 = !_hide2),
                  ),
                ),
                const Spacer(),
                CommonButton(text: 'Submitting...', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {}
  }
}
