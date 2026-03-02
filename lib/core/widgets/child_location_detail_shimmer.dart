import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';

/// Shimmer skeleton for ChildLocationDetailView full-page loading state.
/// Mirrors: 45% map area + activity card + screentime card + tracking banner.
class ChildLocationDetailShimmer extends StatelessWidget {
  const ChildLocationDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return ShimmerWrapper(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Map area placeholder (45% of screen height) ---
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: ShimmerBox(
                width: screenWidth - AppSizes.paddingM * 2,
                height: screenHeight * 0.45,
                borderRadius: AppSizes.radiusXL,
              ),
            ),

            // --- Content below map ---
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity card skeleton
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        const ShimmerBox(width: 220, height: 16),
                        const SizedBox(height: AppSizes.spacingM),

                        // Metrics row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      ShimmerBox(width: 70, height: 40),
                                      SizedBox(width: AppSizes.spacingS),
                                      ShimmerBox(width: 70, height: 40),
                                    ],
                                  ),
                                  const SizedBox(height: AppSizes.spacingS),
                                  Row(
                                    children: const [
                                      ShimmerBox(width: 80, height: 36),
                                      SizedBox(width: AppSizes.spacingS),
                                      ShimmerBox(width: 70, height: 40),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSizes.spacingM),
                            // Progress circle placeholder
                            const ShimmerCircle(size: 60),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacingM),
                        const Divider(color: Color(0xFFE0E0E0)),
                        // Footer row of card
                        Row(
                          children: const [
                            Expanded(
                              child: ShimmerBox(
                                width: double.infinity,
                                height: 32,
                              ),
                            ),
                            SizedBox(width: AppSizes.spacingM),
                            ShimmerBox(width: 78, height: 27, borderRadius: 6),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingM),

                  // Screentime card skeleton
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: Row(
                      children: const [
                        ShimmerBox(
                          width: 48,
                          height: 48,
                          borderRadius: AppSizes.radiusM,
                        ),
                        SizedBox(width: AppSizes.spacingS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(width: 160, height: 16),
                              SizedBox(height: 6),
                              ShimmerBox(width: 100, height: 12),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSizes.spacingM),
                        ShimmerBox(width: 70, height: 26, borderRadius: 6),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingM),

                  // Tracking banner skeleton
                  ShimmerBox(
                    width: double.infinity,
                    height: 72,
                    borderRadius: AppSizes.radiusL,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
