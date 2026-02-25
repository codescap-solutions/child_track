import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';

/// Shimmer skeleton for the GeoFencingView place card list loading state.
/// Mirrors a GeoPlaceCard: leading icon + title + subtitle + trailing toggle.
class GeoFencingShimmer extends StatelessWidget {
  final int itemCount;

  const GeoFencingShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Radius info bar placeholder
            Center(child: ShimmerBox(width: 200, height: 14, borderRadius: 6)),
            const SizedBox(height: 10),
            ...List.generate(itemCount, (_) => const _GeoPlaceCardSkeleton()),
          ],
        ),
      ),
    );
  }
}

class _GeoPlaceCardSkeleton extends StatelessWidget {
  const _GeoPlaceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingM,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          // Leading icon circle
          const ShimmerCircle(size: 40),
          const SizedBox(width: AppSizes.spacingM),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 120, height: 16),
                SizedBox(height: 6),
                ShimmerBox(width: 160, height: 12),
              ],
            ),
          ),

          // Toggle / arrow placeholder
          const ShimmerBox(width: 44, height: 26, borderRadius: 13),
        ],
      ),
    );
  }
}
