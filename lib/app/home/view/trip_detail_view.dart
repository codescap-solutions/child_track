import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:intl/intl.dart';
import 'package:child_track/app/map/view/map_view.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

/// Trip Detail View - Shows detailed trip with map and timeline
class TripDetailView extends StatefulWidget {
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
  State<TripDetailView> createState() => _TripDetailViewState();
}

class _TripDetailViewState extends State<TripDetailView> {
  GoogleMapController? _mapController;

  String _getRideModeText(String rideMode) {
    switch (rideMode.toLowerCase()) {
      case 'walking':
        return 'Walking';
      case 'cycling':
        return 'Cycling';
      case 'stationary':
        return 'Stationary';
      case 'vehicle':
        return 'In Vehicle';
      default:
        return 'Ride';
    }
  }

  String _formatDateTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      // Input format from API seems to be "dd-MM-yyyy HH:mm:ss"
      // or standard ISO. Try generic parse first, then specific.
      DateTime dt;
      try {
        dt = DateTime.parse(timeStr);
      } catch (_) {
        final inputFormat = DateFormat('dd-MM-yyyy HH:mm:ss');
        dt = inputFormat.parse(timeStr);
      }

      // Desired format: "13-01-2026 07:00pm"
      final outputFormat = DateFormat('dd-MM-yyyy hh:mma');
      return outputFormat.format(dt).toLowerCase();
    } catch (e) {
      return timeStr;
    }
  }

  void _fitBounds() {
    if (_mapController == null || widget.polylines.isEmpty) return;

    double minLat = widget.markers.first.position.latitude;
    double maxLat = widget.markers.first.position.latitude;
    double minLng = widget.markers.first.position.longitude;
    double maxLng = widget.markers.first.position.longitude;

    // Include all markers
    for (var marker in widget.markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    // Include polyline points
    for (var polyline in widget.polylines) {
      for (var point in polyline.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Map Section (Full screen)
          Positioned.fill(
            child: _buildMapSection(context, widget.markers, widget.polylines),
          ),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2, // Collapsed state showing map
            maxChildSize: 0.50, // Expanded state
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle

                    // Trip Timeline (Scrollable content)
                    Expanded(
                      child: ListView(
                        controller: scrollController, // Link to draggable sheet
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingL,
                        ),
                        children: [
                          Center(
                            child: Container(
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
                          ),
                          // Trip Time Range
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Text(
                              '${_formatDateTime(widget.trip.startTime)} to ${_formatDateTime(widget.trip.endTime)}',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headline6.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSizes.spacingL),
                          _buildTimelineItem(
                            icon: Icons.home,
                            title: widget.trip.startPlace,
                            time: widget.trip.startTime,
                            color: AppColors.primaryColor,
                            position: widget.markers.first.position,
                          ),
                          _buildTimelineItem(
                            icon: Icons.school,
                            title: widget.trip.endPlace,
                            time: widget.trip.endTime,
                            color: AppColors.success,
                            position: widget.markers.last.position,
                          ),
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
            onMapCreated: (controller) {
              _mapController = controller;
              // Initial fit bounds
              _fitBounds();
            },
            interactive: true,
            width: double.infinity,
            maxZoom: 15,
            height: double.infinity,
            currentPosition: markers.first.position,
            markers: markers,
            // Native gestures preferred for full screen map
            useEagerGestures: true,
            polylines: polylines,
            isPolyLines: true,
          ),
        ),

        Positioned(
          top: 50,
          left: 20,
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
        ),

        // App Bar Overlay
        Positioned(
          top: 50,
          left: 120,
          right: 120,
          child: Container(
            alignment: Alignment.center,
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
        ),
      ],
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
    LatLng? position,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingL),
      child: IntrinsicHeight(
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
                  Expanded(
                    child: Container(width: 2, color: AppColors.borderColor),
                  ),
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
                            if (position != null && title == "Unknown Location")
                              _DetailPlaceRenderer(
                                initialText: title,
                                position: position,
                                isDark: true,
                              )
                            else
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
                        color: AppColors
                            .surfaceColor, // Changed to Surface to stand out against bg? Or keep container.
                        // Actually standard is often a light gray block.
                        // color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getRideModeText(widget.trip.rideMode),
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.trip.distanceKm}km (${widget.trip.durationMinutes}min)',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
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
                              'max speed - ${widget.trip.maxSpeedKmph} km/h',
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
      ),
    );
  }
}

class _DetailPlaceRenderer extends StatefulWidget {
  final String initialText;
  final LatLng position;
  final bool isDark;

  const _DetailPlaceRenderer({
    required this.initialText,
    required this.position,
    this.isDark = false,
  });

  @override
  State<_DetailPlaceRenderer> createState() => _DetailPlaceRendererState();
}

class _DetailPlaceRendererState extends State<_DetailPlaceRenderer> {
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
    return widget.initialText == "Unknown Location" ||
        widget.initialText.startsWith("Start") ||
        widget.initialText.startsWith("End");
  }

  Future<void> _resolveAddress() async {
    if (!_shouldResolveAddress()) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        widget.position.latitude,
        widget.position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        setState(() {
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
    if (widget.isDark) {
      // Timeline style
      final displayText = _resolvedAddress ?? widget.initialText;
      return _isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textPrimary,
              ),
            )
          : Text(
              displayText,
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );
    }

    // Map Label style
    Color badgeColor = AppColors.surfaceColor;
    Color textColor = AppColors.textPrimary;
    String labelText = widget.initialText;

    if (widget.initialText == 'Start') {
      badgeColor = Colors.green;
      textColor = Colors.white;
      labelText = 'START';
    } else if (widget.initialText == 'End') {
      badgeColor = Colors.red; // Or a pinkish red if preferred
      textColor = Colors.white;
      labelText = 'FINISH';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingS,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        labelText,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
