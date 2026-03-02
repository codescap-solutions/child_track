import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';

/// Shimmer skeleton for the HomePage bottom sheet loading state.
/// Mirrors: location title/subtitle, status chips, feature cards, banner, list tile.
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder gives us a finite maxWidth so ShimmerBox can use double.infinity
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth - (AppSizes.paddingM * 2)
            : 300.0;

        return ShimmerWrapper(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSizes.spacingS),

                // --- Location title + save-place button row ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: 180, height: 22),
                        SizedBox(height: 8),
                        ShimmerBox(width: 100, height: 14),
                      ],
                    ),
                    const ShimmerBox(width: 90, height: 32, borderRadius: 8),
                  ],
                ),

                const SizedBox(height: AppSizes.spacingM),

                // --- Status chips row (battery · wifi · sound) ---
                Row(
                  children: const [
                    ShimmerBox(width: 70, height: 28, borderRadius: 6),
                    SizedBox(width: AppSizes.spacingS),
                    ShimmerBox(width: 70, height: 28, borderRadius: 6),
                    SizedBox(width: AppSizes.spacingS),
                    ShimmerBox(width: 70, height: 28, borderRadius: 6),
                  ],
                ),

                const SizedBox(height: AppSizes.spacingM),

                // --- Feature cards row (Scroll & Geo Guard) ---
                Row(
                  children: [
                    ShimmerBox(
                      width: (fullWidth - AppSizes.spacingM) / 2,
                      height: 100,
                      borderRadius: AppSizes.radiusM,
                    ),
                    const SizedBox(width: AppSizes.spacingM),
                    ShimmerBox(
                      width: (fullWidth - AppSizes.spacingM) / 2,
                      height: 100,
                      borderRadius: AppSizes.radiusM,
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.spacingM),

                // --- Tracking banner placeholder ---
                ShimmerBox(
                  width: fullWidth,
                  height: 72,
                  borderRadius: AppSizes.radiusM,
                ),

                const SizedBox(height: AppSizes.spacingM),

                // --- Location history list tile placeholder ---
                ShimmerBox(
                  width: fullWidth,
                  height: 56,
                  borderRadius: AppSizes.radiusM,
                ),

                const SizedBox(height: AppSizes.spacingM),
              ],
            ),
          ),
        );
      },
    );
  }
}
