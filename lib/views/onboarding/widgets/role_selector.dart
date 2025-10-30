import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';

/// A pill-shaped segmented control to choose between Kid and Parent.
/// Reusable for other binary choices if needed.
class RoleSelector extends StatelessWidget {
  final String selected; // 'Kid' or 'Parent'
  final ValueChanged<String> onChanged;

  const RoleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isKid = selected == 'Kid';

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Kid',
              selected: isKid,
              onTap: () => onChanged('Kid'),
              isLeft: true,
            ),
          ),
          Container(width: 1, height: double.infinity, color: AppColors.borderColor),
          Expanded(
            child: _Segment(
              label: 'Parent',
              selected: !isKid,
              onTap: () => onChanged('Parent'),
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isLeft;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected ? Colors.white : Colors.transparent;
    final textColor = selected ? AppColors.textPrimary : AppColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(isLeft ? 32 : 0),
        right: Radius.circular(isLeft ? 0 : 32),
      ),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(isLeft ? 32 : 0),
            right: Radius.circular(isLeft ? 0 : 32),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.subtitle2.copyWith(color: textColor),
        ),
      ),
    );
  }
}


