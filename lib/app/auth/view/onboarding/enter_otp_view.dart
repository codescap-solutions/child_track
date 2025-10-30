import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';

class EnterOtpView extends StatefulWidget {
  const EnterOtpView({super.key});

  @override
  State<EnterOtpView> createState() => _EnterOtpViewState();
}

class _EnterOtpViewState extends State<EnterOtpView> {
  final _controllers = List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
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
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter OTP',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.spacingS),
            Text(
              'Enter the OTP code we just sent you on your registered Email/Phone number',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _otpBox(_controllers[i])),
            ),
            const SizedBox(height: AppSizes.spacingXL),
            CommonButton(text: 'Reset Password', onPressed: () {}),
            const SizedBox(height: AppSizes.spacingM),
            Center(
              child: Wrap(
                children: const [
                  Text("Didn't get OTP? "),
                  Text(
                    'Resend OTP',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageDot(true),
                const SizedBox(width: 8),
                _pageDot(false),
                const SizedBox(width: 8),
                _pageDot(false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(TextEditingController c) {
    return SizedBox(
      width: 44,
      child: TextField(
        controller: c,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF1F5FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
        ),
      ),
    );
  }

  Widget _pageDot(bool active) {
    return Container(
      width: 24,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.primaryColor : AppColors.borderColor,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
