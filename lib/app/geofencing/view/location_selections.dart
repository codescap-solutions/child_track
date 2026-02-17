import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../map/view/map_view.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  Completer<GoogleMapController> _controller = Completer();

  static const LatLng _initialPosition = LatLng(12.9716, 77.5946); // Bengaluru

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _addDemoPath();
  }

  void _addDemoPath() {
    final start = const LatLng(12.9716, 77.5946);
    final end = const LatLng(12.9766, 77.6000);

    _markers.add(
      Marker(
        markerId: const MarkerId("start"),
        position: start,
        infoWindow: const InfoWindow(title: "START"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId("finish"),
        position: end,
        infoWindow: const InfoWindow(title: "FINISH"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    _polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.deepPurple,
        width: 5,
        points: [start, end],
      ),
    );

    _circles.add(
      Circle(
        circleId: const CircleId("geofence"),
        center: end,
        radius: 200, // 200 meters
        strokeWidth: 2,
        strokeColor: Colors.deepPurple,
        fillColor: Colors.deepPurple.withOpacity(0.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: Stack(
        children: [
          MapViewWidget(
            key: const ValueKey('home_map_static'),
            width: double.infinity,
            height: double.infinity,
            interactive: true,
            currentPosition: _initialPosition,
            markers: _markers.toList(),
            myLocationEnabled: true,
            minZoom: 0.0,
            maxZoom: 20,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
            onMapTap: (position) async {
              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const GeoFenceFormSheet(),
              );
              if (result != null) {
                Navigator.pop(context, result);
              }
            },
          ),

          /// Search Bar
          Positioned(
            top: 15,
            left: 17,
            right: 17,
            child: SafeArea(
              child: Container(
                height: 44,

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 13),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: "search",
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isCollapsed: true, // optional: removes extra padding
                        ),
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(0xFFF0EEEE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// Bottom Instruction
          // Positioned(
          //   bottom: 20,
          //   child: Container(
          //     width: MediaQuery.of(context).size.width,
          //     decoration: BoxDecoration(color: Colors.white),
          //     child: const Text(
          //       "zoom in and pick the location you want to fence",
          //       style: TextStyle(fontSize: 12),
          //     ),
          //   ),
          // ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 8),
          ],
        ),
        height: 68,
        alignment: Alignment.center,
        child: const Text(
          "zoom in and pick the location you want to fence",
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class GeoFenceFormSheet extends StatefulWidget {
  const GeoFenceFormSheet({Key? key}) : super(key: key);

  @override
  State<GeoFenceFormSheet> createState() => _GeoFenceFormSheetState();
}

class _GeoFenceFormSheetState extends State<GeoFenceFormSheet> {
  final TextEditingController nameController = TextEditingController();

  String? selectedCategory;

  final List<String> categories = ["Home", "School", "Office", "Other"];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Name Field
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Name",
                hintStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// Category Dropdown
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                hintText: "Category",
                hintStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 24),

            /// Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12201C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final data = {
                    "name": nameController.text,
                    "category": selectedCategory,
                  };

                  Navigator.pop(context, data);
                },
                child: const Text("Save", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
