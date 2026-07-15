import 'package:child_track/app/home/model/trip_list_model.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_bloc.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_state.dart';
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
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:child_track/core/utils/map_marker_utils.dart';
import 'package:child_track/core/widgets/trips_shimmer.dart';

/// Trips List View - Shows all trips
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
    _scrollController.addListener(_onScroll);
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
              return const TripsShimmer();
            }

            if (!state.isLoadingTrips && state.trips.isEmpty) {
              return const Center(child: Text("No trips found"));
            }

            return ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSizes.paddingL),
              // Add +1 for loader if loading more
              itemCount: state.hasReachedMax
                  ? state.trips.length
                  : state.trips.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.trips.length) {
                  return const TripsShimmer(itemCount: 1);
                }
                final trip = state.trips[index];
                return _SimpleTripCard(
                  trip: trip,
                  sourceIcon: _sourceIcon,
                  destinationIcon: _destinationIcon,
                );
              },
            );
          }
          return const TripsShimmer();
        },
      ),
    );
  }
}

// Simplified Trip Card for List View (No Map Data)
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

  String _formatDateLabel(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      DateTime dt;
      try {
        dt = DateTime.parse(timeStr).toLocal();
      } catch (_) {
        final inputFormat = DateFormat('dd-MM-yyyy HH:mm:ss');
        dt = inputFormat.parse(timeStr, true).toLocal();
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateToCheck = DateTime(dt.year, dt.month, dt.day);

      if (dateToCheck == today) {
        return 'Today';
      } else if (dateToCheck == yesterday) {
        return 'Yesterday';
      } else {
        return DateFormat('d MMM yyyy').format(dt);
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDateLabel(trip.startTime);
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
                            if (dateLabel.isNotEmpty)
                              TextSpan(
                                text: '$dateLabel, ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            TextSpan(
                              text:
                                  '${_formatTime(trip.startTime)} - ${_formatTime(trip.endTime)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '   ${_calculateDuration(trip.startTime, trip.endTime)}',
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
                        injector<HomepageBloc>().add(
                          GetTripDetail(tripId: trip.tripId),
                        );
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
                // Removed redundant SizedBox and PlaceRenderers that were here
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

  String _calculateDuration(String startStr, String endStr) {
    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      final duration = end.difference(start);
      if (duration.isNegative) return '(Invalid Trip Data)';
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);

      if (hours > 0) {
        return '(${hours}hrs ${minutes > 0 ? '$minutes min' : ''})'.trim();
      } else {
        return '($minutes min)';
      }
    } catch (_) {
      return '';
    }
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      // First try ISO 8601 directly
      final dt = DateTime.parse(timeStr).toLocal();
      return DateFormat('h:mm a').format(dt).toLowerCase();
    } catch (_) {
      try {
        // Fallback for older model format: "dd-MM-yyyy HH:mm:ss"
        final inputFormat = DateFormat('dd-MM-yyyy HH:mm:ss');
        final dtParsed = inputFormat.parse(timeStr, true); // true = force UTC
        final dtLocal = dtParsed.toLocal();

        return DateFormat('h:mm a').format(dtLocal).toLowerCase();
      } catch (e) {
        return timeStr;
      }
    }
  }
}

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
