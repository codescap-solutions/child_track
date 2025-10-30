import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Widget? icon;
  final bool isEnabled;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.icon,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isEnabled && !isLoading ? onPressed : null;
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primaryColor;
    final effectiveTextColor = textColor ?? AppColors.surfaceColor;

    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height ?? AppSizes.buttonHeightM,
        child: OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: effectiveTextColor,
            side: BorderSide(
              color: isEnabled
                  ? effectiveBackgroundColor
                  : AppColors.borderColor,
              width: 1.5,
            ),
            padding:
                padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                  vertical: AppSizes.paddingM,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppSizes.radiusM,
              ),
            ),
          ),
          child: _buildButtonContent(),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height ?? AppSizes.buttonHeightM,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? effectiveBackgroundColor
              : AppColors.borderColor,
          foregroundColor: effectiveTextColor,
          elevation: isEnabled ? 2 : 0,
          padding:
              padding ??
              const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingL,
                vertical: AppSizes.paddingM,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppSizes.radiusM,
            ),
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? AppColors.primaryColor : AppColors.surfaceColor,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: AppSizes.paddingS),
          Text(
            text,
            style: AppTextStyles.button.copyWith(
              color: isEnabled ? textColor : AppColors.textHint,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: AppTextStyles.button.copyWith(
        color: isEnabled ? textColor : AppColors.textHint,
      ),
    );
  }
}
