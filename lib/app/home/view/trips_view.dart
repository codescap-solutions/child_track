import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_bloc.dart';
import 'package:child_track/app/map/view/map_view.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
        title: Text(
          'Trips',
          style: AppTextStyles.headline5.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: BlocBuilder<HomepageBloc, HomepageState>(
        bloc: injector<HomepageBloc>(),
        builder: (context, state) {
          if (state is HomepageSuccess) {
            return ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSizes.paddingL),
              itemCount: state.yesterdayTrips.length,
              itemBuilder: (context, index) {
                final trip = state.yesterdayTrips[index];
                return _TripCard(
                  trip: trip,
                  markers: [
                    Marker(
                      markerId: const MarkerId('start'),
                      position: trip.startLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                    ),
                    Marker(
                      markerId: const MarkerId('end'),
                      position: trip.endLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  ],
                  polylines: [
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: trip.polylinePoints,
                      color: Colors.purple,
                      width: 4,
                    ),
                  ],
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

/// Individual Trip Card Widget
class _TripCard extends StatelessWidget {
  final List<Marker> markers;
  final List<Polyline> polylines;
  const _TripCard({
    required this.markers,
    required this.polylines,
    required this.trip,
  });
  final TripSegment trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      margin: const EdgeInsets.only(bottom: AppSizes.spacingL),

      decoration: BoxDecoration(
        color: AppColors.surfaceColor,

        borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusL)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildMapSection(markers, polylines, context),
          Positioned(
            bottom: 10,
            right: 10,
            left: 10,
            child: _buildTripTodayCard(context, withMargin: false),
          ),
        ],
      ),
    );
  }

  // Map Section with Google Maps showing static route
  Widget _buildMapSection(
    List<Marker> markers,
    List<Polyline> polylines,
    context,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppSizes.radiusL),
        topRight: Radius.circular(AppSizes.radiusL),
      ),
      child: Stack(
        children: [
          MapViewWidget(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.40,
            markers: markers,
            polylines: polylines,
            isPolyLines: true,
            interactive: false, // Disable touch to move
            currentPosition: markers.first.position,
            myLocationEnabled: false, // Disable my location
            myLocationButtonEnabled: false,
            minZoom: 10.0,
            maxZoom: 11.0,
          ),
        ],
      ),
    );
  }

  Widget _buildTripTodayCard(BuildContext context, {bool withMargin = true}) {
    return Container(
      height: 85,
      margin: withMargin
          ? const EdgeInsets.symmetric(horizontal: AppSizes.paddingL)
          : EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSizes.paddingS),
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
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${trip.startTime} - ${trip.endTime} (${trip.durationMinutes} mins)',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              // const SizedBox(height: AppSizes.spacingXS),
              Text(
                '${trip.startPlace} - ${trip.endPlace}',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingXS,
                      vertical: AppSizes.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Text(
                      '${trip.segmentId} Events',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingS,
                      vertical: AppSizes.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Text(
                      trip.type.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Spacer(),
          CommonButton(
            padding: EdgeInsets.zero,
            width: 80,
            text: 'View all',
            fontSize: 12,
            textColor: AppColors.surfaceColor,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripDetailView(
                  trip: trip,
                  markers: markers,
                  polylines: polylines,
                ),
              ),
            ),
            height: 30,
          ),
        ],
      ),
    );
  }
}
