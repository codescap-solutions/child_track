import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../map/view/map_view.dart';
import '../view_model/bloc/geofence_bloc.dart';
import '../view_model/bloc/geofence_event.dart';
import '../view_model/bloc/geofence_state.dart';
import '../model/geofence_model.dart';

class LocationSelectionScreen extends StatefulWidget {
  final String? childId;
  final String? parentId;
  final Geofence? geofence;

  const LocationSelectionScreen({
    super.key,
    this.childId,
    this.parentId,
    this.geofence,
  });

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  bool _showSuggestions = false;
  final Set<Marker> _markers = {};
  bool _isMapReady = false;

  static const LatLng _initialPosition = LatLng(12.9716, 77.5946); // Bengaluru

  @override
  void initState() {
    super.initState();
    // If we are editing an existing geofence, show its marker initially
    if (widget.geofence != null) {
      final g = widget.geofence!;
      if (g.latitude != null && g.longitude != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: LatLng(g.latitude!, g.longitude!),
            infoWindow: InfoWindow(title: g.name ?? 'Selected Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            onTap: () async {
              setState(() {
                _showSuggestions = false;
              });

              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => GeoFenceFormSheet(
                  latitude: g.latitude!,
                  longitude: g.longitude!,
                  childId: widget.childId ?? '',
                  parentId: widget.parentId ?? '',
                  geofence: g,
                ),
              );
              if (result != null) {
                Navigator.pop(context, result);
              }
            },
          ),
        );
        _searchController.text = g.name ?? '';
        // Open the edit sheet automatically when screen is opened for editing
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final result = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => GeoFenceFormSheet(
              latitude: g.latitude!,
              longitude: g.longitude!,
              childId: widget.childId ?? '',
              parentId: widget.parentId ?? '',
              geofence: g,
            ),
          );
          if (result != null) {
            Navigator.pop(context, result);
          }
        });
      }
    } else if (widget.childId != null) {
      // If we are creating a new geofence, fetch the child's location natively
      context.read<GeofenceBloc>().add(
        FetchChildLocationRequested(childId: widget.childId!),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Selected Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () async {
            setState(() {
              _showSuggestions = false;
            });

            final result = await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => GeoFenceFormSheet(
                latitude: position.latitude,
                longitude: position.longitude,
                childId: widget.childId ?? '',
                parentId: widget.parentId ?? '',
                geofence: widget.geofence,
              ),
            );
            if (result != null) {
              Navigator.pop(context, result);
            }
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey.shade300,
      body: BlocListener<GeofenceBloc, GeofenceState>(
        listener: (context, state) {
          if (state is GeofenceError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is PlaceCoordinatesLoaded) {
            _addMarker(state.coordinates);
            if (_isMapReady) {
              _controller.future.then((controller) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(state.coordinates, 16),
                );
              });
            }
          } else if (state is ChildLocationLoaded) {
            if (_isMapReady) {
              _controller.future.then((controller) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(state.coordinates, 16),
                );
              });
            } else {
              // Defer camera movement if controller hasn't completed yet
              _controller.future.then((controller) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(state.coordinates, 16),
                );
              });
            }
          }
        },
        child: Stack(
          children: [
            MapViewWidget(
              key: const ValueKey('location_map_selection'),
              width: double.infinity,
              height: double.infinity,
              interactive: true,
              myLocationEnabled: false,
              minZoom: 0.0,
              maxZoom: 20,
              myLocationButtonEnabled: false,
              markers: _markers.toList(),
              onMapCreated: (controller) async {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                  setState(() {
                    _isMapReady = true;
                  });
                  await Future.delayed(const Duration(milliseconds: 500));

                  final state = context.read<GeofenceBloc>().state;

                  if (widget.geofence != null &&
                      widget.geofence!.latitude != null &&
                      widget.geofence!.longitude != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          widget.geofence!.latitude!,
                          widget.geofence!.longitude!,
                        ),
                        16,
                      ),
                    );
                  } else if (state is ChildLocationLoaded) {
                    // Do nothing, listener will handle it or already did
                  } else {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(_initialPosition, 14),
                    );
                  }
                }
              },
              onMapTap: (position) async {
                _addMarker(position);
                setState(() {
                  _showSuggestions = false;
                });

                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => GeoFenceFormSheet(
                    latitude: position.latitude,
                    longitude: position.longitude,
                    childId: widget.childId ?? '',
                    parentId: widget.parentId ?? '',
                    geofence: widget.geofence,
                  ),
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
                child: Column(
                  children: [
                    Container(
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
                          const SizedBox(width: 13),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: "search location",
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                isCollapsed: true,
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  context.read<GeofenceBloc>().add(
                                    SearchLocationSuggestionsRequested(
                                      query: value,
                                    ),
                                  );
                                  setState(() {
                                    _showSuggestions = true;
                                  });
                                } else {
                                  setState(() {
                                    _showSuggestions = false;
                                  });
                                }
                              },
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
                              color: const Color(0xFFF0EEEE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search),
                          ),
                        ],
                      ),
                    ),
                    if (_showSuggestions)
                      BlocBuilder<GeofenceBloc, GeofenceState>(
                        builder: (context, state) {
                          if (state is LocationSuggestionsLoaded) {
                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: state.suggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = state.suggestions[index];
                                  return ListTile(
                                    title: Text(
                                      suggestion.mainText ?? "Unknown",
                                    ),
                                    subtitle: Text(
                                      suggestion.description ??
                                          "Unknown location",
                                    ),
                                    onTap: () {
                                      // Use BLoC to fetch coordinates from Google Places API
                                      _searchController.text =
                                          suggestion.mainText!;
                                      setState(() {
                                        _showSuggestions = false;
                                      });

                                      // Emit event to fetch place coordinates via BLoC
                                      context.read<GeofenceBloc>().add(
                                        GetPlaceCoordinatesRequested(
                                          placeId: suggestion.placeId!,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
  final double latitude;
  final double longitude;
  final String childId;
  final String parentId;
  final Geofence? geofence;

  const GeoFenceFormSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.childId,
    required this.parentId,
    this.geofence,
  });

  @override
  State<GeoFenceFormSheet> createState() => _GeoFenceFormSheetState();
}

class _GeoFenceFormSheetState extends State<GeoFenceFormSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController radiusController = TextEditingController(
    text: '30',
  );

  String? selectedCategory;

  final List<String> categories = ["home", "school", "tuition", "other"];

  @override
  void dispose() {
    nameController.dispose();
    radiusController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Prefill fields when editing
    if (widget.geofence != null) {
      final g = widget.geofence!;
      nameController.text = g.name ?? '';
      selectedCategory = g.category;
      radiusController.text = (g.radius ?? 30).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeofenceBloc, GeofenceState>(
      listener: (context, state) {
        if (state is GeofenceCreated) {
          Navigator.pop(context, {
            "id": state.geofence.id,
            "name": state.geofence.name,
            "category": state.geofence.category,
            "latitude": state.geofence.latitude,
            "longitude": state.geofence.longitude,
            "radius": state.geofence.radius,
          });
        } else if (state is GeofenceUpdated) {
          Navigator.pop(context, {
            "id": state.geofence.id,
            "name": state.geofence.name,
            "category": state.geofence.category,
            "latitude": state.geofence.latitude,
            "longitude": state.geofence.longitude,
            "radius": state.geofence.radius,
          });
        } else if (state is GeofenceError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Padding(
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
              const SizedBox(height: 8),

              /// Name Field
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Geofence Name",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  hintText: "Category",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              /// Radius Field (in meters)
              TextField(
                controller: radiusController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Radius (meters)",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Save Button
              BlocBuilder<GeofenceBloc, GeofenceState>(
                builder: (context, state) {
                  final isLoading = state is GeofenceLoading;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12201C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLoading ? null : _handleSaveGeofence,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Save", style: TextStyle(fontSize: 16)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSaveGeofence() {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a geofence name')),
      );
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final radius = int.tryParse(radiusController.text) ?? 30;

    if (widget.geofence != null && widget.geofence!.id != null) {
      final updateRequest = UpdateGeofenceRequest(
        name: nameController.text,
        category: selectedCategory,
        radius: radius,
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      context.read<GeofenceBloc>().add(
        UpdateGeofenceRequested(
          id: widget.geofence!.id!,
          request: updateRequest,
        ),
      );
      return;
    }

    final request = CreateGeofenceRequest(
      name: nameController.text,
      category: selectedCategory!,
      radius: radius,
      childId: widget.childId,
      parentId: widget.parentId,
      latitude: widget.latitude,
      longitude: widget.longitude,
      isLocked: false,
    );

    context.read<GeofenceBloc>().add(CreateGeofenceRequested(request: request));
  }
}
