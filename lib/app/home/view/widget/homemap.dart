// Map Section Widget with Google Maps
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/app/home/view_model/homepage_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSection extends StatefulWidget {
  const MapSection({super.key});

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  late final HomepageBloc _homepageBloc;

  @override
  void initState() {
    super.initState();
    AppLogger.info('🗺️ MapSection: initState called');
    _homepageBloc = injector<HomepageBloc>();
    // Initialize map when widget is created
    AppLogger.info('🗺️ MapSection: Initializing map...');
    _homepageBloc.add(InitializeMap());
  }

  void _onMapCreated(GoogleMapController controller) {
    AppLogger.info('🗺️ MapSection: Map controller created successfully!');
    _homepageBloc.add(MapCreated(controller));
  }

  void _moveToCurrentLocation() {
    _homepageBloc.add(MoveToCurrentLocation());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homepageBloc,
      child: BlocBuilder<HomepageBloc, HomepageState>(
        builder: (context, state) {
          return Container(
            color: AppColors.beach,
            child: Stack(
              children: [
                // Google Map
                Positioned.fill(child: _buildMapContent(state)),

                // Map controls at bottom right
                Positioned(
                  bottom: AppSizes.paddingM,
                  right: AppSizes.paddingM,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.layers,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                      GestureDetector(
                        onTap: _moveToCurrentLocation,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapContent(HomepageState state) {
    AppLogger.info('🗺️ MapSection: Building map content, state: ${state.runtimeType}');
    
    if (state is MapLoading || state is MapInitial) {
      AppLogger.info('🗺️ MapSection: Map is loading or initializing...');
      return Container(
        color: AppColors.beach,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state is MapError) {
      AppLogger.error('🗺️ MapSection: Map error - ${state.message}');
      return Container(
        color: AppColors.beach,
        child: Center(
          child: Text(
            'Error: ${state.message}',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    if (state is MapLoaded) {
      final initialTarget = state.currentPosition != null
          ? LatLng(
              state.currentPosition!.latitude,
              state.currentPosition!.longitude,
            )
          : const LatLng(12.9716, 77.5946); // Default: Bangalore
      
      AppLogger.info('🗺️ MapSection: Map loaded successfully!');
      AppLogger.info('🗺️ MapSection: Current position: ${state.currentPosition != null ? "Lat: ${state.currentPosition!.latitude}, Lng: ${state.currentPosition!.longitude}" : "NULL"}');
      AppLogger.info('🗺️ MapSection: Initial target: Lat: ${initialTarget.latitude}, Lng: ${initialTarget.longitude}');
      AppLogger.info('🗺️ MapSection: Markers count: ${state.markers.length}');
      AppLogger.info('🗺️ MapSection: MapType: MapType.normal');
      
      return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: initialTarget,
          zoom: state.currentPosition != null ? 15.0 : 12.0,
        ),
        markers: state.markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        mapType: MapType.normal,
        zoomControlsEnabled: false,
        compassEnabled: false,
        onCameraMoveStarted: () {
          AppLogger.info('🗺️ MapSection: Camera move started');
        },
        onCameraIdle: () {
          AppLogger.info('🗺️ MapSection: Camera idle');
        },
      );
    }

    // Fallback for other states
    AppLogger.warning('🗺️ MapSection: Unknown state, showing fallback');
    return Container(
      color: AppColors.beach,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
