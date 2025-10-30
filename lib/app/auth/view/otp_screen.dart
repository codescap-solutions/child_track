import 'package:child_track/app/auth/view_model/bloc/auth_bloc.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_strings.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/widgets/common_textfield.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.surfaceColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                _buildHeader(),
                const SizedBox(height: AppSizes.spacingXXL),
                _buildOtpField(),
                const SizedBox(height: AppSizes.spacingXL),
                _buildVerifyOtpButton(),
                const SizedBox(height: AppSizes.spacingL),
                _buildResendOtpButton(),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
          ),
          child: const Icon(Icons.sms, size: 50, color: AppColors.primaryColor),
        ),
        const SizedBox(height: AppSizes.spacingL),
        Text(
          AppStrings.otpTitle,
          style: AppTextStyles.headline3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingS),
        Text(
          AppStrings.otpSubtitle,
          style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingM),
        Text(
          '+91 ${widget.phoneNumber}',
          style: AppTextStyles.subtitle1.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtpField() {
    return CommonTextField(
      controller: _otpController,
      focusNode: _focusNode,
      hintText: AppStrings.otpHint,
      labelText: 'OTP',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(Icons.lock, color: AppColors.textSecondary),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.otpRequired;
        }
        if (value.length != 6) {
          return AppStrings.invalidOtp;
        }
        return null;
      },
      onSubmitted: (_) => _verifyOtp(),
    );
  }

  Widget _buildVerifyOtpButton() {
    return CommonButton(
      text: AppStrings.verifyOtp,
      onPressed: _verifyOtp,
      width: double.infinity,
    );
  }

  Widget _buildResendOtpButton() {
    return CommonButton(
      text: AppStrings.resendOtp,
      onPressed: _resendOtp,
      isOutlined: true,
      width: double.infinity,
    );
  }

  void _verifyOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthStarted());
    }
  }

  void _resendOtp() {
    context.read<AuthBloc>().add(AuthStarted());
  }
}
