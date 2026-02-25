import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';

/// Shimmer skeleton for the SocialAppsView app list loading state.
/// Mirrors: screentime header card + a list of app rows.
class SocialAppsShimmer extends StatelessWidget {
  final int itemCount;

  const SocialAppsShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Screentime header card skeleton ---
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: 80, height: 14),
                        SizedBox(height: 8),
                        ShimmerBox(width: 120, height: 26),
                      ],
                    ),
                    const ShimmerBox(width: 100, height: 14),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingM),
                // Button placeholder
                ShimmerBox(
                  width: double.infinity,
                  height: 50,
                  borderRadius: AppSizes.radiusM,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.spacingM),

          // Filter tabs placeholder
          Row(
            children: const [
              ShimmerBox(width: 60, height: 36, borderRadius: 12),
              SizedBox(width: 8),
              ShimmerBox(width: 70, height: 36, borderRadius: 12),
              SizedBox(width: 8),
              ShimmerBox(width: 90, height: 36, borderRadius: 12),
            ],
          ),

          const SizedBox(height: AppSizes.spacingS),

          // --- App list skeleton ---
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              itemBuilder: (_, __) => const _AppRowSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppRowSkeleton extends StatelessWidget {
  const _AppRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
      child: Row(
        children: [
          // App icon circle
          const ShimmerCircle(size: 44),
          const SizedBox(width: AppSizes.spacingM),

          // App name + usage text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 140, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 80, height: 12),
              ],
            ),
          ),

          // Usage time / lock button area
          const ShimmerBox(width: 60, height: 28, borderRadius: 6),
        ],
      ),
    );
  }
}
