import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../../core/constants/app_sizes.dart';
import '../../../core/services/shared_prefs_service.dart';
import 'location_selections.dart';
import 'place_selection_view.dart';
import '../view_model/bloc/geofence_bloc.dart';
import '../view_model/bloc/geofence_event.dart';
import '../view_model/bloc/geofence_state.dart';
import '../model/geofence_model.dart';
import 'widgets/geoplace_card.dart';
import 'package:child_track/core/widgets/geo_fencing_shimmer.dart';

class GeoFencingView extends StatefulWidget {
  final String? childId;
  final String? parentId;

  const GeoFencingView({super.key, this.childId, this.parentId});

  @override
  State<GeoFencingView> createState() => _GeoFencingViewState();
}

class _GeoFencingViewState extends State<GeoFencingView> {
  List<Geofence> _geofences = [];
  int _defaultRadius = 30;
  String? _lastDateParam;

  String _getChildName() {
    return SharedPrefsService().getString('child_name') ?? 'Ananya';
  }

  String _getChildEmoji() {
    final name = _getChildName().toLowerCase();
    if (name.contains('rohan')) return '👦';
    return '👧';
  }

  @override
  void initState() {
    super.initState();
    // Load default radius from SharedPreferences
    _defaultRadius = SharedPrefsService().getInt('default_radius') ?? 30;

    // Load geofences when the view is initialized
    if (widget.childId != null) {
      // Default to today's data on initial load
      final today = DateTime.now();
      final todayStr =
          "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      _lastDateParam = todayStr;
      context.read<GeofenceBloc>().add(
        GetGeofencesRequested(childId: widget.childId!, date: todayStr),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Count how many geofences are active (locked)
    final activeCount = _geofences.where((g) => g.isLocked ?? false).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leadingWidth: 72,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Geofencing',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0C1D37),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildChildHeaderRow(activeCount),
          Expanded(
            child: BlocConsumer<GeofenceBloc, GeofenceState>(
              listener: (context, state) {
                if (state is GeofencesLoaded) {
                  setState(() {
                    _geofences = state.geofences;
                  });
                } else if (state is GeofenceCreated) {
                  setState(() {
                    _geofences.add(state.geofence);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geofence created successfully'),
                    ),
                  );
                } else if (state is GeofenceUpdated) {
                  setState(() {
                    final index = _geofences.indexWhere(
                      (g) => g.id == state.geofence.id,
                    );
                    if (index != -1) _geofences[index] = state.geofence;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geofence updated successfully'),
                    ),
                  );
                } else if (state is GeofenceDeleted) {
                  setState(() {
                    _geofences.removeWhere((g) => g.id == state.geofenceId);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geofence deleted successfully'),
                    ),
                  );
                } else if (state is GeofenceLockToggled) {
                  setState(() {
                    final index = _geofences.indexWhere(
                      (g) => g.id == state.geofence.id,
                    );
                    if (index != -1) _geofences[index] = state.geofence;
                  });
                } else if (state is GeofenceError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is GeofenceLoading) {
                  return const GeoFencingShimmer();
                }

                if (state is GeofenceError) {
                  final message = state.message;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            message,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (widget.childId != null) {
                                context.read<GeofenceBloc>().add(
                                  GetGeofencesRequested(
                                    childId: widget.childId!,
                                    date: _lastDateParam,
                                  ),
                                );
                              }
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                  ),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 14),

                      // Fences List
                      if (_geofences.isNotEmpty)
                        ..._geofences.map(
                          (geofence) => GeoPlaceCard(
                            title: geofence.name ?? "Unknown Place",
                            radius: geofence.radius ?? _defaultRadius,
                            toggleValue: geofence.isLocked ?? false,
                            category: geofence.category,
                            onTap: () => _navigateToLocationSelection(geofence: geofence),
                            onToggle: (value) {
                              if (geofence.id != null) {
                                context.read<GeofenceBloc>().add(
                                  ToggleGeofenceLockRequested(
                                    id: geofence.id!,
                                    isLocked: value,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invalid geofence ID')),
                                );
                              }
                            },
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Suggested Fences Section
                      _buildSuggestedFencesHeader(),
                      const SizedBox(height: 8),
                      _buildSuggestedFenceTile(
                        "${_getChildName()}'s School, Whitefield",
                        const LatLng(12.9698, 77.7500),
                      ),
                      _buildSuggestedFenceTile(
                        "Cubbon Park, Bengaluru",
                        const LatLng(12.9738, 77.5906),
                      ),

                      const SizedBox(height: 80), // spacer for FAB
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToPlaceSelection,
        backgroundColor: const Color(0xFF0066FF),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildChildHeaderRow(int activeCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Child selector pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // soft blue tint
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${_getChildEmoji()} ${_getChildName()}",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0066FF),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Color(0xFF0066FF),
                  size: 20,
                ),
              ],
            ),
          ),
          // Active fences count
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$activeCount active ${activeCount == 1 ? 'fence' : 'fences'}",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.check_rounded,
                color: Color(0xFF22C55E),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedFencesHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
      child: Text(
        "SUGGESTED FENCES",
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSuggestedFenceTile(String name, LatLng coordinates) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1D37).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LocationSelectionScreen(
                childId: widget.childId,
                parentId: widget.parentId,
              ),
            ),
          );
        },
        leading: Container(
          height: 36,
          width: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF1F2), // soft rose background
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.location_on_rounded,
              color: Color(0xFFF43F5E), // rose pin color
              size: 18,
            ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0C1D37),
          ),
        ),
        trailing: const Icon(
          CupertinoIcons.chevron_right,
          color: Color(0xFF94A3B8),
          size: 16,
        ),
      ),
    );
  }

  void _navigateToLocationSelection({Geofence? geofence}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSelectionScreen(
          childId: widget.childId,
          parentId: widget.parentId,
          geofence: geofence,
        ),
      ),
    );
  }

  void _navigateToPlaceSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceSelectionScreen(
          childId: widget.childId,
          parentId: widget.parentId,
        ),
      ),
    ).then((_) {
      // Refresh geofences list on return
      if (widget.childId != null && _lastDateParam != null) {
        context.read<GeofenceBloc>().add(
          GetGeofencesRequested(childId: widget.childId!, date: _lastDateParam!),
        );
      }
    });
  }
}
