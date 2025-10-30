import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/widgets/common_textfield.dart';

class ProfileForm extends StatefulWidget {
  final bool isEdit;
  const ProfileForm({super.key, required this.isEdit});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'VANCHAI');
  final _emailController = TextEditingController(text: 'yanchu@gmail.com');
  final _phoneController = TextEditingController(text: '+14867888899');
  final _genderController = TextEditingController(text: 'Male');
  final _dobController = TextEditingController(text: '12/12/2000');
  final _passwordController = TextEditingController(text: 'eWTrByvGc4');
  final _idController = TextEditingController(text: '2723-202408282');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 56),
          _label('Name'),
          CommonTextField(controller: _nameController, hintText: 'Name'),
          const SizedBox(height: AppSizes.spacingM),
          _label('Email Id'),
          CommonTextField(
            controller: _emailController,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSizes.spacingM),
          _label('Phone Number'),
          CommonTextField(
            controller: _phoneController,
            hintText: 'Phone',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSizes.spacingM),
          _label('Gender'),
          _GenderField(controller: _genderController),
          const SizedBox(height: AppSizes.spacingM),
          _label('Date of Birth ( DD/MM/YR )'),
          _DobField(controller: _dobController),
          const SizedBox(height: AppSizes.spacingM),
          _label('Password'),
          CommonTextField(
            controller: _passwordController,
            hintText: 'Password',
            obscureText: true,
          ),
          if (!widget.isEdit) ...[
            const SizedBox(height: AppSizes.spacingM),
            _label('ID Number'),
            CommonTextField(controller: _idController, hintText: 'ID Number'),
          ],
          const SizedBox(height: AppSizes.spacingXL),
          CommonButton(
            text: widget.isEdit ? 'Update' : 'Add',
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(widget.isEdit ? 'Updated' : 'Added')),
                );
              }
            },
            height: 44,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GenderField extends StatelessWidget {
  final TextEditingController controller;
  const _GenderField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: controller.text,
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (v) => controller.text = v ?? 'Male',
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
      ),
    );
  }
}

class _DobField extends StatelessWidget {
  final TextEditingController controller;
  const _DobField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(now.year - 10, now.month, now.day),
          firstDate: DateTime(1970),
          lastDate: now,
        );
        if (picked != null) {
          final day = picked.day.toString().padLeft(2, '0');
          final month = picked.month.toString().padLeft(2, '0');
          final year = picked.year.toString();
          controller.text = '$day/$month/$year';
        }
      },
      child: IgnorePointer(
        child: CommonTextField(controller: controller, hintText: 'DD/MM/YR'),
      ),
    );
  }
}
