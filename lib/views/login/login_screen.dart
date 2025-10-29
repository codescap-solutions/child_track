import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../viewmodels/auth_viewmodel.dart';
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
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = GetIt.instance<AuthViewModel>();
    _authViewModel.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthStateChanged);
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (_authViewModel.successMessage != null) {
      AppSnackbar.showSuccess(context, _authViewModel.successMessage!);
      Navigator.pushNamed(
        context,
        RouteNames.otp,
        arguments: {'phoneNumber': _phoneController.text},
      );
    } else if (_authViewModel.errorMessage != null) {
      AppSnackbar.showError(context, _authViewModel.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    return ListenableBuilder(
      listenable: _authViewModel,
      builder: (context, child) {
        return CommonButton(
          text: AppStrings.sendOtp,
          onPressed: _sendOtp,
          isLoading: _authViewModel.isLoading,
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
      _authViewModel.sendOtp(_phoneController.text);
    }
  }
}
