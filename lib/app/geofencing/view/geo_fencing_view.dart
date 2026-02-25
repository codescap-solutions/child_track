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

class GeoFencingView extends StatefulWidget {
  final String? childId;
  final String? parentId;

  const GeoFencingView({super.key, this.childId, this.parentId});

  @override
  State<GeoFencingView> createState() => _GeoFencingViewState();
}

class _GeoFencingViewState extends State<GeoFencingView> {
  int _selectedTabIndex = 1;
  PageController _pageController = PageController();
  List<Geofence> _geofences = [];
  int _defaultRadius = 30;

  @override
  void initState() {
    super.initState();
    // Load geofences when the view is initialized
    if (widget.childId != null) {
      context.read<GeofenceBloc>().add(
        GetGeofencesRequested(childId: widget.childId!),
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
      body: BlocListener<GeofenceBloc, GeofenceState>(
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
              const SnackBar(content: Text('Geofence created successfully')),
            );
          } else if (state is GeofenceDeleted) {
            setState(() {
              _geofences.removeWhere((g) => g.id == state.geofenceId);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Geofence deleted successfully')),
            );
          } else if (state is GeofenceLockToggled) {
            setState(() {
              final index = _geofences.indexWhere(
                (g) => g.id == state.geofence.id,
              );
              if (index != -1) {
                _geofences[index] = state.geofence;
              }
            });
          } else if (state is GeofenceError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.spacingM),
              AdvancedSegmentedTab(
                onTabChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
              ),
              const SizedBox(height: 10),
              _buildRadiusInfo(context),
              const SizedBox(height: 10),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildGeofencesListView(),
                    _buildGeofencesListView(forTest: true),
                    _buildGeofencesListView(),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildGeofencesListView({bool forTest = false}) {
    if (_geofences.isEmpty && forTest) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          final geofence = Geofence();
          return GeoPlaceCard(
            title:
                geofence.name ??
                (forTest
                    ? "Test Geofence ${index + 1}"
                    : "Geofence ${index + 1}"),
            subtitle:
                "${geofence.category ?? (forTest ? "Test Category" : "Unknown")} • ${geofence.radius ?? 0}m radius",
            isPrimary: true,
            toggleValue:
                geofence.isLocked ?? (forTest ? index % 2 == 0 : false),
            geofenceId: geofence.id,
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
            onDelete: () {
              _showDeleteConfirmation(geofence);
            },
          );
        },
      );
    } else if (_geofences.isEmpty && !forTest) {
      return _buildAddGeofencesView();
    }

    return ListView.builder(
      itemCount: _geofences.length,
      itemBuilder: (context, index) {
        final geofence = _geofences[index];
        return GeoPlaceCard(
          title:
              geofence.name ??
              "Unknown Place", // Fallback to "Unknown Place" if name is null
          subtitle:
              "${geofence.category ?? "Unknown"} • ${geofence.radius ?? 0}m radius",
          isPrimary: true,
          toggleValue: geofence.isLocked ?? false,
          geofenceId: geofence.id,
          onToggle: (value) {
            if (geofence.id != null) {
              context.read<GeofenceBloc>().add(
                ToggleGeofenceLockRequested(id: geofence.id!, isLocked: value),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid geofence ID')),
              );
            }
          },
          onDelete: () {
            _showDeleteConfirmation(geofence);
          },
        );
      },
    );
  }

  void _navigateToLocationSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSelectionScreen(
          childId: widget.childId,
          parentId: widget.parentId,
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
}

Widget _buildRadiusInfo(BuildContext context) {
  final state = context.findAncestorStateOfType<_GeoFencingViewState>();
  final radius = state?._defaultRadius ?? 30;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${radius}mtr radius will be locked",
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => state?._showRadiusEditDialog(),
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

class GeoPlaceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isPrimary;
  final bool toggleValue;
  final String? geofenceId;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;

  const GeoPlaceCard({
    super.key,
    required this.title,
    this.subtitle,
    this.toggleValue = false,
    this.isPrimary = false,
    this.geofenceId,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAddCard = title.contains('Add');

    return GestureDetector(
      onTap: isAddCard ? (onTap ?? _defaultNavigate) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.04),
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPrimary
                    ? const Color(0xFF0C5391)
                    : const Color(0xFF666363),
              ),
              child: Container(
                decoration: isPrimary && !isAddCard
                    ? null
                    : BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                child: Icon(
                  isPrimary && !isAddCard ? getIconByName(title) : Icons.add,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xFF0070F0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isAddCard) ...[
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete' && onDelete != null) {
                    onDelete!();
                  }
                },
              ),
              CustomToggleSwitch(
                value: toggleValue,
                onChanged: onToggle ?? (value) {},
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _defaultNavigate() {
    // This won't be called if onTap is provided
  }
}

class CustomToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomToggleSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CustomToggleSwitch> createState() => _CustomToggleSwitchState();
}

class _CustomToggleSwitchState extends State<CustomToggleSwitch> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.value;
  }

  void toggle() {
    setState(() {
      isOn = !isOn;
    });
    widget.onChanged(isOn);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 58,
        height: 33,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isOn ? const Color(0xFF0070F0) : Color(0xFF898C8E),

          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 23,
            height: 25,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData getIconByName(String name) {
  switch (name.toLowerCase()) {
    case 'home':
      return Icons.home;
    case 'school':
      return Icons.school;
    case 'office':
      return Icons.business;
    case 'hospital':
      return Icons.local_hospital;
    case 'park':
      return Icons.park;
    case 'shop':
      return Icons.store;
    case 'gym':
      return Icons.fitness_center;
    case 'mosque':
      return Icons.mosque;
    case 'church':
      return Icons.church;
    default:
      return Icons.location_on; // default fallback
  }
}
