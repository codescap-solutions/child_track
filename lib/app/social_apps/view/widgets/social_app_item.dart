import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';

class SocialAppItem extends StatelessWidget {
  final ImageProvider icon;
  final String name;
  final String usage;
  final bool isLocked;

  const SocialAppItem({
    super.key,
    required this.icon,
    required this.name,
    required this.usage,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        side: BorderSide(color: AppColors.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingS,
          ),
          child: Row(
            children: [
              CircleAvatar(backgroundImage: icon, radius: 16),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.subtitle2),
                    const SizedBox(height: 2),
                    Text(
                      usage,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _LockIconButton(isLocked: isLocked),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockIconButton extends StatelessWidget {
  final bool isLocked;
  const _LockIconButton({required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 24,
      onPressed: () => _showLockDialog(context),
      icon: Image.asset(
        isLocked ? 'assets/images/lock.png' : 'assets/images/unlock.png',
        width: 24,
        height: 24,
      ),
    );
  }

  void _showLockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _LockDurationDialog(),
    );
  }
}

class _LockDurationDialog extends StatefulWidget {
  const _LockDurationDialog();

  @override
  State<_LockDurationDialog> createState() => _LockDurationDialogState();
}

class _LockDurationDialogState extends State<_LockDurationDialog> {
  int hours = 1;
  int minutes = 30;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceColor,
      contentPadding: const EdgeInsets.all(AppSizes.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepperColumn(
                label: 'hr',
                value: hours,
                onInc: () => setState(() => hours = (hours + 1).clamp(0, 23)),
                onDec: () => setState(() => hours = (hours - 1).clamp(0, 23)),
              ),
              const SizedBox(width: AppSizes.spacingL),
              _StepperColumn(
                label: 'min',
                value: minutes,
                step: 5,
                max: 55,
                onInc: () => setState(() => minutes = (minutes + 5) % 60),
                onDec: () => setState(
                  () => minutes = (minutes - 5) < 0 ? 55 : minutes - 5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingL),
          CommonButton(
            text: 'Lock',
            onPressed: () => Navigator.pop(
              context,
              Duration(hours: hours, minutes: minutes),
            ),
            width: 140,
            height: 40,
          ),
        ],
      ),
    );
  }
}

class _StepperColumn extends StatelessWidget {
  final String label;
  final int value;
  final int step;
  final int max;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _StepperColumn({
    required this.label,
    required this.value,
    this.step = 1,
    this.max = 23,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTextStyles.subtitle1.copyWith(
      fontWeight: FontWeight.w700,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.keyboard_arrow_up, onTap: onInc),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value.toString().padLeft(2, '0'),
                style: textStyle.copyWith(color: AppColors.textPrimary),
              ),
              TextSpan(
                text: '  $label',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _StepButton(icon: Icons.keyboard_arrow_down, onTap: onDec),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}
