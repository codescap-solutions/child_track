import 'package:child_track/app/home/model/trip_list_model.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/app/home/view/trip_detail_view.dart';
import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:child_track/core/utils/map_marker_utils.dart';

/// Trips List View - Shows all trips with day group headers,
/// pull-to-refresh, and proper UTC→local time display.
class TripsView extends StatefulWidget {
  const TripsView({super.key});

  @override
  State<TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<TripsView> {
  late HomepageBloc _homepageBloc;
  final ScrollController _scrollController = ScrollController();
  BitmapDescriptor? _sourceIcon;
  BitmapDescriptor? _destinationIcon;

  @override
  void initState() {
    super.initState();
    _homepageBloc = injector<HomepageBloc>();
    _homepageBloc.add(GetTrips(page: 1, pageSize: 10));
    _scrollController.addListener(_onScroll);
    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    try {
      final start = await MapMarkerUtils.getStartMarker();
      final end = await MapMarkerUtils.getEndMarker();
      if (mounted) {
        setState(() {
          _sourceIcon = start;
          _destinationIcon = end;
        });
      }
    } catch (e) {
      debugPrint('Error loading custom markers: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final state = _homepageBloc.state;
      if (state is HomepageSuccess &&
          !state.isLoadingTrips &&
          !state.hasReachedMax) {
        final nextPage = (state.tripsPage ?? 1) + 1;
        _homepageBloc.add(GetTrips(page: nextPage, pageSize: 10));
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _onRefresh() async {
    _homepageBloc.add(GetTrips(page: 1, pageSize: 10));
    // Wait a moment for the state to update
    await Future.delayed(const Duration(milliseconds: 800));
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
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text("No trips found")),
                  ],
                ),
              );
            }

            // Build items list with day group headers
            final items = _buildListItems(state.trips);

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSizes.paddingL),
                itemCount: state.hasReachedMax
                    ? items.length
                    : items.length + 1,
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = items[index];
                  if (item is _DayHeader) {
                    return _buildDayHeader(item.label);
                  }

