import 'package:child_track/app/auth/view/onboarding/connect_to_parent_screen.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/widgets/common_textfield.dart';

class AddKidView extends StatefulWidget {
  const AddKidView({super.key});

  @override
  State<AddKidView> createState() => _AddKidViewState();
}

class _AddKidViewState extends State<AddKidView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _childRepo = injector<ChildRepo>();
  final _sharedPrefsService = SharedPrefsService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
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
                  Text(
                    textAlign: TextAlign.center,
                    'Add Kid',
                    style: AppTextStyles.headline1.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  Text(
                    textAlign: TextAlign.center,
                    'It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum.',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXL),
                  CommonTextField(
                    fillColor: AppColors.containerBackground,
                    controller: _nameController,
                    hintText: 'Enter child name',
                    labelText: 'Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter child name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  CommonTextField(
                    fillColor: AppColors.containerBackground,
                    controller: _ageController,
                    hintText: 'Enter age',
                    labelText: 'Age',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter age';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 1 || age > 18) {
                        return 'Please enter a valid age (1-18)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  CommonButton(
                    text: 'Next',
                    onPressed: _isLoading ? null : _createChild,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createChild() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final name = _nameController.text.trim();
        final age = int.parse(_ageController.text.trim());
        
        final response = await _childRepo.createChild(name: name, age: age);
        
        if (response.isSuccess && response.data != null) {
          final childCode = response.data!['child_code'] as String?;
          final childId = response.data!['child_id'] as String?;
          
          if (childCode != null) {
            // Save child code and child ID
            await _sharedPrefsService.setString('child_code', childCode);
            if (childId != null) {
              await _sharedPrefsService.setString('child_id', childId);
            }
            
            AppLogger.info('Child created successfully. Code: $childCode');
            
            // Navigate to connect to parent screen
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const ConnectToParentScreen(),
                ),
              );
            }
          } else {
            if (mounted) {
              AppSnackbar.showError(context, 'Child code not received');
            }
          }
        } else {
          if (mounted) {
            AppSnackbar.showError(context, response.message);
          }
        }
      } catch (e) {
        AppLogger.error('Error creating child: ${e.toString()}');
        if (mounted) {
          AppSnackbar.showError(context, 'Failed to create child: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
