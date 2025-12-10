import 'package:child_track/app/auth/view/otp_screen.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_bloc.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_event.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_state.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_strings.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/widgets/common_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          // Navigate to OTP screen on success
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpScreen(phoneNumber: state.phoneNumber),
            ),
          );
        } else if (state is AuthError) {
          // Show error message
          AppSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
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
                  _buildPhoneField(),
                  const SizedBox(height: AppSizes.spacingXL),
                  _buildSendOtpButton(),
                  const Spacer(),
                  _buildFooter(),
                ],
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
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
          ),
          child: const Icon(
            Icons.child_care,
            size: 60,
            color: AppColors.surfaceColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacingL),
        Text(
          AppStrings.loginTitle,
          style: AppTextStyles.headline3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingS),
        Text(
          AppStrings.loginSubtitle,
          style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return CommonTextField(
      controller: _phoneController,
      focusNode: _focusNode,
      hintText: AppStrings.phoneNumberHint,
      labelText: 'Phone Number',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(Icons.phone, color: AppColors.textSecondary),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.phoneNumberRequired;
        }
        if (value.length < 10) {
          return AppStrings.invalidPhoneNumber;
        }
        return null;
      },
      onSubmitted: (_) => _sendOtp(),
    );
  }

  Widget _buildSendOtpButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return CommonButton(
          text: AppStrings.sendOtp,
          onPressed: isLoading ? null : _sendOtp,
          width: double.infinity,
          isLoading: isLoading,
        );
      },
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'By continuing, you agree to our Terms of Service and Privacy Policy',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingL),
        Text(
          'Version 1.0.0',
          style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  void _sendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      final phoneNumber = _phoneController.text.trim();
      context.read<AuthBloc>().add(SendOtp(phoneNumber: phoneNumber));
    }
  }
}
