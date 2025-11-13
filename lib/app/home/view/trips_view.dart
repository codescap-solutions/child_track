import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'trip_detail_view.dart';

/// Trips List View - Shows all trips with mini-map cards
class TripsView extends StatelessWidget {
  const TripsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Trips'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        itemCount: 3,
        itemBuilder: (context, index) {
          return _TripCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TripDetailView()),
            ),
          );
        },
      ),
    );
  }
}

/// Individual Trip Card Widget
class _TripCard extends StatelessWidget {
  final VoidCallback onTap;

  const _TripCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map Placeholder Section (Top part of card)
          _buildMapPlaceholder(context),

          // Trip Details Section (Bottom part of card)
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time and Duration Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '08:43 am - 21:20 pm (12hrs)',
                        style: AppTextStyles.subtitle2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Distance badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingM,
                        vertical: AppSizes.paddingS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                      ),
                      child: Text(
                        '16km',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.spacingM),

                // Locations
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingS),
                    Text(
                      'Kamakshi Palaya',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.spacingXS),

                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingS),
                    Text(
                      'Cubbon Park',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.spacingM),

                // View all button
                Align(
                  alignment: Alignment.centerRight,
                  child: CommonButton(
                    text: 'View all',
                    onPressed: onTap,
                    height: 36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Map Placeholder with beach-sand color (MAP-SCREEN RULE)
  Widget _buildMapPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.beach,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusL),
          topRight: Radius.circular(AppSizes.radiusL),
        ),
      ),
      child: Stack(
        children: [
          // Base beach-sand colored container
          Positioned.fill(child: Container(color: AppColors.beach)),

          // Purple route line placeholder
          Positioned(
            left: 50,
            right: 50,
            top: 80,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Yellow circular markers along route
          ...List.generate(
            5,
            (index) => Positioned(
              left: 60 + (index * 40.0),
              top: 70 + (index % 2 == 0 ? 10.0 : -10.0),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purple, width: 2),
                ),
              ),
            ),
          ),

          // START marker (green with house icon)
          Positioned(
            left: 50,
            top: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingS,
                vertical: AppSizes.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.home,
                    size: 16,
                    color: AppColors.surfaceColor,
                  ),
                  const SizedBox(width: AppSizes.spacingXS),
                  Text(
                    'START',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.surfaceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FINISH marker (green with tree icon)
          Positioned(
            right: 50,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingS,
                vertical: AppSizes.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.park,
                    size: 16,
                    color: AppColors.surfaceColor,
                  ),
                  const SizedBox(width: AppSizes.spacingXS),
                  Text(
                    'FINISH',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.surfaceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location labels placeholder
          Positioned(
            left: AppSizes.paddingM,
            top: AppSizes.paddingM,
            child: Text(
              'RAJAJINAGAR',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Positioned(
            right: AppSizes.paddingM,
            bottom: AppSizes.paddingM,
            child: Text(
              'Bengaluru Pa.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
