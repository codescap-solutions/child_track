
// Map Section Widget with Google Maps
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSection extends StatefulWidget {
  const MapSection({super.key});

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoading = true;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _kidMarkerIcon;
  BitmapDescriptor? _parentMarkerIcon;

  @override
  void initState() {
    super.initState();
    _createCustomMarkers();
    _getCurrentLocation();
  }

  Future<void> _createCustomMarkers() async {
    // Create kid marker with avatar and battery
    _kidMarkerIcon = await _createMarkerWithAvatar(
      avatarColor: AppColors.error,
      batteryLevel: 90,
      isKid: true,
    );

    // Create parent marker (blue)
    _parentMarkerIcon = await _createMarkerWithAvatar(
      avatarColor: AppColors.info,
      batteryLevel: null,
      isKid: false,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<BitmapDescriptor> _createMarkerWithAvatar({
    required Color avatarColor,
    int? batteryLevel,
    required bool isKid,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double markerWidth = 80.0;
    const double markerHeight = 100.0;

    // Draw marker shape (teardrop)
    final Paint markerPaint = Paint()
      ..color = avatarColor
      ..style = PaintingStyle.fill;

    final Path markerPath = Path();
    // Teardrop shape
    markerPath.moveTo(markerWidth / 2, 0);
    markerPath.arcToPoint(
      Offset(markerWidth, markerHeight * 0.7),
      radius: Radius.circular(markerWidth / 2),
      clockwise: false,
    );
    markerPath.lineTo(markerWidth / 2, markerHeight);
    markerPath.close();

    canvas.drawPath(markerPath, markerPaint);

    // Draw white border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(markerPath, borderPaint);

    // Draw avatar circle
    final double avatarRadius = 28;
    final Offset avatarCenter = Offset(markerWidth / 2, markerHeight * 0.35);

    // Avatar background
    final Paint avatarPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(avatarCenter, avatarRadius, avatarPaint);

    // Avatar border
    final Paint avatarBorderPaint = Paint()
      ..color = avatarColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(avatarCenter, avatarRadius, avatarBorderPaint);

    // Draw avatar icon (person or character)
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: isKid ? '👤' : '👨',
        style: TextStyle(
          fontSize: 32,
          color: avatarColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        avatarCenter.dx - textPainter.width / 2,
        avatarCenter.dy - textPainter.height / 2,
      ),
    );

    // Draw battery indicator if provided
    if (batteryLevel != null) {
      final double batteryWidth = 24;
      final double batteryHeight = 12;
      final Offset batteryPos = Offset(
        markerWidth / 2 - batteryWidth / 2,
        markerHeight * 0.65,
      );

      // Battery outline
      final Paint batteryOutlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final RRect batteryRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          batteryPos.dx,
          batteryPos.dy,
          batteryWidth,
          batteryHeight,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(batteryRect, batteryOutlinePaint);

      // Battery terminal
      canvas.drawRect(
        Rect.fromLTWH(
          batteryPos.dx + batteryWidth,
          batteryPos.dy + batteryHeight * 0.25,
          2,
          batteryHeight * 0.5,
        ),
        batteryOutlinePaint..style = PaintingStyle.fill,
      );

      // Battery fill
      final double fillWidth = (batteryWidth - 4) * (batteryLevel / 100);
      final Paint batteryFillPaint = Paint()
        ..color = AppColors.success
        ..style = PaintingStyle.fill;
      final RRect fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          batteryPos.dx + 2,
          batteryPos.dy + 2,
          fillWidth,
          batteryHeight - 4,
        ),
        const Radius.circular(1),
      );
      canvas.drawRRect(fillRect, batteryFillPaint);

      // Battery percentage text
      final TextPainter batteryTextPainter = TextPainter(
        text: TextSpan(
          text: '$batteryLevel%',
          style: const TextStyle(
            fontSize: 8,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      batteryTextPainter.layout();
      batteryTextPainter.paint(
        canvas,
        Offset(
          markerWidth / 2 - batteryTextPainter.width / 2,
          batteryPos.dy + batteryHeight + 2,
        ),
      );
    }

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(
      markerWidth.toInt(),
      markerHeight.toInt(),
    );
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
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

  Future<void> _moveToCurrentLocation() async {
    Position? position = await _locationService.getCurrentPosition();
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );
      setState(() {
        _currentPosition = position;
        _markers.clear();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.beach,
      child: Stack(
        children: [
          // Google Map
          Positioned.fill(
            child: _isLoading
                ? Container(
                    color: AppColors.beach,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null
                          ? LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            )
                          : const LatLng(12.9716, 77.5946), // Default: Bangalore
                      zoom: _currentPosition != null ? 15.0 : 12.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                  ),
          ),

       

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
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
