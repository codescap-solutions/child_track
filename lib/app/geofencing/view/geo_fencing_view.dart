import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../social_apps/view/social_apps_view.dart';
import 'location_selections.dart';
import '../view_model/bloc/geofence_bloc.dart';
import '../view_model/bloc/geofence_event.dart';
import '../view_model/bloc/geofence_state.dart';
import '../model/geofence_model.dart';
import 'widgets/geoplace_card.dart';

class GeoFencingView extends StatefulWidget {
  final String? childId;
  final String? parentId;

  const GeoFencingView({super.key, this.childId, this.parentId});

  @override
  State<GeoFencingView> createState() => _GeoFencingViewState();
}

enum FetchResult { success, failure, loading }

class _GeoFencingViewState extends State<GeoFencingView> {
  final PageController _pageController = PageController();
  List<Geofence> _geofences = [];
  int _defaultRadius = 30;
  String? _lastDateParam;
  String? _lastStartDate;
  String? _lastEndDate;

  @override
  void initState() {
    super.initState();
    // Load geofences when the view is initialized
    if (widget.childId != null) {
      // Default to today's data on initial load
      final today = DateTime.now();
      final todayStr =
          "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      _lastDateParam = todayStr;
      _lastStartDate = null;
      _lastEndDate = null;
      context.read<GeofenceBloc>().add(
        GetGeofencesRequested(childId: widget.childId!, date: todayStr),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showRadiusEditDialog() {
    final radiusController = TextEditingController(
      text: _defaultRadius.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Default Radius'),
        content: TextField(
          controller: radiusController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter radius in meters',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixText: 'meters',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newRadius = int.tryParse(radiusController.text);
              if (newRadius != null && newRadius > 0) {
                setState(() {
                  _defaultRadius = newRadius;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Default radius changed to ${_defaultRadius}m',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid radius')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Geofencing', style: AppTextStyles.headline3),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSizes.spacingM),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: AdvancedSegmentedTab(
              onTabChanged: (index) {
                // map tab index -> date parameter
                String? dateParam;
                final now = DateTime.now();
                if (index == 0) {
                  final yesterday = now.subtract(const Duration(days: 1));
                  dateParam =
                      "${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
                } else if (index == 1) {
                  dateParam =
                      "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                } else if (index == 2) {
                  // For week, compute startDate and endDate (7-day range)
                  final now = DateTime.now();
                  final start = now.subtract(const Duration(days: 6));
                  final startStr =
                      "${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
                  final endStr =
                      "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                  // We'll store range separately for retry logic
                  _lastStartDate = startStr;
                  _lastEndDate = endStr;
                  dateParam =
                      null; // use startDate/endDate instead of single date
                }
                setState(() {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });

                // remember last requested date and request
                _lastDateParam = dateParam ?? _lastDateParam;
                setState(() {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });

                if (widget.childId != null) {
                  if (index == 2) {
                    context.read<GeofenceBloc>().add(
                      GetGeofencesRequested(
                        childId: widget.childId!,
                        startDate: _lastStartDate,
                        endDate: _lastEndDate,
                      ),
                    );
                  } else {
                    // clear any previous range when requesting a single date
                    _lastStartDate = null;
                    _lastEndDate = null;
                    context.read<GeofenceBloc>().add(
                      GetGeofencesRequested(
                        childId: widget.childId!,
                        date: _lastDateParam,
                      ),
                    );
                  }
                }
              },
            ),
          ),
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
                // Loading
                if (state is GeofenceLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error: show UI with retry
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
                                if (_lastStartDate != null &&
                                    _lastEndDate != null) {
                                  context.read<GeofenceBloc>().add(
                                    GetGeofencesRequested(
                                      childId: widget.childId!,
                                      startDate: _lastStartDate,
                                      endDate: _lastEndDate,
                                    ),
                                  );
                                } else {
                                  context.read<GeofenceBloc>().add(
                                    GetGeofencesRequested(
                                      childId: widget.childId!,
                                      date: _lastDateParam,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Loaded / other states: render content using current list
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildRadiusInfo(context),
                      const SizedBox(height: 10),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildGeofencesListView(),
                            _buildGeofencesListView(),
                            _buildGeofencesListView(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGeofencesView() {
    return ListView(
      children: [
        GeoPlaceCard(
          title: "Add Home",
          subtitle: "given radius will be marked",
          isPrimary: true,
          onTap: _navigateToLocationSelection,
        ),
        GeoPlaceCard(
          title: "Add School",
          subtitle: "given radius will be marked",
          isPrimary: true,
          onTap: _navigateToLocationSelection,
        ),
        GeoPlaceCard(title: "Add Place", onTap: _navigateToLocationSelection),
      ],
    );
  }

  Widget _buildGeofencesListView() {
    if (_geofences.isEmpty) {
      return _buildAddGeofencesView();
    }

    return ListView.builder(
      itemCount: _geofences.length + 1,
      itemBuilder: (context, index) {
        Geofence? geofence;
        if (index < _geofences.length) {
          geofence = _geofences[index];
        }
        return index < _geofences.length
            ? GeoPlaceCard(
                title:
                    geofence?.name ??
                    "Unknown Place", // Fallback to "Unknown Place" if name is null
                subtitle:
                    "${geofence?.category ?? "Unknown"} • ${geofence?.radius ?? 0}m radius",
                isPrimary: true,
                toggleValue: geofence?.isLocked ?? false,
                geofenceId: geofence?.id,
                onTap: () => _navigateToLocationSelection(geofence: geofence),
                onToggle: (value) {
                  if (geofence?.id != null) {
                    context.read<GeofenceBloc>().add(
                      ToggleGeofenceLockRequested(
                        id: geofence?.id ?? '',
                        isLocked: value,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid geofence ID')),
                    );
                  }
                },
                onDelete: () {
                  if (geofence != null) {
                    _showDeleteConfirmation(geofence);
                  }
                },
              )
            : GeoPlaceCard(
                title: "Add Place",
                onTap: _navigateToLocationSelection,
              );
      },
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

  void _showDeleteConfirmation(Geofence geofence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Geofence'),
        content: Text('Are you sure you want to delete "${geofence.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (geofence.id != null) {
                Navigator.pop(context);
                context.read<GeofenceBloc>().add(
                  DeleteGeofenceRequested(id: geofence.id!),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid geofence ID')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${_defaultRadius}mtr radius will be locked",
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              _showRadiusEditDialog();
            },
            child: const Text(
              "edit",
              style: TextStyle(
                color: Color(0xFF0070F0),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