                  final trip = item as Trip;
                  return _SimpleTripCard(
                    trip: trip,
                    sourceIcon: _sourceIcon,
                    destinationIcon: _destinationIcon,
                  );
                },
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  /// Build a mixed list of day headers and trip objects for the list view.
  List<Object> _buildListItems(List<Trip> trips) {
    final items = <Object>[];
    String? lastDayLabel;

    for (final trip in trips) {
      final dayLabel = trip.dayGroupLabel;
      if (dayLabel != lastDayLabel) {
        items.add(_DayHeader(dayLabel));
        lastDayLabel = dayLabel;
      }
      items.add(trip);
    }

    return items;
  }

  Widget _buildDayHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSizes.spacingL,
        bottom: AppSizes.spacingM,
      ),
      child: Text(
        label,
        style: AppTextStyles.headline6.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Marker class for day group headers in the list.
class _DayHeader {
  final String label;
  const _DayHeader(this.label);
}

// ─────────────────────────────────────────────────────────────────────
// Trip Card
// ─────────────────────────────────────────────────────────────────────
class _SimpleTripCard extends StatelessWidget {
  final Trip trip;
  final BitmapDescriptor? sourceIcon;
  final BitmapDescriptor? destinationIcon;

  const _SimpleTripCard({
    required this.trip,
    this.sourceIcon,
    this.destinationIcon,
  });

  IconData _getRideModeIcon(String rideMode) {
    switch (rideMode.toLowerCase()) {
      case 'walking':
        return Icons.directions_walk;
      case 'cycling':
        return Icons.directions_bike;
      case 'stationary':
        return Icons.location_on;
      case 'vehicle':
      default:
        return Icons.directions_car;
    }
  }

  Set<Polyline> _createPolylines() {
    if (trip.points.isEmpty) return {};

    final coordinates = trip.points
        .map((point) => LatLng(point.lat, point.lng))
        .toList();

    return {
      Polyline(
        polylineId: PolylineId('trip_${trip.tripId}'),
        points: coordinates,
        color: AppColors.tripPolyline,
        width: 3,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        patterns: trip.rideMode.toLowerCase() == 'walking'
            ? [PatternItem.dot, PatternItem.gap(10)]
            : [],
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
        icon:
            sourceIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(endPoint.lat, endPoint.lng),
        icon:
            destinationIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  CameraPosition _getInitialCameraPosition() {
    if (trip.points.isEmpty) {
      return const CameraPosition(target: LatLng(0, 0), zoom: 1);
    }
    final midIndex = trip.points.length ~/ 2;
    return CameraPosition(
      target: LatLng(trip.points[midIndex].lat, trip.points[midIndex].lng),
      zoom: 12,
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
          // Active trip indicator
          if (trip.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusL),
                  topRight: Radius.circular(AppSizes.radiusL),
                ),
              ),
              child: const Center(
                child: Text(
                  'ACTIVE TRIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

          // Map Section
          SizedBox(
            height: 150,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: trip.isActive
                  ? BorderRadius.zero
                  : const BorderRadius.only(
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
                        if (trip.points.isNotEmpty) {
                          final bounds = _createBounds(
                            trip.points
                                .map((p) => LatLng(p.lat, p.lng))
                                .toList(),
                          );
                          controller.moveCamera(
                            CameraUpdate.newLatLngBounds(bounds, 20),
                          );
                        }
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
                // Top Row: Time, Duration, Distance
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${trip.startTimeFormatted} - ${trip.endTimeFormatted}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '   ${trip.durationFormatted}',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Icon(_getRideModeIcon(trip.rideMode)),
                    const SizedBox(width: AppSizes.spacingM),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${trip.distanceKm}km',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingM),
                // Bottom Row: Timeline and View Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PlaceRenderer(
                            placeName: trip.fromPlace.isNotEmpty
                                ? trip.fromPlace
                                : 'Unknown Location',
                            point: trip.points.isNotEmpty
                                ? trip.points.first
                                : null,
                            iconColor: Colors.grey.shade400,
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 3.5),
                            height: 12,
                            width: 1,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          _PlaceRenderer(
                            placeName: trip.toPlace.isNotEmpty
                                ? trip.toPlace
                                : 'Unknown Location',
                            point: trip.points.isNotEmpty
                                ? trip.points.last
                                : null,
                            iconColor: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingM),
                    CommonButton(
                      padding: EdgeInsets.zero,
                      width: 80,
                      text: 'View',
                      fontSize: 12,
                      textColor: AppColors.surfaceColor,
                      onPressed: () {
                        if (trip.points.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("No detailed trip data available"),
                            ),
                          );
                          return;
                        }
                        final tripSegment = TripSegment.fromTrip(trip);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TripDetailView(
                              trip: tripSegment,
                              markers: _createMarkers().toList(),
                              polylines: _createPolylines().toList(),
                            ),
                          ),
                        );
                      },
                      height: 30,
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

  LatLngBounds _createBounds(List<LatLng> positions) {
    var south = positions.first.latitude;
    var north = positions.first.latitude;
    var west = positions.first.longitude;
    var east = positions.first.longitude;

    for (var i = 1; i < positions.length; i++) {
      var p = positions[i];
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Place Renderer (with reverse geocoding fallback)
// ─────────────────────────────────────────────────────────────────────
class _PlaceRenderer extends StatefulWidget {
  final String placeName;
  final TripPoint? point;
  final Color iconColor;

  const _PlaceRenderer({
    required this.placeName,
    required this.point,
    required this.iconColor,
  });

  @override
  State<_PlaceRenderer> createState() => _PlaceRendererState();
}

class _PlaceRendererState extends State<_PlaceRenderer> {
  String? _resolvedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_shouldResolveAddress()) {
      _resolveAddress();
    }
  }

  bool _shouldResolveAddress() {
    return widget.placeName == "Unknown Location" && widget.point != null;
  }

  Future<void> _resolveAddress() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        widget.point!.lat,
        widget.point!.lng,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        setState(() {
          // Construct a simple address string
          _resolvedAddress = [
            place.street,
            place.subLocality,
            place.locality,
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          if (_resolvedAddress!.isEmpty) {
            _resolvedAddress = "${place.name}";
          }
        });
      }
    } catch (e) {
      // debugPrint('Failed to resolve address: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _resolvedAddress ?? widget.placeName;

    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: widget.iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: _isLoading
              ? SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary,
                  ),
                )
              : Text(
                  displayText,
                  style: AppTextStyles.body2,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }
}
