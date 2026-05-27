import 'package:child_track/app/auth/view/otp_screen.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_bloc.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_event.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_state.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_strings.dart';
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
  bool _isPhoneValid = false;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final text = _phoneController.text.trim();
    final isValid = text.length == 10;
    if (isValid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
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
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFBFCFE),
                Color(0xFFEDF4FE),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.spacingS),
                    _buildCustomAppBar(),
                    const SizedBox(height: AppSizes.spacingL),
                    _buildHeader(),
                    const SizedBox(height: AppSizes.spacingXXL),
                    _buildPhoneField(),
                    const SizedBox(height: AppSizes.spacingS),
                    _buildValidationTip(),
                    const SizedBox(height: AppSizes.spacingXL),
                    _buildSocialDivider(),
                    const SizedBox(height: AppSizes.spacingL),
                    _buildSocialButtons(),
                    const SizedBox(height: AppSizes.spacingXL),
                    _buildTermsCheckbox(),
                    const SizedBox(height: AppSizes.spacingXXL),
                    _buildSendOtpButton(),
                    const SizedBox(height: AppSizes.spacingXL),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.textPrimary,
            size: 32,
          ),
        ),
        const Spacer(),
        Text(
          'Sign Up',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 48), // Align text to center by balancing the Back button size
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personalisation',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0069F8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Verify and Proceed',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D293C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No Spams, Just Personalized Notification',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF62748E),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7C8BA0),
          ),
        ),
        const SizedBox(height: 8),
        CommonTextField(
          controller: _phoneController,
          focusNode: _focusNode,
          hintText: 'Enter device/child code',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF7C8BA0)),
          suffixIcon: _isPhoneValid
              ? Container(
                  margin: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8FAF6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF00C096),
                    size: 16,
                  ),
                )
              : null,
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
        ),
      ],
    );
  }

  Widget _buildValidationTip() {
    return Text(
      'we will generate otp automatically',
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF838383),
      ),
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppColors.borderColor,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
          child: Text(
            'Or sign up with',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7C8BA0),
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AppColors.borderColor,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    const String googleSvg = '''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
        <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
        <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
        <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/>
        <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
      </svg>
    ''';

    const String appleSvg = '''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 4.17c.66-.81 1.11-1.93.99-3.06-1 .04-2.22.67-2.94 1.5-.63.73-1.18 1.87-1.03 2.97 1.12.09 2.27-.56 2.98-1.41z"/>
      </svg>
    ''';

    return Column(
      children: [
        // Google button
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.string(googleSvg, width: 22, height: 22),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF040000),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Apple button
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.string(
                  appleSvg, 
                  width: 20, 
                  height: 24,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Apple',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (val) {
              setState(() {
                _agreeToTerms = val ?? false;
              });
            },
            activeColor: const Color(0xFF0066FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'I agree to the ',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF494949),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Terms of Service',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0066FF),
                  ),
                ),
              ),
              Text(
                ' & ',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF494949),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Privacy Policy',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSendOtpButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return InkWell(
          onTap: (isLoading || !_agreeToTerms) ? null : _sendOtp,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: (isLoading || !_agreeToTerms) 
                  ? const Color(0xFF0066FF).withValues(alpha: 0.5)
                  : const Color(0xFF0066FF),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _sendOtp() {
    if (!_agreeToTerms) {
      AppSnackbar.showError(context, 'You must agree to the Terms of Service & Privacy Policy');
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      final phoneNumber = _phoneController.text.trim();
      context.read<AuthBloc>().add(SendOtp(phoneNumber: phoneNumber));
    }
  }
}

