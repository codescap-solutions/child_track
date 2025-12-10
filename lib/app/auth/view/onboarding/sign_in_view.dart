import 'package:child_track/app/auth/view/onboarding/add_kid_view.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_bloc.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_event.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_state.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/widgets/common_textfield.dart';

class SignInView extends StatefulWidget {
  final String? phoneNumber;

  const SignInView({super.key, this.phoneNumber});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill phone number if provided
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: injector<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // After successful registration, navigate to add child screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const AddKidView(),
              ),
            );
          } else if (state is AuthError) {
            AppSnackbar.showError(context, state.message);
          }
        },
        child: Scaffold(
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
                    const SizedBox(height: AppSizes.spacingL),
                    Text(
                      'Complete Registration',
                      style: AppTextStyles.headline3.copyWith(
                        color: AppColors.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    Text(
                      'Please provide your details to complete the registration.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.spacingXL),
                    CommonTextField(
                      fillColor: AppColors.containerBackground,
                      controller: _phoneController,
                      hintText: 'Phone Number',
                      labelText: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      enabled: false, // Disable editing since it's pre-filled
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    CommonTextField(
                      fillColor: AppColors.containerBackground,
                      controller: _nameController,
                      hintText: 'Enter your name',
                      labelText: 'Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const Spacer(),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return CommonButton(
                          text: 'Register',
                          onPressed: isLoading ? null : _register,
                          isLoading: isLoading,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _register() {
    if (_formKey.currentState?.validate() ?? false) {
      final phoneNumber = _phoneController.text.trim();
      final name = _nameController.text.trim();
      
      context.read<AuthBloc>().add(
        RegisterUser(
          phoneNumber: phoneNumber,
          name: name,
          // Address can be added later if needed
        ),
      );
    }
  }
}
