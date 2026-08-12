import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';

/// Shimmer skeleton for the TripsView initial load state.
/// Each card mirrors: map area (150px) + time/distance row + 2 place rows.
class TripsShimmer extends StatelessWidget {
  final int itemCount;

  const TripsShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        itemCount: itemCount,
        itemBuilder: (_, __) => const _TripCardSkeleton(),
      ),
    );
  }
}

class _TripCardSkeleton extends StatelessWidget {
  const _TripCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map section placeholder
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSizes.radiusL),
              topRight: Radius.circular(AppSizes.radiusL),
            ),
            child: ShimmerBox(
              width: double.infinity,
              height: 150,
              borderRadius: 0,
            ),
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time + distance row
                Row(
                  children: const [
                    Expanded(
                      child: ShimmerBox(width: double.infinity, height: 16),
                    ),
                    SizedBox(width: AppSizes.spacingM),
                    ShimmerBox(width: 50, height: 26, borderRadius: 12),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingM),

                // From place row
                Row(
                  children: const [
                    ShimmerCircle(size: 10),
                    SizedBox(width: 8),
                    Expanded(
                      child: ShimmerBox(width: double.infinity, height: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // To place row
                Row(
                  children: const [
                    ShimmerCircle(size: 10),
                    SizedBox(width: 8),
                    Expanded(
                      child: ShimmerBox(width: double.infinity, height: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
