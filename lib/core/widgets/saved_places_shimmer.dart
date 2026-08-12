import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';

/// Shimmer skeleton for AddandSavePlace and SavedPlacesView list loading state.
/// Mirrors a saved-place card: 48px icon box + title + address + saved-date.
class SavedPlacesShimmer extends StatelessWidget {
  final int itemCount;

  const SavedPlacesShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        itemCount: itemCount,
        itemBuilder: (_, __) => const _PlaceCardSkeleton(),
      ),
    );
  }
}

class _PlaceCardSkeleton extends StatelessWidget {
  const _PlaceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          // Icon placeholder
          const ShimmerBox(
            width: 48,
            height: 48,
            borderRadius: AppSizes.radiusM,
          ),
          const SizedBox(width: AppSizes.spacingM),

          // Title, address, date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 120, height: 16),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 12),
                SizedBox(height: 4),
                ShimmerBox(width: 100, height: 10),
              ],
            ),
          ),

          // Delete icon placeholder
          const SizedBox(width: AppSizes.spacingM),
          const ShimmerCircle(size: 24),
        ],
      ),
    );
  }
}
