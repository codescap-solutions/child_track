import 'package:child_track/app/childapp/view/sos_view.dart';
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
                  SizedBox(height: 40),
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
}
