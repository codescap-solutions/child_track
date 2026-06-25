import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/model/trip_detail_model.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_bloc.dart';
import 'package:child_track/app/map/view/map_view.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/services/tracking/kalman_filter_service.dart';
import 'package:child_track/core/services/tracking/timeline_engine.dart';
import 'package:child_track/core/services/tracking/trip_playback_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

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
  late HomepageBloc _homepageBloc;
  late KalmanFilterService _kalmanService;
  TripPlaybackController? _playbackController;

  List<LatLng> _smoothedPoints = [];
  List<TimelineEvent> _timelineEvents = [];

  // Playback values to rebuild UI
  LatLng? _currentPlaybackPosition;
  double _currentPlaybackSpeed = 1.0;
  bool _isPlaying = false;
  double _playbackProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _homepageBloc = injector<HomepageBloc>();
    _kalmanService = KalmanFilterService();

    // 1. Smooth route points using Kalman Filter
    if (widget.trip.polylinePoints.isNotEmpty) {
      _smoothedPoints = widget.trip.polylinePoints.map((p) {
        final (lat, lng) = _kalmanService.smooth(p.latitude, p.longitude);
        return LatLng(lat, lng);
      }).toList();
    } else {
      _smoothedPoints = [];
    }

    // 2. Generate local timeline events as a fallback/offline view
    _generateLocalTimeline();

    // 3. Initialize Playback Controller if route exists
    if (_smoothedPoints.isNotEmpty) {
      _playbackController = TripPlaybackController(route: _smoothedPoints);
      _playbackController!.positionNotifier.addListener(_onPlaybackPositionChanged);
      _playbackController!.progressNotifier.addListener(_onPlaybackProgressChanged);
      _playbackController!.isPlayingNotifier.addListener(_onPlaybackPlayingChanged);
      _playbackController!.speedNotifier.addListener(_onPlaybackSpeedChanged);
      _currentPlaybackPosition = _smoothedPoints.first;
    }
  }

  void _onPlaybackPositionChanged() {
    if (mounted) {
      setState(() {
        _currentPlaybackPosition = _playbackController?.currentPosition;
      });
      if (_currentPlaybackPosition != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentPlaybackPosition!),
        );
      }
    }
  }

  void _onPlaybackProgressChanged() {
    if (mounted) {
      setState(() {
        _playbackProgress = _playbackController?.progress ?? 0.0;
      });
    }
  }

  void _onPlaybackPlayingChanged() {
    if (mounted) {
      setState(() {
        _isPlaying = _playbackController?.isPlaying ?? false;
      });
    }
  }

  void _onPlaybackSpeedChanged() {
    if (mounted) {
      setState(() {
        _currentPlaybackSpeed = _playbackController?.speed ?? 1.0;
      });
    }
  }

  @override
  void dispose() {
    _playbackController?.positionNotifier.removeListener(_onPlaybackPositionChanged);
    _playbackController?.progressNotifier.removeListener(_onPlaybackProgressChanged);
    _playbackController?.isPlayingNotifier.removeListener(_onPlaybackPlayingChanged);
    _playbackController?.speedNotifier.removeListener(_onPlaybackSpeedChanged);
    _playbackController?.dispose();
    super.dispose();
  }

  void _generateLocalTimeline() {
    try {
      final List<Map<String, dynamic>> rawPoints = [];
      final points = widget.trip.polylinePoints;
      final startTime = DateTime.tryParse(widget.trip.startTime) ?? DateTime.now();
      final endTime = DateTime.tryParse(widget.trip.endTime) ?? DateTime.now();
      final totalSeconds = endTime.difference(startTime).inSeconds;
      final stepSeconds = points.length > 1 ? totalSeconds ~/ (points.length - 1) : 0;

      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        final ts = startTime.add(Duration(seconds: i * stepSeconds)).toIso8601String();
        double speed = 0.0;
        if (i > 0) {
          final prev = points[i - 1];
          final dist = Geolocator.distanceBetween(
            prev.latitude, prev.longitude, p.latitude, p.longitude,
          );
          if (stepSeconds > 0) {
            speed = dist / stepSeconds; // m/s
          }
        }
        rawPoints.add({
          'lat': p.latitude,
          'lng': p.longitude,
          'speed': speed,
          'ts': ts,
        });
      }

      _timelineEvents = TimelineEngine.generate(
        points: rawPoints,
        initialRideMode: widget.trip.rideMode,
      );
    } catch (e) {
      // Fallback
      _timelineEvents = [
        TimelineEvent(
          type: TimelineEventType.tripStart,
          time: DateTime.tryParse(widget.trip.startTime) ?? DateTime.now(),
          label: 'Trip Started from ${widget.trip.startPlace}',
          lat: widget.trip.startLocation.latitude,
          lng: widget.trip.startLocation.longitude,
        ),
        TimelineEvent(
          type: TimelineEventType.arrived,
          time: DateTime.tryParse(widget.trip.endTime) ?? DateTime.now(),
          label: 'Arrived at ${widget.trip.endPlace}',
          lat: widget.trip.endLocation.latitude,
          lng: widget.trip.endLocation.longitude,
        ),
      ];
    }
  }

  int get _currentPlaybackIndex {
    if (_playbackController == null || _smoothedPoints.isEmpty) return 0;
    final pos = _playbackController!.currentPosition;
    final idx = _smoothedPoints.indexOf(pos);
    return idx >= 0 ? idx : 0;
  }

  double get _currentSpeedKmh {
    if (_smoothedPoints.isEmpty) return 0.0;
    final idx = _currentPlaybackIndex;
    if (idx == 0) return 0.0;
    final prev = _smoothedPoints[idx - 1];
    final curr = _smoothedPoints[idx];
    final dist = Geolocator.distanceBetween(
      prev.latitude, prev.longitude, curr.latitude, curr.longitude,
    );
    // Estimate speed based on a default time interval of 5 seconds
    final speedMps = dist / 5.0;
    final speedKmh = speedMps * 3.6;
    return speedKmh > 120 ? 0.0 : double.parse(speedKmh.toStringAsFixed(1));
  }

  String get _currentTimestamp {
    if (_smoothedPoints.isEmpty) return '';
    final idx = _currentPlaybackIndex;
    final start = DateTime.tryParse(widget.trip.startTime) ?? DateTime.now();
    final end = DateTime.tryParse(widget.trip.endTime) ?? DateTime.now();
    final totalSec = end.difference(start).inSeconds;
    final stepSec = _smoothedPoints.length > 1 ? totalSec ~/ (_smoothedPoints.length - 1) : 0;
    final currentTs = start.add(Duration(seconds: idx * stepSec));
    return DateFormat('h:mm:ss a').format(currentTs).toLowerCase();
  }

  String _formatDateTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      DateTime dt;
      try {
        dt = DateTime.parse(timeStr).toLocal();
      } catch (_) {
        final inputFormat = DateFormat('dd-MM-yyyy HH:mm:ss');
        dt = inputFormat.parse(timeStr, true).toLocal();
      }
      final outputFormat = DateFormat('dd-MM-yyyy hh:mma');
      return outputFormat.format(dt).toLowerCase();
    } catch (e) {
      return timeStr;
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
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
    return BlocProvider.value(
      value: _homepageBloc,
      child: BlocBuilder<HomepageBloc, HomepageState>(
        builder: (context, state) {
          List<TimelineEvent> displayEvents = _timelineEvents;
          double maxSpeed = widget.trip.maxSpeedKmph;
          double totalDistance = widget.trip.distanceKm;
          int durationMinutes = widget.trip.durationMinutes;

          if (state is HomepageSuccess &&
              state.selectedTripDetail != null &&
              state.selectedTripDetail!.tripId == widget.trip.segmentId) {
            final detail = state.selectedTripDetail!;
            maxSpeed = detail.maxSpeedKmph;
            totalDistance = detail.totalDistanceKm;
            try {
              durationMinutes = DateTime.parse(detail.endTime)
                  .difference(DateTime.parse(detail.startTime))
                  .inMinutes;
            } catch (_) {}

            displayEvents = detail.events.map((e) {
              TimelineEventType type = TimelineEventType.tripStart;
              switch (e.eventType.toLowerCase()) {
                case 'trip_start':
                  type = TimelineEventType.tripStart;
                  break;
                case 'walking':
                case 'started_walking':
                  type = TimelineEventType.startedWalking;
                  break;
                case 'running':
                case 'started_running':
                  type = TimelineEventType.startedRunning;
                  break;
                case 'cycling':
                case 'started_cycling':
                  type = TimelineEventType.startedCycling;
                  break;
                case 'vehicle':
                case 'started_vehicle':
                  type = TimelineEventType.startedVehicle;
                  break;
                case 'stopped':
                  type = TimelineEventType.stopped;
                  break;
                case 'arrived':
                  type = TimelineEventType.arrived;
                  break;
                case 'left_place':
                  type = TimelineEventType.leftPlace;
                  break;
                case 'geofence_entered':
                  type = TimelineEventType.geofenceEntered;
                  break;
                case 'geofence_exited':
                  type = TimelineEventType.geofenceExited;
                  break;
              }

              return TimelineEvent(
                type: type,
                time: DateTime.tryParse(e.time)?.toLocal() ?? DateTime.now(),
                label: e.title,
                stopDuration: e.durationMinutes != null ? Duration(minutes: e.durationMinutes!) : null,
                speedKmh: e.maxSpeedKmph,
                distanceKm: e.distanceKm,
              );
            }).toList();
          }

          final markers = <Marker>{};
          if (widget.markers.isNotEmpty) {
            markers.addAll(widget.markers);
          }

          if (_currentPlaybackPosition != null) {
            markers.add(
              Marker(
                markerId: const MarkerId('playback_marker'),
                position: _currentPlaybackPosition!,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: InfoWindow(
                  title: 'Current Playback',
                  snippet: '${_currentSpeedKmh} km/h • ${_currentTimestamp}',
                ),
              ),
            );
          }

          final polylines = <Polyline>{};
          if (_smoothedPoints.isNotEmpty) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('smoothed_route'),
                points: _smoothedPoints,
                color: AppColors.tripPolyline,
                width: 4,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                patterns: widget.trip.rideMode.toLowerCase() == 'walking'
                    ? [PatternItem.dot, PatternItem.gap(10)]
                    : [],
              ),
            );
          } else if (widget.polylines.isNotEmpty) {
            polylines.addAll(widget.polylines);
          }

          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Stack(
              children: [
                // Map Section (Full screen)
                Positioned.fill(
                  child: _buildMapSection(context, markers.toList(), polylines.toList()),
                ),

                // Playback info overlay (top-mid)
                if (_isPlaying || _playbackProgress > 0.0)
                  Positioned(
                    top: 110,
                    left: 20,
                    right: 20,
                    child: Card(
                      color: AppColors.surfaceColor.withOpacity(0.95),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.speed,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_currentSpeedKmh} km/h',
                                    style: AppTextStyles.subtitle1.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _currentTimestamp,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _playbackController?.pause();
                                _playbackController?.seekTo(0.0);
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                // Draggable Bottom Sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.25,
                  maxChildSize: 0.75,
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

                          // Playback Controls Panel (Always visible at the top of bottom sheet)
                          if (_playbackController != null)
                            _buildPlaybackControlPanel(),

                          const Divider(height: 1),

                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingL,
                                vertical: AppSizes.paddingM,
                              ),
                              children: [
                                _buildTripHeaderStats(totalDistance, durationMinutes, maxSpeed),
                                const SizedBox(height: AppSizes.spacingL),
                                const Divider(),
                                const SizedBox(height: AppSizes.spacingM),
                                Text(
                                  'Activity Timeline',
                                  style: AppTextStyles.subtitle1.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.spacingM),
                                if (state is HomepageSuccess && state.isLoadingTripDetail)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else
                                  ...displayEvents.map((event) => _buildEnhancedTimelineItem(event)),
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
        },
      ),
    );
  }

  Widget _buildPlaybackControlPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                iconSize: 32,
                color: AppColors.primaryColor,
                icon: Icon(
                  _playbackController!.isAtEnd
                      ? Icons.replay
                      : (_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                ),
                onPressed: () {
                  if (_playbackController!.isAtEnd) {
                    _playbackController!.replay();
                  } else if (_isPlaying) {
                    _playbackController!.pause();
                  } else {
                    _playbackController!.play();
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _playbackProgress,
                    onChanged: (val) {
                      _playbackController!.seekTo(val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<double>(
                value: _currentPlaybackSpeed,
                underline: const SizedBox(),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                items: TripPlaybackController.supportedSpeeds.map((s) {
                  return DropdownMenuItem<double>(
                    value: s,
                    child: Text('${s}x'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _playbackController!.setSpeed(val);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripHeaderStats(double distanceKm, int durationMinutes, double maxSpeedKmph) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          icon: Icons.directions_run,
          value: '${distanceKm.toStringAsFixed(2)} km',
          label: 'Distance',
        ),
        _buildStatItem(
          icon: Icons.timer,
          value: '${durationMinutes} min',
          label: 'Duration',
        ),
        _buildStatItem(
          icon: Icons.speed,
          value: '${maxSpeedKmph.toStringAsFixed(1)} km/h',
          label: 'Max Speed',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTimelineItem(TimelineEvent event) {
    Color color = AppColors.primaryColor;
    IconData icon = Icons.directions_walk;

    switch (event.type) {
      case TimelineEventType.tripStart:
        color = Colors.blue;
        icon = Icons.play_arrow;
        break;
      case TimelineEventType.startedWalking:
        color = Colors.green;
        icon = Icons.directions_walk;
        break;
      case TimelineEventType.startedRunning:
        color = Colors.teal;
        icon = Icons.directions_run;
        break;
      case TimelineEventType.startedCycling:
        color = Colors.orange;
        icon = Icons.directions_bike;
        break;
      case TimelineEventType.startedVehicle:
        color = Colors.purple;
        icon = Icons.directions_car;
        break;
      case TimelineEventType.stopped:
        color = Colors.grey;
        icon = Icons.pause;
        break;
      case TimelineEventType.arrived:
        color = Colors.red;
        icon = Icons.place;
        break;
      case TimelineEventType.leftPlace:
        color = Colors.amber;
        icon = Icons.exit_to_app;
        break;
      case TimelineEventType.geofenceEntered:
        color = Colors.indigo;
        icon = Icons.notifications_active;
        break;
      case TimelineEventType.geofenceExited:
        color = Colors.blueGrey;
        icon = Icons.notifications_none;
        break;
    }

    final timeStr = DateFormat('h:mm a').format(event.time).toLowerCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingL),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.label,
                          style: AppTextStyles.subtitle2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (event.stopDuration != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Duration: ${event.stopDuration!.inMinutes} min',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (event.speedKmh != null && event.speedKmh! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Max speed: ${event.speedKmh!.toStringAsFixed(1)} km/h',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (event.distanceKm != null && event.distanceKm! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Distance: ${event.distanceKm!.toStringAsFixed(2)} km',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.spacingS),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(
    BuildContext context,
    List<Marker> markers,
    List<Polyline> polylines,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: MapViewWidget(
            onMapCreated: (controller) {
              _mapController = controller;
              _fitBounds(_smoothedPoints.isNotEmpty ? _smoothedPoints : widget.trip.polylinePoints);
            },
            interactive: true,
            width: double.infinity,
            maxZoom: 20,
            height: double.infinity,
            currentPosition: _smoothedPoints.isNotEmpty
                ? _smoothedPoints.first
                : (widget.markers.isNotEmpty ? widget.markers.first.position : const LatLng(0, 0)),
            markers: markers,
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
              color: AppColors.surfaceColor.withOpacity(0.9),
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
}
