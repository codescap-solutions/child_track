import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/map/view/map_view.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Trip Detail View - Shows detailed trip with map and timeline
class TripDetailView extends StatelessWidget {
  const TripDetailView({
    super.key,
    required this.markers,
    required this.polylines,
    required this.trip,
  });
  final List<Marker> markers;
  final List<Polyline> polylines;
  final TripSegment trip;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Map Section (Full screen)
          _buildMapSection(context, markers, polylines),

          // Bottom Sheet with Trip Timeline
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusXL),
                    topRight: Radius.circular(AppSizes.radiusXL),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSizes.spacingM,
                      ),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Trip Time Range
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingL,
                      ),
                      child: Text(
                        '${trip.startTime} - ${trip.endTime}',
                        style: AppTextStyles.headline6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingL),

                    // Trip Timeline
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingL,
                        ),
                        children: [
                          _buildTimelineItem(
                            icon: Icons.home,
                            title: trip.startPlace,
                            time: trip.startTime,
                            color: AppColors.primaryColor,
                          ),
                          // _buildTimelineItem(
                          //   icon: Icons.directions_bus,
                          //   title: 'Ride',
                          //   subtitle: '6.4km (37min)',
                          //   time: null,
                          //   badge: 'max speed - 24.5 kmp',
                          //   color: AppColors.info,
                          // ),
                          _buildTimelineItem(
                            icon: Icons.school,
                            title: trip.endPlace,
                            time: trip.endTime,
                            color: AppColors.success,
                          ),

                          // // Additional items for scroll demonstration
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Map Section with Google Maps showing route
  Widget _buildMapSection(
    BuildContext context,
    List<Marker> markers,
    List<Polyline> polylines,
  ) {
    return Stack(
      children: [
        // Google Map (Full screen)
        Positioned.fill(
          child: MapViewWidget(
            width: double.infinity,
            height: double.infinity,
            currentPosition: markers.first.position,
            markers: markers,
            polylines: polylines,
            isPolyLines: true,
          ),
        ),

        // App Bar Overlay
        SafeArea(
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: AppColors.textPrimary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: const Text(
                'Trip Details',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            centerTitle: true,
          ),
        ),

        // Location labels overlay
        Positioned(
          left: AppSizes.paddingL,
          top: 100,
          child: _buildLocationLabel(markers.first.infoWindow.title ?? 'Start'),
        ),

        Positioned(
          right: AppSizes.paddingL,
          bottom: 200,
          child: _buildLocationLabel(markers.last.infoWindow.title ?? 'End'),
        ),
      ],
    );
  }

  // Location Label Widget
  Widget _buildLocationLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingS,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  // Timeline Item Widget
  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? time,
    String? badge,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and icon
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (icon == Icons.home)
                Container(width: 2, height: 60, color: AppColors.borderColor),
            ],
          ),

          const SizedBox(width: AppSizes.spacingM),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSizes.spacingXS),
                            Text(
                              subtitle,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (badge != null) ...[
                            const SizedBox(height: AppSizes.spacingXS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingS,
                                vertical: AppSizes.paddingXS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusS,
                                ),
                              ),
                              child: Text(
                                badge,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (time != null)
                      Text(
                        time,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingXS),
                if (icon == Icons.home)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.paddingS),
                    decoration: BoxDecoration(
                      color: AppColors.containerBackground,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.type.toUpperCase()),
                        Text(
                          '${trip.distanceKm}km (${trip.durationMinutes}min)',
                        ),
                        const SizedBox(height: AppSizes.spacingXS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingS,
                            vertical: AppSizes.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusS,
                            ),
                          ),
                          child: Text(
                            'max speed - ${trip.maxSpeedKmph} kmp',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
