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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: BlocProvider(
          create: (context) => GetIt.instance<AuthBloc>(),
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is OtpSentSuccess) {
                AppSnackbar.showSuccess(context, state.message);
                Navigator.pushNamed(
                  context,
                  RouteNames.otp,
                  arguments: {'phoneNumber': _phoneController.text},
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
        return CommonButton(
          text: AppStrings.sendOtp,
          onPressed: _sendOtp,
          isLoading: state is AuthLoading,
          width: double.infinity,
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
      context.read<AuthBloc>().add(
        SendOtpEvent(phoneNumber: _phoneController.text),
      );
    }
  }
}
