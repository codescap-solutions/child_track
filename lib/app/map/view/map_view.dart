import 'package:child_track/app/map/view_model/map_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: BlocProvider.value(
        value: injector<MapBloc>(),
        child: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            if (state is MapLoaded) {
              return IgnorePointer(
                ignoring: !interactive,
                child: GoogleMap(
                  mapType: MapType.satellite,
                  mapToolbarEnabled: true,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  scrollGesturesEnabled: interactive,
                  zoomGesturesEnabled: interactive,
                  tiltGesturesEnabled: interactive,
                  rotateGesturesEnabled: interactive,
                  onMapCreated: (controller) {
                    injector<MapBloc>().add(MapCreated(controller));
                  },
                  polylines: isPolyLines == true
                      ? Set<Polyline>.of(polylines ?? state.polylines.values)
                      : {},
                  initialCameraPosition: CameraPosition(
                    target: currentPosition ?? state.currentPosition,
                    zoom: 11,
                  ),
                  markers: (markers ?? state.markers).toSet(),
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
