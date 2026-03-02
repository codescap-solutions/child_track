import 'package:child_track/app/map/view_model/map_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:child_track/core/widgets/map_shimmer.dart';

class MapViewWidget extends StatefulWidget {
  const MapViewWidget({
    super.key,
    required this.width,
    required this.height,
    this.interactive = true,
    this.currentPosition,
    this.markers,
    this.polylines,
    this.isPolyLines = false,
    this.onMapCreated,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = true,
    this.minZoom = 1.0,
    this.maxZoom = 20.0,
    this.useEagerGestures = false,
    this.onCameraMove,
    this.onMapTap,
  });
  final double width, height;
  final bool interactive, isPolyLines;
  final bool useEagerGestures;
  final void Function(CameraPosition)? onCameraMove;
  final LatLng? currentPosition;
  final List<Marker>? markers;
  final List<Polyline>? polylines;
  final void Function(GoogleMapController)? onMapCreated;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final double minZoom;
  final double maxZoom;
  final void Function(LatLng)? onMapTap;
  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  Map<PolylineId, Polyline> polylines = {};
  MapType currentMapType = MapType.normal;
  late CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    getPolylines();
    _initialCameraPosition = CameraPosition(
      target:
          widget.currentPosition ??
          const LatLng(11.258753, 75.780410), // fallback
      zoom: 15,
    );
  }

  void _showMapTypeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Map Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildMapTypeOption(context, 'Normal', MapType.normal, Icons.map),
            _buildMapTypeOption(
              context,
              'Satellite',
              MapType.satellite,
              Icons.satellite,
            ),
            _buildMapTypeOption(
              context,
              'Hybrid',
              MapType.hybrid,
              Icons.layers,
            ),
            _buildMapTypeOption(
              context,
              'Terrain',
              MapType.terrain,
              Icons.terrain,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOption(
    BuildContext context,
    String label,
    MapType mapType,
    IconData icon,
  ) {
    final isSelected = currentMapType == mapType;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[600]),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black87,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        setState(() {
          currentMapType = mapType;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  void didUpdateWidget(MapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update polylines when widget markers change
    if (widget.markers != oldWidget.markers) {
      if (mounted) {
        getPolylines();
      }
    }
  }

  Future<void> getPolylines() async {
    if (!mounted) return;

    // Start with provided polylines if any
    final Map<PolylineId, Polyline> initialPolylines = {};
    if (widget.polylines != null && widget.polylines!.isNotEmpty) {
      for (var polyline in widget.polylines!) {
        initialPolylines[polyline.polylineId] = polyline;
      }
      // If explicit polylines are provided, we likley don't want to fetch automatic ones from markers
      // unless we want to merge them. For detail views, we usually want EXACTLY what we passed.
    } else {
      // Attempt to get polylines from markers via Bloc ONLY if no polylines provided
      try {
        final blocPolylines = await injector<MapBloc>().getPolyLines(
          widget.markers ?? [],
        );
        initialPolylines.addAll(blocPolylines);
      } catch (e) {
        // Ignore error if bloc fails
      }
    }

    polylines = initialPolylines;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: BlocProvider.value(
        value: injector<MapBloc>(),
        child: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            if (state is MapLoaded) {
              return Stack(
                children: [
                  IgnorePointer(
                    ignoring: !widget.interactive,
                    child: RepaintBoundary(
                      child: GoogleMap(
                        onTap: (LatLng position) {
                          widget.onMapTap?.call(position);
                        },
                        mapType: currentMapType,
                        mapToolbarEnabled: true,
                        zoomControlsEnabled: true,
                        compassEnabled: false,
                        gestureRecognizers:
                            widget.interactive && widget.useEagerGestures
                            ? <Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              }
                            : <Factory<OneSequenceGestureRecognizer>>{},
                        scrollGesturesEnabled: widget.interactive,
                        minMaxZoomPreference: MinMaxZoomPreference(
                          widget.minZoom,
                          widget.maxZoom,
                        ),

                        zoomGesturesEnabled: widget.interactive,
                        tiltGesturesEnabled: widget.interactive,
                        rotateGesturesEnabled: widget.interactive,

                        onMapCreated: (controller) {
                          injector<MapBloc>().add(MapCreated(controller));
                          // Call custom onMapCreated callback if provided
                          widget.onMapCreated?.call(controller);
                        },
                        polylines: Set<Polyline>.of(polylines.values),
                        initialCameraPosition: _initialCameraPosition,
                        markers: () {
                          final markersToUse =
                              widget.markers != null &&
                                  widget.markers!.isNotEmpty
                              ? widget.markers!.toSet()
                              : state.markers.toSet();

                          return markersToUse;
                        }(),
                        onCameraMove: widget.onCameraMove,
                        onCameraMoveStarted: () {},
                        onCameraIdle: () {},
                        myLocationEnabled: widget.myLocationEnabled,
                        myLocationButtonEnabled: widget.myLocationButtonEnabled,
                      ),
                    ),
                  ),
                  // Floating layers button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    right: 60,
                    child: InkWell(
                      onTap: () => _showMapTypeOptions(context),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(
                          alpha: 0.6,
                        ), // Standard map button style
                        child: const Icon(Icons.layers, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }
            return MapShimmer(width: widget.width, height: widget.height);
          },
        ),
      ),
    );
  }
}
