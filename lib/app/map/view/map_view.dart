import 'package:child_track/app/map/view_model/map_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewWidget extends StatelessWidget {
  const MapViewWidget({super.key, required this.width, required this.height});
  final double width, height;

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
              return GoogleMap(
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  injector<MapBloc>().add(MapCreated(controller));
                },
                polylines: Set<Polyline>.of(state.polylines.values),
                initialCameraPosition:  CameraPosition(
                  target: state.currentPosition,
                  zoom: 10,
                ),
                markers: state.markers.toSet(),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onTap: (latLng) {
                  injector<MapBloc>().add(MarkerAdded(latLng));
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
