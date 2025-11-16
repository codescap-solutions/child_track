import 'package:child_track/app/map/view_model/map_bloc.dart';
import 'package:child_track/core/di/injector.dart';
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
  });
  final double width, height;
  final bool interactive, isPolyLines;
  final LatLng? currentPosition;
  final List<Marker>? markers;
  final List<Polyline>? polylines;

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  Map<PolylineId, Polyline> polylines = {};
  @override
  void initState() {
    super.initState();
    getPolylines();
  }

  Future<void> getPolylines() async {
    if (mounted) {
      polylines = await injector<MapBloc>().getPolyLines(widget.markers ?? []);
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
              return IgnorePointer(
                ignoring: !widget.interactive,
                child: GoogleMap(
                  mapType: MapType.normal,
                  mapToolbarEnabled: true,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  scrollGesturesEnabled: widget.interactive,
                  zoomGesturesEnabled: widget.interactive,
                  tiltGesturesEnabled: widget.interactive,
                  rotateGesturesEnabled: widget.interactive,
                  onMapCreated: (controller) {
                    injector<MapBloc>().add(MapCreated(controller));
                  },
                  polylines: Set<Polyline>.of(polylines.values),
                  initialCameraPosition: CameraPosition(
                    target: widget.currentPosition ?? state.currentPosition,
                    zoom: 11,
                  ),
                  markers: (widget.markers ?? state.markers).toSet(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
