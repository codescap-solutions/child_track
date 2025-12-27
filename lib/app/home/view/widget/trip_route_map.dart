import 'package:child_track/app/home/view/trips_view.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/services/location_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:child_track/core/constants/app_colors.dart';

class TripRouteMap extends StatefulWidget {
  const TripRouteMap({super.key});

  @override
  State<TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends State<TripRouteMap> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoading = true;
  BitmapDescriptor? _kidMarkerIcon;
  BitmapDescriptor? _parentMarkerIcon;

  @override
  void initState() {
    super.initState();
    AppLogger.info('🗺️ TripRouteMap: initState called');
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  Future<void> _getCurrentLocation() async {
    AppLogger.info('📍 TripRouteMap: Starting to get current location...');
    try {
      Position? position = await _locationService.getCurrentPosition();
      AppLogger.info('📍 TripRouteMap: getCurrentPosition returned: ${position != null ? "SUCCESS" : "NULL"}');
      
      if (position != null && mounted) {
        AppLogger.info('📍 TripRouteMap: Position received - Lat: ${position.latitude}, Lng: ${position.longitude}');
        setState(() {
          _currentPosition = position;
          _isLoading = false;
          AppLogger.info('📍 TripRouteMap: State updated with position, isLoading: false');
          // Add kid marker for current location
          if (_kidMarkerIcon != null) {
            _markers.add(
              Marker(
                markerId: const MarkerId('kid_location'),
                position: LatLng(position.latitude, position.longitude),
                icon: _kidMarkerIcon!,
                anchor: const Offset(0.5, 1.0),
                infoWindow: const InfoWindow(
                  title: 'Kid Location',
                  snippet: 'Current position',
                ),
              ),
            );
            AppLogger.info('📍 TripRouteMap: Kid marker added');
          } else {
            AppLogger.warning('📍 TripRouteMap: _kidMarkerIcon is null, cannot add kid marker');
          }

          // Add parent/office marker (slightly offset for demo)
          // In real app, this would come from API
          if (_parentMarkerIcon != null) {
            _markers.add(
              Marker(
                markerId: const MarkerId('parent_location'),
                position: LatLng(
                  position.latitude + 0.005,
                  position.longitude + 0.005,
                ),
                icon: _parentMarkerIcon!,
                anchor: const Offset(0.5, 1.0),
                infoWindow: const InfoWindow(
                  title: 'at Office',
                  snippet: '1 h 53 m',
                ),
              ),
            );
            AppLogger.info('📍 TripRouteMap: Parent marker added');
          }
        });

        // Move camera to current location
        if (_mapController != null) {
          AppLogger.info('📍 TripRouteMap: Moving camera to current location');
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              15.0,
            ),
          );
        } else {
          AppLogger.warning('📍 TripRouteMap: Map controller is null, cannot move camera');
        }
      } else {
        AppLogger.warning('📍 TripRouteMap: Position is null or widget not mounted, trying last known position...');
        // If current position fails, try last known position
        Position? lastPosition = await _locationService.getLastKnownPosition();
        AppLogger.info('📍 TripRouteMap: getLastKnownPosition returned: ${lastPosition != null ? "SUCCESS" : "NULL"}');
        
        if (lastPosition != null && mounted) {
          AppLogger.info('📍 TripRouteMap: Last known position - Lat: ${lastPosition.latitude}, Lng: ${lastPosition.longitude}');
          setState(() {
            _currentPosition = lastPosition;
            _isLoading = false;
            if (_kidMarkerIcon != null) {
              _markers.add(
                Marker(
                  markerId: const MarkerId('last_known_location'),
                  position: LatLng(
                    lastPosition.latitude,
                    lastPosition.longitude,
                  ),
                  icon: _kidMarkerIcon!,
                  anchor: const Offset(0.5, 1.0),
                  infoWindow: const InfoWindow(
                    title: 'Last Known Location',
                    snippet: 'Last known position',
                  ),
                ),
              );
            }
          });
          if (_mapController != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(lastPosition.latitude, lastPosition.longitude),
                15.0,
              ),
            );
          }
        } else {
          AppLogger.warning('📍 TripRouteMap: No location available, using default location (Bangalore)');
          // Default location (if no location available)
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ TripRouteMap: Error getting location', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  void _onMapCreated(GoogleMapController controller) {
    AppLogger.info('🗺️ TripRouteMap: Map controller created successfully!');
    _mapController = controller;
    
    // If we already have a position, move camera to it
    if (_currentPosition != null) {
      AppLogger.info('🗺️ TripRouteMap: Moving camera to existing position - Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}');
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    } else {
      AppLogger.warning('🗺️ TripRouteMap: No current position available when map was created');
    }
  }
@override
Widget build(BuildContext context) {
  final initialTarget = _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : const LatLng(12.9716, 77.5946); // Default: Bangalore
  
  AppLogger.info('🗺️ TripRouteMap: Building map widget');
  AppLogger.info('🗺️ TripRouteMap: isLoading = $_isLoading');
  AppLogger.info('🗺️ TripRouteMap: currentPosition = ${_currentPosition != null ? "Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}" : "NULL"}');
  AppLogger.info('🗺️ TripRouteMap: initialTarget = Lat: ${initialTarget.latitude}, Lng: ${initialTarget.longitude}');
  AppLogger.info('🗺️ TripRouteMap: markers count = ${_markers.length}');
  AppLogger.info('🗺️ TripRouteMap: mapType = MapType.normal');
  
  return Stack(
    clipBehavior: Clip.none,
    children: [
      // Map at the bottom
      Positioned.fill(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          margin: const EdgeInsets.all(AppSizes.paddingM),
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: _currentPosition != null ? 15.0 : 12.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: false,
            onCameraMoveStarted: () {
              AppLogger.info('🗺️ TripRouteMap: Camera move started');
            },
            onCameraIdle: () {
              AppLogger.info('🗺️ TripRouteMap: Camera idle');
            },
          ),
        ),
      ),

      // Title on top of the map
      Positioned(
        top: 29,
        left: 30,
        right: 0,

        child: Container(
          width: 100,
          // height: 30,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Text(
            'Trip Route',
            style: AppTextStyles.subtitle1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
        Positioned(
        bottom:30,
        left: 0,
        right: 0,

        child: _buildTripTodayCard(context)
      ),
    ],
  );
}

 // Trip Today Card
  Widget _buildTripTodayCard(BuildContext context) {
    return Container(
      height: 85,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      padding: const EdgeInsets.all(AppSizes.paddingS),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Text(
                '08:43 am - 21:20 pm (12hrs)',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              // const SizedBox(height: AppSizes.spacingXS),
              Text(
                'Kamakshi Palaya - Cubbon Park',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingXS,
                      vertical: AppSizes.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Text('4 Events', style: AppTextStyles.caption),
                  ),
                  const SizedBox(width: AppSizes.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingS,
                      vertical: AppSizes.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Text(
                      'today',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                 
                ],
              ),
            ],
          ),
           const Spacer(),
                  CommonButton(
                    padding: EdgeInsets.zero,
                    width: 80,
                    text: 'View all',
                    fontSize: 12,
                    textColor: AppColors.surfaceColor,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TripsView()),
                    ),
                    height: 30,
                  ),
        ],
      ),
    );
  }

}

