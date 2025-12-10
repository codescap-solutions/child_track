import 'package:child_track/app/map/view_model/map_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    this.minZoom = 5.0,
    this.maxZoom = 15.0,
  });
  final double width, height;
  final bool interactive, isPolyLines;
  final LatLng? currentPosition;
  final List<Marker>? markers;
  final List<Polyline>? polylines;
  final void Function(GoogleMapController)? onMapCreated;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final double minZoom;
  final double maxZoom;
  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  Map<PolylineId, Polyline> polylines = {};
  MapType currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    getPolylines();
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
    polylines = await injector<MapBloc>().getPolyLines(widget.markers ?? []);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: BlocProvider(
        create: (context) => injector<MapBloc>(),
        child: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            if (state is MapLoaded) {
              return Stack(
                children: [
                  IgnorePointer(
                    ignoring: !widget.interactive,
                    child: GoogleMap(
                      mapType: currentMapType,
                      mapToolbarEnabled: true,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      gestureRecognizers: widget.interactive
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
                      initialCameraPosition: CameraPosition(
                        target: widget.currentPosition ?? state.currentPosition,
                        zoom: widget.currentPosition != null ? 15.0 : 11.0,
                      ),
                      markers: () {
                        final markersToUse =
                            widget.markers != null && widget.markers!.isNotEmpty
                            ? widget.markers!.toSet()
                            : state.markers.toSet();

                        return markersToUse;
                      }(),
                      onCameraMoveStarted: () {},
                      onCameraIdle: () {},
                      myLocationEnabled: widget.myLocationEnabled,
                      myLocationButtonEnabled: widget.myLocationButtonEnabled,
                    ),
                  ),
                  // Floating layers button
                  Positioned(
                    right: 16,
                    bottom: 160,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        onTap: () => _showMapTypeOptions(context),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.layers,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
