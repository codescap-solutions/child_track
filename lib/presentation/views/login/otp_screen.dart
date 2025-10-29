import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common_button.dart';
import '../../widgets/common_textfield.dart';

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
        child: BlocProvider(
          create: (context) => GetIt.instance<AuthBloc>(),
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is OtpVerifiedSuccess) {
                AppSnackbar.showSuccess(context, state.message);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.home,
                  (route) => false,
                );
              } else if (state is AuthFailure) {
                AppSnackbar.showError(context, state.message);
              }
            },
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return CommonButton(
          text: AppStrings.verifyOtp,
          onPressed: _verifyOtp,
          isLoading: state is AuthLoading,
          width: double.infinity,
        );
      },
    );
  }

  Widget _buildResendOtpButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return CommonButton(
          text: AppStrings.resendOtp,
          onPressed: _resendOtp,
          isOutlined: true,
          isLoading: state is AuthLoading,
          width: double.infinity,
        );
      },
    );
  }

  void _verifyOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(VerifyOtpEvent(otp: _otpController.text));
    }
  }

  void _resendOtp() {
    context.read<AuthBloc>().add(SendOtpEvent(phoneNumber: widget.phoneNumber));
  }
}
