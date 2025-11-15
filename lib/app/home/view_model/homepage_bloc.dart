import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:child_track/core/services/location_service.dart';
import 'package:child_track/core/constants/app_colors.dart';

part 'homepage_event.dart';
part 'homepage_state.dart';

class HomepageBloc extends Bloc<HomepageEvent, HomepageState> {
  final LocationService _locationService = LocationService();

  HomepageBloc() : super(MapInitial()) {
    on<GetHomepageData>(_onGetHomepageData);
    on<InitializeMap>(_onInitializeMap);
    on<MapCreated>(_onMapCreated);
    on<MoveToCurrentLocation>(_onMoveToCurrentLocation);
  }

  Future<void> _onGetHomepageData(
    GetHomepageData event,
    Emitter<HomepageState> emit,
  ) async {
    emit(HomepageLoading());
    try {
      emit(HomepageSuccess());
    } catch (e) {
      emit(HomepageError(message: e.toString()));
    }
  }

  Future<void> _onInitializeMap(
    InitializeMap event,
    Emitter<HomepageState> emit,
  ) async {
    emit(MapLoading());
    try {
      // Create custom markers
      final kidMarkerIcon = await _createMarkerWithAvatar(
        avatarColor: AppColors.error,
        batteryLevel: 90,
        isKid: true,
      );

      final parentMarkerIcon = await _createMarkerWithAvatar(
        avatarColor: AppColors.info,
        batteryLevel: null,
        isKid: false,
      );

      // Get current location
      Position? position = await _locationService.getCurrentPosition();
      Set<Marker> markers = {};
      Set<Polyline> polylines = {};

      if (position != null) {
        final kidPosition = LatLng(position.latitude, position.longitude);
        final parentPosition = LatLng(
          position.latitude + 0.005,
          position.longitude + 0.005,
        );

        // Add kid marker
        markers.add(
          Marker(
            markerId: const MarkerId('kid_location'),
            position: kidPosition,
            icon: kidMarkerIcon,
            anchor: const Offset(0.5, 1.0),
            infoWindow: const InfoWindow(
              title: 'Kid Location',
              snippet: 'Current position',
            ),
          ),
        );

        // Add parent/office marker (slightly offset for demo)
        markers.add(
          Marker(
            markerId: const MarkerId('parent_location'),
            position: parentPosition,
            icon: parentMarkerIcon,
            anchor: const Offset(0.5, 1.0),
            infoWindow: const InfoWindow(
              title: 'at Office',
              snippet: '1 h 53 m',
            ),
          ),
        );

        // Create polyline between kid and parent locations
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route_kid_to_parent'),
            points: [kidPosition, parentPosition],
            color: AppColors.primaryColor,
            width: 4,
            patterns: [],
            geodesic: true,
          ),
        );
      } else {
        // Try last known position
        Position? lastPosition = await _locationService.getLastKnownPosition();
        if (lastPosition != null) {
          position = lastPosition;
          markers.add(
            Marker(
              markerId: const MarkerId('last_known_location'),
              position: LatLng(lastPosition.latitude, lastPosition.longitude),
              icon: kidMarkerIcon,
              anchor: const Offset(0.5, 1.0),
              infoWindow: const InfoWindow(
                title: 'Last Known Location',
                snippet: 'Last known position',
              ),
            ),
          );
        }
      }

