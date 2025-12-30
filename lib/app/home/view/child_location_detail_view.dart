import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/view/trips_view.dart';
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

class ChildLocationDetailView extends StatelessWidget {
  const ChildLocationDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: injector<HomepageBloc>()..add(GetHomepageData()),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceColor,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Kid Location Details'),
        ),
        body: SingleChildScrollView(
          child: BlocBuilder<HomepageBloc, HomepageState>(
            builder: (context, state) {
              if (state is HomepageSuccess) {
                if (state.yesterdayTrips.isEmpty) {
                  return const Center(child: Text('No trip data available'));
                }
                final currentLocation = state.currentLocation;
                final trip = state.yesterdayTrips.first;
                return Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSizes.paddingM,
                              right: AppSizes.paddingM,
                              //bottom: AppSizes.paddingM,
                              top: AppSizes.paddingM,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusXL,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusXL,
                                  ),
                                ),
                                // padding: const EdgeInsets.all(AppSizes.paddingM),
                                child: MapViewWidget(
                                  interactive: true,
                                  isPolyLines: true,

                                  width: double.infinity,
                                  height: double.infinity,
                                  currentPosition: LatLng(
                                    currentLocation?.lat ?? 0,
                                    currentLocation?.lng ?? 0,
                                  ),
                                  markers: [
                                    Marker(
                                      markerId: MarkerId('start'),
                                      position: LatLng(
                                        trip.startLocation.latitude,
                                        trip.startLocation.longitude,
                                      ),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                            BitmapDescriptor.hueGreen,
                                          ),
                                    ),
                                    Marker(
                                      markerId: MarkerId('end'),
                                      position: LatLng(
                                        trip.endLocation.latitude,
                                        trip.endLocation.longitude,
                                      ),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                            BitmapDescriptor.hueRed,
                                          ),
                                    ),
                                  ],
                                  polylines: [
                                    Polyline(
                                      polylineId: PolylineId('route'),
                                      points: trip.polylinePoints,
                                      color: AppColors.error,
                                      width: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Positioned(
                          //   top: 0,
                          //   right: 0,
                          //   child: _buildTripTodayCard(context)
                          // ),
                          Positioned(
                            bottom: 10,
                            right: 30,
                            left: 30,
                            child: _buildTripTodayCard(
                              context,
                              withMargin: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildChildLocationCardContent(context, trip),
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
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
                '08:43 am - 21:20 pm (12hrs)',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              // const SizedBox(height: AppSizes.spacingXS),
              Text(
                'Kamakshi Palaya - Cubbon Park',
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
                    child: Text('4 Events', style: AppTextStyles.caption),
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
                      'today',
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
          const Spacer(),
          CommonButton(
            padding: EdgeInsets.zero,
            width: 80,
            text: 'View all',
            fontSize: 12,
            textColor: AppColors.surfaceColor,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TripsView()),
            ),
            height: 30,
          ),
        ],
      ),
    );
  }

  // First View: Child Location Info Card Content
  Widget _buildChildLocationCardContent(
    BuildContext context,
    TripSegment trip,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Second View: Trip Today Card
              //  _buildTripTodayCard(context),

              // Activity Today Card
              _buildActivityTodayCard(context, trip),
              const SizedBox(height: AppSizes.spacingM),

              // Screentime Card
              _buildScreentimeCard(context),
              const SizedBox(height: AppSizes.spacingM),

              // Infinite Real-Time Tracking Card
              _buildInfiniteTrackingCard(),

              const SizedBox(height: AppSizes.spacingXL),
            ],
          ),
        ],
      ),
    );
  }

  // Activity Today Card
  Widget _buildActivityTodayCard(BuildContext context, TripSegment trip) {
    return Container(
      // margin: const EdgeInsets.all(AppSizes.paddingM),
      padding: const EdgeInsets.all(AppSizes.paddingM),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${trip.type.toUpperCase()} - ${trip.startTime} - ${trip.endTime}',
            style: AppTextStyles.headline6.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity metrics
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActivityMetric(
                          '${trip.distanceKm} km',
                          'Distance',
                        ),
                        const SizedBox(width: AppSizes.spacingS),
                        _buildActivityMetric(
                          '${trip.durationMinutes} min',
                          'Duration',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        _buildActivityMetric(
                          '${trip.startPlace} - ${trip.endPlace}',

                          'Route',
                        ),
                        const SizedBox(width: AppSizes.spacingS),
                        _buildActivityMetric(
                          '${trip.maxSpeedKmph} km/h',
                          'Max Speed',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Progress indicator
              // Progress indicator
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: trip.progress / 100,
                            strokeWidth: 8,
                            backgroundColor: AppColors.borderColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor,
                            ),
                          ),
                        ),
                        Text(
                          '${trip.progress}%',
                          style: AppTextStyles.subtitle1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: Text(
                        'more distance walked than last day',
                        maxLines: 3,
                        textAlign: TextAlign.start,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          Divider(color: AppColors.borderColor, thickness: 1),
          Row(
            children: [
              Text(
                'Track your child\'s weekly progress\nand get personalized growth tips!',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 78,
                  height: 27,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TripsView()),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textPrimary),
                      padding: const EdgeInsets.symmetric(),
                    ),
                    child: Text('View all', style: AppTextStyles.caption),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Activity Metric Widget
  Widget _buildActivityMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.subtitle1.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: AppSizes.spacingXS),
        Text(
          label,

          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // Screentime Card
  Widget _buildScreentimeCard(BuildContext context) {
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: const Icon(
              Icons.grid_view,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSizes.spacingXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2.3hrs of screentime',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                Row(
                  children: [
                    // App icons placeholder
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingXS),
                    Text(
                      'and more yesterday',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CommonButton(
            padding: EdgeInsets.zero,
            width: 70,
            text: 'View all',
            fontSize: 12,
            textColor: AppColors.surfaceColor,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TripsView()),
            ),
            height: 26,
          ),
        ],
      ),
    );
  }

  // Infinite Real-Time Tracking Card (Bottom)
  Widget _buildInfiniteTrackingCard() {
    return Container(
      // margin: const EdgeInsets.all(AppSizes.paddingL),
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFINITE REAL-TIME TRACKING',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    4,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSizes.spacingXS,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: AppSizes.spacingXS),
                          Text(
                            'Unlimited Updated, just for you',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Gift box placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AppColors.primaryColor,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
