import 'package:child_track/app/childapp/view/sos_view.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/widgets/common_textfield.dart';

class ConnectToParentScreen extends StatefulWidget {
  const ConnectToParentScreen({super.key});

  @override
  State<ConnectToParentScreen> createState() => _ConnectToParentScreenState();
}

class _ConnectToParentScreenState extends State<ConnectToParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childCodeController = TextEditingController();
  final _childRepo = injector<ChildRepo>();
  bool _isLoading = false;

  @override
  void dispose() {
    _childCodeController.dispose();
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
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  _buildHeader(),
                  const SizedBox(height: AppSizes.spacingXL),
                  _buildChildCodeField(),
                  const SizedBox(height: AppSizes.spacingL),
                  _buildInfoText(),
                  const Spacer(),
                  CommonButton(
                    text: 'Connect',
                    onPressed: _isLoading ? null : _connectToParent,
                    isLoading: _isLoading,
                  ),
                  // const SizedBox(height: AppSizes.spacingM),
                  // CommonButton(
                  //   text: 'Skip for now',
                  //   onPressed: _isLoading ? null : _skipConnection,
                  //   isOutlined: true,
                  // ),
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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
          ),
          child: const Icon(
            Icons.family_restroom,
            size: 50,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacingL),
        Text(
          'Connect to Parent',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingS),
        Text(
          'Enter your child code to connect and share your location and screen time',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChildCodeField() {
    return CommonTextField(
      fillColor: AppColors.containerBackground,
      controller: _childCodeController,
      hintText: 'Enter child code',
      labelText: 'Child Code',
      textInputAction: TextInputAction.done,
      inputFormatters: [
        UpperCaseTextFormatter(),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter child code';
        }
        if (value.length < 4) {
          return 'Child code must be at least 4 characters';
        }
        return null;
      },
      onSubmitted: (_) => _connectToParent(),
    );
  }

  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: AppSizes.spacingS),
          Expanded(
            child: Text(
              'By connecting, you allow your parent to view your location and screen time.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToParent() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final childCode = _childCodeController.text.trim().toUpperCase();
        
        AppLogger.info('Logging in with child code: $childCode');
        
        // Call child login API
        final response = await _childRepo.childLogin(childCode: childCode);
        
        if (response.isSuccess) {
          AppLogger.info('Child login successful');
          
          if (mounted) {
            AppSnackbar.showSuccess(context, 'Connected successfully!');
            
            // Navigate to SOS view (child app main screen)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const SosView(),
              ),
            );
          }
        } else {
          if (mounted) {
            AppSnackbar.showError(context, response.message);
          }
        }
      } catch (e) {
        AppLogger.error('Error connecting to parent: ${e.toString()}');
        if (mounted) {
          AppSnackbar.showError(context, 'Failed to connect: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _skipConnection() {
    // Navigate to SOS view without connecting
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SosView(),
      ),
    );
  }
}

// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

