import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'trip_detail_view.dart';

/// Trips List View - Shows all trips with mini-map cards
class TripsView extends StatelessWidget {
  const TripsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title:  Text('Trips',style: AppTextStyles.headline5.copyWith(
          fontWeight: FontWeight.w600,
        ),),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        itemCount: 3, // Sample trip count
        itemBuilder: (context, index) {
          return _TripCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TripDetailView()),
            ),
          );
        },
      ),
    );
  }
}

/// Individual Trip Card Widget
class _TripCard extends StatefulWidget {
  final VoidCallback onTap;

  const _TripCard({required this.onTap});

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  GoogleMapController? _mapController;
  
  // Static route coordinates: Kamakshi Palaya to Cubbon Park, Bangalore
  static const LatLng _startLocation = LatLng(12.9716, 77.5946); // Kamakshi Palaya area
  static const LatLng _endLocation = LatLng(12.9764, 77.5928); // Cubbon Park area
  
  // Static route points for polyline
  final List<LatLng> _routePoints = const [
    LatLng(12.9716, 77.5946), // Start: Kamakshi Palaya
    LatLng(12.9725, 77.5935),
    LatLng(12.9735, 77.5930),
    LatLng(12.9745, 77.5925),
    LatLng(12.9755, 77.5925),
    LatLng(12.9764, 77.5928), // End: Cubbon Park
  ];
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  void _initializeMap() {
    // Create markers
    _markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: _startLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Start',
          snippet: 'Kamakshi Palaya',
        ),
      ),
    );
    
    _markers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: _endLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: 'End',
          snippet: 'Cubbon Park',
        ),
      ),
    );
    
    // Create polyline for route
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: Colors.purple,
        width: 4,
        patterns: [],
      ),
    );
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Fit bounds to show entire route
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        _boundsFromLatLngList(_routePoints),
        50.0, // padding
      ),
    );
  }
  
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;
    for (var latLng in list) {
      minLat ??= latLng.latitude;
      maxLat ??= latLng.latitude;
      minLng ??= latLng.longitude;
      maxLng ??= latLng.longitude;
      
      if (latLng.latitude < minLat) minLat = latLng.latitude;
      if (latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (latLng.longitude < minLng) minLng = latLng.longitude;
      if (latLng.longitude > maxLng) maxLng = latLng.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusL)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map Section (Top part of card)
          _buildMapSection(),

          // Trip Details Section (Bottom part of card)
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time and Duration Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '08:43 am - 21:20 pm (12hrs)',
                            style: AppTextStyles.subtitle2.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppSizes.spacingS),
                           Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingS),
                    Text(
                      'Kamakshi Palaya',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                 Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                color: AppColors.textSecondary,
                shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.spacingS),
                                Text(
                                  'Cubbon Park',
                                  style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Distance badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SizedBox(height: AppSizes.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingXS,
                            vertical: AppSizes.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundColor,
                            borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                          ),
                          child: Text(
                            '16km',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSizes.spacingS),
                            Align(
                  alignment: Alignment.centerRight,
                  child: CommonButton(
                    text: 'View all',
                    fontSize: 12,
                    padding: EdgeInsets.zero,
                    textColor: AppColors.surfaceColor,
                    onPressed: widget.onTap,
                   height: 28,
                  ),
                ),
                      ],
                    ),

                  ],
                ),

                // const SizedBox(height: AppSizes.spacingM),

                // Locations
               

              //  const SizedBox(height: AppSizes.spacingXS),

               

              //  const SizedBox(height: AppSizes.spacingM),

                // View all button
            
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Map Section with Google Maps showing static route
  Widget _buildMapSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppSizes.radiusL),
        topRight: Radius.circular(AppSizes.radiusL),
      ),
      child: Container(
        height: 200,
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _startLocation,
                zoom: 13.0,
              ),
              markers: _markers,
              polylines: _polylines,
              mapType: MapType.normal,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
            ),
            
            // Location labels overlay
            Positioned(
              left: AppSizes.paddingM,
              top: AppSizes.paddingM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingS,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  'Kamakshi Palaya',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            Positioned(
              right: AppSizes.paddingM,
              bottom: AppSizes.paddingM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingS,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  'Cubbon Park',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