      emit(
        MapLoaded(
          currentPosition: position,
          markers: markers,
          polylines: polylines,
          kidMarkerIcon: kidMarkerIcon,
          parentMarkerIcon: parentMarkerIcon,
        ),
      );
    } catch (e) {
      emit(MapError(message: e.toString()));
    }
  }

  void _onMapCreated(MapCreated event, Emitter<HomepageState> emit) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(mapController: event.controller));

      // Move camera to show all markers if available
      if (currentState.markers.isNotEmpty) {
        // If we have multiple markers, fit bounds, otherwise zoom to location
        if (currentState.markers.length > 1) {
          // Calculate bounds to include all markers
          double minLat = double.infinity;
          double maxLat = -double.infinity;
          double minLng = double.infinity;
          double maxLng = -double.infinity;

          for (final marker in currentState.markers) {
            final lat = marker.position.latitude;
            final lng = marker.position.longitude;
            minLat = minLat < lat ? minLat : lat;
            maxLat = maxLat > lat ? maxLat : lat;
            minLng = minLng < lng ? minLng : lng;
            maxLng = maxLng > lng ? maxLng : lng;
          }

          // Add padding to bounds
          final latDiff = maxLat - minLat;
          final lngDiff = maxLng - minLng;
          final padding = 0.01; // Add 1% padding

          final bounds = LatLngBounds(
            southwest: LatLng(
              minLat - (latDiff * padding),
              minLng - (lngDiff * padding),
            ),
            northeast: LatLng(
              maxLat + (latDiff * padding),
              maxLng + (lngDiff * padding),
            ),
          );

          event.controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100.0),
          );
        } else if (currentState.currentPosition != null) {
          // Single marker - zoom to location
          event.controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(
                currentState.currentPosition!.latitude,
                currentState.currentPosition!.longitude,
              ),
              15.0,
            ),
          );
        } else {
          // Fallback to first marker position
          final firstMarker = currentState.markers.first;
          event.controller.animateCamera(
            CameraUpdate.newLatLngZoom(firstMarker.position, 15.0),
          );
        }
      } else if (currentState.currentPosition != null) {
        event.controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              currentState.currentPosition!.latitude,
              currentState.currentPosition!.longitude,
            ),
            15.0,
          ),
        );
      }
    }
  }

  Future<void> _onMoveToCurrentLocation(
    MoveToCurrentLocation event,
    Emitter<HomepageState> emit,
  ) async {
    if (state is! MapLoaded) return;

    final currentState = state as MapLoaded;
    try {
      Position? position = await _locationService.getCurrentPosition();
      if (position != null && currentState.mapController != null) {
        // Move camera
        currentState.mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15.0,
          ),
        );

        // Update markers and polylines
        Set<Marker> markers = {};
        Set<Polyline> polylines = {};

        if (currentState.kidMarkerIcon != null) {
          final kidPosition = LatLng(position.latitude, position.longitude);
          final parentPosition = LatLng(
            position.latitude + 0.005,
            position.longitude + 0.005,
          );

          markers.add(
            Marker(
              markerId: const MarkerId('kid_location'),
              position: kidPosition,
              icon: currentState.kidMarkerIcon!,
              anchor: const Offset(0.5, 1.0),
              infoWindow: const InfoWindow(
                title: 'Kid Location',
                snippet: 'Current position',
              ),
            ),
          );

          if (currentState.parentMarkerIcon != null) {
            markers.add(
              Marker(
                markerId: const MarkerId('parent_location'),
                position: parentPosition,
                icon: currentState.parentMarkerIcon!,
                anchor: const Offset(0.5, 1.0),
                infoWindow: const InfoWindow(
                  title: 'at Office',
                  snippet: '1 h 53 m',
                ),
              ),
            );

            // Create polyline between kid and parent locations
            polylines.add(
              Polyline(
                polylineId: const PolylineId('route_kid_to_parent'),
                points: [kidPosition, parentPosition],
                color: AppColors.primaryColor,
                width: 4,
                patterns: [],
                geodesic: true,
              ),
            );
          }
        }

        emit(
          currentState.copyWith(
            currentPosition: position,
            markers: markers,
            polylines: polylines,
          ),
        );
      }
    } catch (e) {
      emit(MapError(message: e.toString()));
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
        style: TextStyle(fontSize: 32, color: avatarColor),
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
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      // Fallback to default marker if image creation fails
      return BitmapDescriptor.defaultMarker;
    }

    final Uint8List uint8List = byteData.buffer.asUint8List();

    // For Android compatibility, ensure the image is properly formatted
    return BitmapDescriptor.fromBytes(uint8List);
  }
}
