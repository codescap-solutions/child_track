import 'package:child_track/app/home/view/trips_view.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/services/location_service.dart';
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
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  BitmapDescriptor? _startMarkerIcon;
  BitmapDescriptor? _endMarkerIcon; 
  BitmapDescriptor? _intermediateMarkerIcon;
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoading = true;
  BitmapDescriptor? _kidMarkerIcon;
  BitmapDescriptor? _parentMarkerIcon;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  Future<void> _getCurrentLocation() async {
    try {
      Position? position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
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
          }
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15.0,
          ),
        );
      } else {
        // If current position fails, try last known position
        Position? lastPosition = await _locationService.getLastKnownPosition();
        if (lastPosition != null && mounted) {
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
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(lastPosition.latitude, lastPosition.longitude),
              15.0,
            ),
          );
        } else {
          // Default location (if no location available)
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // If we already have a position, move camera to it
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    }
  }
@override
Widget build(BuildContext context) {
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
              target: const LatLng(12.9716, 77.5946), // Default: Bangalore
              zoom: _currentPosition != null ? 15.0 : 12.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.satellite,
            zoomControlsEnabled: false,
            compassEnabled: false,
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

