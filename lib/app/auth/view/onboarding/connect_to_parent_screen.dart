import 'package:child_track/app/childapp/view/sos_view.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
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
  final _parentCodeController = TextEditingController();
  final _sharedPrefsService = SharedPrefsService();
  bool _isLoading = false;

  @override
  void dispose() {
    _parentCodeController.dispose();
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
                  _buildParentCodeField(),
                  const SizedBox(height: AppSizes.spacingL),
                  _buildInfoText(),
                  const Spacer(),
                  CommonButton(
                    text: 'Connect',
                    onPressed: _isLoading ? null : _connectToParent,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  CommonButton(
                    text: 'Skip for now',
                    onPressed: _isLoading ? null : _skipConnection,
                    isOutlined: true,
                  ),
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
          'Enter the parent code to share your location and screen time',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildParentCodeField() {
    return CommonTextField(
      fillColor: AppColors.containerBackground,
      controller: _parentCodeController,
      hintText: 'Enter parent code',
      labelText: 'Parent Code',
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter parent code';
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
        final parentCode = _parentCodeController.text.trim();
        
        // Save parent code for future use
        await _sharedPrefsService.setString('parent_code', parentCode);
        
        AppLogger.info('Connected to parent with code: $parentCode');
        
        // TODO: Call API to connect to parent if needed
        // For now, just save and navigate
        
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Connected to parent successfully');
          
          // Navigate to SOS view (child app main screen)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const SosView(),
            ),
          );
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


