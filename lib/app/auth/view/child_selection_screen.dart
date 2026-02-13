import 'package:child_track/app/auth/view_model/bloc/auth_bloc.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_event.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_state.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChildSelectionScreen extends StatelessWidget {
  final List<Map<String, dynamic>> children;

  const ChildSelectionScreen({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: const Text('Select Child'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.surfaceColor,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.spacingL),
                Text(
                  'Who do you want to track?',
                  style: AppTextStyles.headline4,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingXXL),
                Expanded(
                  child: ListView.separated(
                    itemCount: children.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.spacingM),
                    itemBuilder: (context, index) {
                      final child = children[index];
                      return _buildChildCard(context, child);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, Map<String, dynamic> child) {
    final name = child['name'] as String? ?? 'Unknown';
    final childId = child['child_id'] as String? ?? child['_id'] as String?;
    final age = child['age'] as int?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: InkWell(
        onTap: () {
          if (childId != null) {
            context.read<AuthBloc>().add(SelectChild(childId: childId));
          }
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppTextStyles.headline4.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.subtitle1),
                    if (age != null)
                      Text(
                        '$age years old',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
