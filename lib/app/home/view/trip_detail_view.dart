import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Trip Detail View - Shows detailed trip with map and timeline
class TripDetailView extends StatefulWidget {
  const TripDetailView({super.key});

  @override
  State<TripDetailView> createState() => _TripDetailViewState();
}

class _TripDetailViewState extends State<TripDetailView> {
  GoogleMapController? _mapController;
  
  // Static route coordinates: Kamakshi Palaya to Cubbon Park, Bangalore
  static const LatLng _startLocation = LatLng(12.9716, 77.5946); // Kamakshi Palaya area
  static const LatLng _endLocation = LatLng(12.9764, 77.5928); // Cubbon Park area
  
  // Intermediate points for a more detailed route
  final List<LatLng> _routePoints = const [
    LatLng(12.9716, 77.5946), // Start: Kamakshi Palaya
    LatLng(12.9720, 77.5940),
    LatLng(12.9725, 77.5935),
    LatLng(12.9730, 77.5932),
    LatLng(12.9735, 77.5930),
    LatLng(12.9740, 77.5928),
    LatLng(12.9745, 77.5925),
    LatLng(12.9750, 77.5926),
    LatLng(12.9755, 77.5925),
    LatLng(12.9760, 77.5927),
    LatLng(12.9764, 77.5928), // End: Cubbon Park
  ];
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _homeIcon;
  BitmapDescriptor? _schoolIcon;
  
  @override
  void initState() {
    super.initState();
    _createCustomIcons();
  }
  
  Future<void> _createCustomIcons() async {
    // Create home icon marker
    _homeIcon = await _createMarkerIcon(
      Icons.home,
      AppColors.primaryColor,
    );
    
    // Create school icon marker
    _schoolIcon = await _createMarkerIcon(
      Icons.school,
      AppColors.success,
    );
    
    _initializeMap();
  }
  
  Future<BitmapDescriptor> _createMarkerIcon(IconData icon, Color color) async {
    final size = 50.0;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Draw circle background
    final paint = Paint()..color = color;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 3,
      paint,
    );
    
    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 3,
      borderPaint,
    );
    
    // Draw icon using a simple approach - create text with icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 28,
          fontFamily: icon.fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final bitmap = bytes!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(bitmap);
  }
  
  void _initializeMap() {
    if (_homeIcon == null || _schoolIcon == null) return;
    
    // Create start marker (Home)
    _markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: _startLocation,
        icon: _homeIcon!,
        infoWindow: const InfoWindow(
          title: 'Home',
          snippet: 'Kamakshi Palaya',
        ),
      ),
    );
    
    // Create end marker (School)
    _markers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: _endLocation,
        icon: _schoolIcon!,
        infoWindow: const InfoWindow(
          title: 'School',
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
    
    setState(() {});
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Fit bounds to show entire route
    Future.delayed(const Duration(milliseconds: 500), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList(_routePoints),
          100.0, // padding
        ),
      );
    });
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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Map Section (Full screen)
          _buildMapSection(context),

          // Bottom Sheet with Trip Timeline
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.8,
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
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
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

                    // Trip Time Range
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingL,
                      ),
                      child: Text(
                        '08:43 am - 09:20 am',
                        style: AppTextStyles.headline6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingL),

                    // Trip Timeline
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingL,
                        ),
                        children: [
                          _buildTimelineItem(
                            icon: Icons.home,
                            title: 'Home',
                            time: '08:49',
                            color: AppColors.primaryColor,
                          ),
                          // _buildTimelineItem(
                          //   icon: Icons.directions_bus,
                          //   title: 'Ride',
                          //   subtitle: '6.4km (37min)',
                          //   time: null,
                          //   badge: 'max speed - 24.5 kmp',
                          //   color: AppColors.info,
                          // ),
                          _buildTimelineItem(
                            icon: Icons.school,
                            title: 'School',
                            time: '09:21',
                            color: AppColors.success,
                          ),
                          // // Additional items for scroll demonstration
                          // _buildTimelineItem(
                          //   icon: Icons.restaurant,
                          //   title: 'Lunch Break',
                          //   time: '12:30',
                          //   color: AppColors.warning,
                          // ),
                          // _buildTimelineItem(
                          //   icon: Icons.home,
                          //   title: 'Home',
                          //   time: '21:20',
                          //   color: AppColors.primaryColor,
                          // ),
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
  }

  // Map Section with Google Maps showing route
  Widget _buildMapSection(BuildContext context) {
    return Stack(
      children: [
        // Google Map (Full screen)
        Positioned.fill(
          child:     GoogleMap(
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
        ),

        // App Bar Overlay
        SafeArea(
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: AppColors.textPrimary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor.withValues(alpha: 0.9),
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
            centerTitle: true,
          ),
        ),

        // Location labels overlay
        Positioned(
          left: AppSizes.paddingL,
          top: 100,
          child: _buildLocationLabel('Kamakshi Palaya'),
        ),
        
        Positioned(
          right: AppSizes.paddingL,
          bottom: 200,
          child: _buildLocationLabel('Cubbon Park'),
        ),
      ],
    );
  }

  // Location Label Widget
  Widget _buildLocationLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingS,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  // Timeline Item Widget
  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? time,
    String? badge,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and icon
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if(icon == Icons.home)
              Container(width: 2, height: 60, color: AppColors.borderColor),
            ],
          ),

          const SizedBox(width: AppSizes.spacingM),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSizes.spacingXS),
                            Text(
                              subtitle,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (badge != null) ...[
                            const SizedBox(height: AppSizes.spacingXS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingS,
                                vertical: AppSizes.paddingXS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusS,
                                ),
                              ),
                              child: Text(
                                badge,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (time != null)
                      Text(
                        time,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingXS),
                if(icon == Icons.home)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.containerBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                child:Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text('Ride'),
                  Text('6.4km (37min)'),
                    const SizedBox(height: AppSizes.spacingXS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingS,
                                vertical: AppSizes.paddingXS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusS,
                                ),
                              ),
                              child: Text(
                              'max speed - 24.5 kmp',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                  ],
                ),
              )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
