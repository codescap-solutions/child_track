import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/widgets/common_textfield.dart';
import '../../../childapp/sos_view.dart';

class AddKidView extends StatefulWidget {
  const AddKidView({super.key});

  @override
  State<AddKidView> createState() => _AddKidViewState();
}

class _AddKidViewState extends State<AddKidView> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
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
                    controller: _idController,
                    hintText: 'identity number',
                  ),
                 // const Spacer(),
                 SizedBox(height: 40,),
                  CommonButton(
                    text: 'Next',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SosView()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< Updated upstream
=======

  Future<void> _createChild() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final name = _nameController.text.trim();
        final age = int.parse(_ageController.text.trim());

        final response = await _childRepo.createChild(name: name, age: age);

        if (response.isSuccess && response.data != null) {
          // Extract child data from nested structure
          final childData = response.data!['child'] as Map<String, dynamic>?;
          final childCode = childData?['child_code'] as String?;
          final childId = childData?['child_id'] as String?;

          if (childId != null) {
            // Save child ID (this is what we need for home API)
            await _sharedPrefsService.setString('child_id', childId);
            // Update children count
            final currentCount =
                _sharedPrefsService.getInt('children_count') ?? 0;
            await _sharedPrefsService.setInt(
              'children_count',
              currentCount + 1,
            );

            if (childCode != null) {
              // Save child code for display
              await _sharedPrefsService.setString('child_code', childCode);
            }

            AppLogger.info(
              'Child created successfully. ID: $childId, Code: $childCode',
            );

            // Navigate to child code screen
            if (mounted && childCode != null) {
              Navigator.of(context).pushReplacementNamed(
                RouteNames.childCode,
                arguments: {'childCode': childCode},
              );
            } else if (mounted) {
              // Navigate to home if child code is not available
              Navigator.of(context).pushNamedAndRemoveUntil(
                RouteNames.home,
                (route) => false,
              );
            }
          } else {
            if (mounted) {
              AppSnackbar.showError(context, 'Child ID not received');
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
          AppSnackbar.showError(
            context,
            'Failed to create child: ${e.toString()}',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
>>>>>>> Stashed changes
}
