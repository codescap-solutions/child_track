import 'package:child_track/app/home/model/trip_list_model.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Trips List View - Shows all trips
class TripsView extends StatefulWidget {
  const TripsView({super.key});

  @override
  State<TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<TripsView> {
  late HomepageBloc _homepageBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _homepageBloc = injector<HomepageBloc>();
    _homepageBloc.add(GetTrips(page: 1, pageSize: 10));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.addListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      // TODO: Implement pagination load more
      _homepageBloc.add(GetTrips(page: 1, pageSize: 10));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

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
        bloc: _homepageBloc,
        builder: (context, state) {
          if (state is HomepageSuccess) {
            if (state.isLoadingTrips && state.trips.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.trips.isEmpty) {
              return const Center(child: Text("No trips found"));
            }

            return ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSizes.paddingL),
              itemCount: state.trips.length + (state.isLoadingTrips ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.trips.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final trip = state.trips[index];
                return _SimpleTripCard(trip: trip);
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// Simplified Trip Card for List View (No Map Data)
class _SimpleTripCard extends StatelessWidget {
  final Trip trip;

  const _SimpleTripCard({required this.trip});

  Set<Polyline> _createPolylines() {
    if (trip.points.isEmpty) return {};

    final coordinates = trip.points
        .map((point) => LatLng(point.lat, point.lng))
        .toList();

    return {
      Polyline(
        polylineId: PolylineId('trip_${trip.tripId}'),
        points: coordinates,
        color: AppColors.primaryColor,
        width: 3,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Set<Marker> _createMarkers() {
    if (trip.points.isEmpty) return {};

    final startPoint = trip.points.first;
    final endPoint = trip.points.last;

    return {
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(startPoint.lat, startPoint.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(endPoint.lat, endPoint.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  CameraPosition _getInitialCameraPosition() {
    if (trip.points.isEmpty) {
      return const CameraPosition(target: LatLng(0, 0), zoom: 1);
    }
    // Center map on the first point, or calculate bounds if possible (lite mode handles bounds poorly/static)
    // For lite mode, centering on start or midpoint is best.
    final midIndex = trip.points.length ~/ 2;
    return CameraPosition(
      target: LatLng(trip.points[midIndex].lat, trip.points[midIndex].lng),
      zoom: 13, // Adjust zoom as needed
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map Section
          SizedBox(
            height: 150,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusL),
                topRight: Radius.circular(AppSizes.radiusL),
              ),
              child: trip.points.isNotEmpty
                  ? GoogleMap(
                      initialCameraPosition: _getInitialCameraPosition(),
                      liteModeEnabled: true,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      polylines: _createPolylines(),
                      markers: _createMarkers(),
                      onMapCreated: (controller) {
                        // Optional: Bounds fitting could be attempted here if strictly needed
                        // but risky in ListView performance wise or race conditions.
                      },
                    )
                  : Container(
                      color: Colors.grey[100],
                      child: const Center(child: Text('No path data')),
                    ),
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trip.startTime} - ${trip.endTime}',
                            style: AppTextStyles.subtitle2.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${trip.distanceKm} km • ${trip.eventsCount} events',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CommonButton(
                      padding: EdgeInsets.zero,
                      width: 80,
                      text: 'View',
                      fontSize: 12,
                      textColor: AppColors.surfaceColor,
                      onPressed: () {
                        // Navigate to Detail View - will need to fetch detail inside there
                      },
                      height: 30,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingM),
                // Route info
                Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip.fromPlace,
                        style: AppTextStyles.body2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 3.5),
                  height: 16,
                  width: 1,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip.toPlace,
                        style: AppTextStyles.body2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
