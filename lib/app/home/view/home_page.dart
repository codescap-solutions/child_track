import 'dart:async';
import 'dart:ui' as ui;
import 'package:child_track/core/navigation/app_router.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_bloc.dart';
import 'package:child_track/app/map/view/map_view.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../settings/view/settings_view.dart';
import '../../social_apps/view/social_apps_view.dart';

import '../../addplace/model/saved_place_model.dart';
import '../../addplace/service/saved_places_service.dart';
import 'child_location_detail_view.dart';
import 'package:child_track/core/services/location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SocketService _socketService = SocketService();
  final SharedPrefsService _sharedPrefsService = injector<SharedPrefsService>();
  StreamSubscription? _locationSubscription;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  late final SavedPlacesService _savedPlacesService;
  List<SavedPlace> _savedPlaces = [];

  @override
  void initState() {
    super.initState();
    _savedPlacesService = injector<SavedPlacesService>();
    _loadSavedPlaces();
    _initSocket();
  }

  Future<void> _loadSavedPlaces() async {
    final places = await _savedPlacesService.getSavedPlaces();
    if (mounted) {
      setState(() {
        _savedPlaces = places;
      });
    }
  }

  SavedPlace? _findMatchingPlace(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    // Tolerance for float comparison (approx 110 meters)
    const double tolerance = 0.001;

    try {
      return _savedPlaces.firstWhere((place) {
        return (place.latitude - lat).abs() < tolerance &&
            (place.longitude - lng).abs() < tolerance;
      });
    } catch (e) {
      return null;
    }
  }

  void _initSocket() {
    final childId = _sharedPrefsService.getString('child_id');
    if (childId != null) {
      if (!_socketService.isConnected) {
        _socketService.initSocket();
      }
      _socketService.joinRoom(childId);

      _locationSubscription = _socketService.locationStream.listen((data) {
        if (mounted) {
          injector<HomepageBloc>().add(UpdateSocketLocation(data));
        }
      });
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  /// Resize image from asset to specified width while maintaining aspect ratio
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<BitmapDescriptor?> _loadCustomMarker(int batteryPercentage) async {
    try {
      // Load main marker image
      final Uint8List markerIconBytes = await _getBytesFromAsset(
        'assets/images/images.png',
        150,
      );

      return BitmapDescriptor.bytes(markerIconBytes);
    } catch (e) {
      return null;
    }
  }

  /// Format address to hide plus codes (e.g. "F9FJ+GQF,") and pin codes,
  /// showing only locality and state (e.g. "Devala, Tamil Nadu").
  String _formatAddress(String? address) {
    if (address == null) return '';
    final trimmed = address.trim();
    if (trimmed.isEmpty) return '';

    // Split by comma into parts
    final rawParts = trimmed.split(',');
    final parts = rawParts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return trimmed;

    // Detect and skip leading plus code part like "F9FJ+GQF"
    final plusCodeRegex = RegExp(r'^[A-Z0-9+]{4,}$');
    int startIndex = 0;
    if (plusCodeRegex.hasMatch(parts.first)) {
      startIndex = 1;
    }

    if (startIndex >= parts.length) {
      return parts.last;
    }

    // Locality (e.g. "Devala")
    final locality = parts[startIndex];

    // State part (e.g. "Tamil Nadu 643270" -> "Tamil Nadu")
    String? statePart;
    if (startIndex + 1 < parts.length) {
      statePart = parts[startIndex + 1];
      // Drop trailing pin code / numbers from state part
      statePart = statePart.replaceFirst(RegExp(r'\s*\d.*$'), '').trim();
    }

    if (statePart == null || statePart.isEmpty) {
      return locality;
    }

    return '$locality, $statePart';
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return 'Unknown times';
    }

    try {
      final timestampDate = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(timestampDate);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
      } else {
        final days = difference.inDays;
        return '$days ${days == 1 ? 'day' : 'days'} ago';
      }
    } catch (e) {
      return 'Invalid time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: injector<HomepageBloc>()
        ..add(GetHomepageData()), // Will get from SharedPreferences
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Stack(
          children: [
            // Layer 1: Map Background
            Positioned.fill(
              child: _HomeMapBackground(loadCustomMarker: _loadCustomMarker),
            ),

            // Layer 2: Top Bar Actions (Settings, etc.)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: InkWell(
                onTap: () {
                  // Add back navigation if needed or menu
                },
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsView()),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(
                    0.6,
                  ), // Standard map button style
                  child: const Icon(Icons.settings, color: Colors.white),
                ),
              ),
            ),

            // Layer 3: Draggable Bottom Sheet
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.4,
              minChildSize: 0.2, // Small enough to show map
              maxChildSize: 0.85,
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(), // Smooth feel
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.paddingL),
                      child: Column(
                        children: [
                          // Drag Handle
                          Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          _buildChildLocationCardContent(context),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // First View: Child Location Info Card Content
  Widget _buildChildLocationCardContent(BuildContext context) {
    return BlocBuilder<HomepageBloc, HomepageState>(
      builder: (context, state) {
        if (state is HomepageError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${state.message}',
                  style: AppTextStyles.body1.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: AppSizes.spacingM),
                CommonButton(
                  text: 'Retry',
                  onPressed: () {
                    injector<HomepageBloc>().add(GetHomepageData());
                  },
                ),
              ],
            ),
          );
        }

        if (state is! HomepageSuccess) {
          // Show simplified loading or placeholder
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Show "no child connected" UI
        if (state.hasNoChild) {
          return _buildNoChildConnectedUI(context);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
              if (state.isLoading) const SizedBox(height: AppSizes.spacingS),
              // Title and Save Place button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final matchingPlace = _findMatchingPlace(
                              state.currentLocation?.lat,
                              state.currentLocation?.lng,
                            );

                            return Text(
                              matchingPlace != null
                                  ? matchingPlace.name
                                  : _formatAddress(
                                      state.currentLocation?.address,
                                    ),
                              style: AppTextStyles.headline3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.spacingXS),
                        Text(
                          _formatTimeAgo(state.currentLocation?.since),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Save Place button (only show if NO matching place)
                  if (_findMatchingPlace(
                        state.currentLocation?.lat,
                        state.currentLocation?.lng,
                      ) ==
                      null)
                    OutlinedButton.icon(
                      onPressed: () {
                        _showSavePlaceDialog(
                          context,
                          LatLng(
                            state.currentLocation?.lat ?? 0,
                            state.currentLocation?.lng ?? 0,
                          ),
                          state.currentLocation?.address ?? '',
                        ).then((_) => _loadSavedPlaces());
                      },
                      icon: const Icon(
                        Icons.bookmark,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      label: Text('save place', style: AppTextStyles.caption),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.transparent),
                        backgroundColor: AppColors.containerBackground,

                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingM,
                          vertical: AppSizes.paddingS,
                        ),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingM),

              // Device status indicators
              Row(
                children: [
                  // Battery
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingXS,
                      vertical: AppSizes.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.battery_full,
                          color: AppColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: AppSizes.spacingXS),
                        Text(
                          '${state.deviceInfo?.batteryPercentage}%',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingS),
                  // Wi-Fi
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingS,
                      vertical: AppSizes.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi, color: AppColors.info, size: 16),
                        const SizedBox(width: AppSizes.spacingXS),
                        Text(
                          state.deviceInfo?.networkStatus.toUpperCase() ?? '',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingS),
                  // Sound
                  Builder(
                    builder: (context) {
                      final soundProfile =
                          state.deviceInfo?.soundProfile.toLowerCase() ?? '';

                      Color getColor() {
                        switch (soundProfile) {
                          case 'silent':
                            return AppColors.error;
                          case 'vibrate':
                            return AppColors.warning;
                          default:
                            return AppColors.success;
                        }
                      }

                      IconData getIcon() {
                        switch (soundProfile) {
                          case 'silent':
                            return Icons.volume_off;
                          case 'vibrate':
                            return Icons.vibration;
                          default:
                            return Icons.volume_up;
                        }
                      }

                      final color = getColor();
                      final icon = getIcon();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingS,
                          vertical: AppSizes.paddingXS,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 16),
                            const SizedBox(width: AppSizes.spacingXS),
                            Text(
                              state.deviceInfo?.soundProfile.toUpperCase() ??
                                  '',
                              style: AppTextStyles.overline.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingM),

              // Feature Cards Row
              Row(
                children: [
                  // Scroll card
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Scroll',
                      subtitle: 'Social Media &\nApp control',
                      icon: 'assets/home/scroll_girl.svg',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SocialAppsView(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingM),
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Geo Guard',
                      subtitle: 'Places &\nGeofencing',
                      icon: 'assets/home/geo_guard_girl.svg',
                      onTap: () {
                        // Feature implementation needed
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingM),

              // Infinite Real-Time Tracking Banner
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INFINITE REAL-TIME TRACKING',
                            style: AppTextStyles.subtitle2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacingXS),
                          Text(
                            'Unlimited Updated, just for you',
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CommonButton(
                      padding: EdgeInsets.zero,
                      height: 28,
                      width: 78,
                      fontSize: 10,
                      text: 'View all',
                      onPressed: () {
                        AppRouter.push(context, RouteNames.trips);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.spacingM),

              // Additional Details (can be navigated to)
              ListTile(
                tileColor: AppColors.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                leading: const Icon(
                  Icons.info_outline,
                  color: AppColors.textSecondary,
                ),
                title: const Text("View Full Location History"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChildLocationDetailView(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Feature Card Widget
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required String icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        padding: const EdgeInsets.only(
          left: AppSizes.paddingS,
          right: 0,
          top: AppSizes.paddingS,
          bottom: 0,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXS),
                Text(
                  textAlign: TextAlign.start,
                  subtitle,
                  maxLines: 2,
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),

                // Placeholder for illustration
              ],
            ),
            Spacer(),
            Container(
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                //borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: SvgPicture.asset(icon, width: 60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChildConnectedUI(BuildContext context) {
    // Keeping simple for now
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        children: [
          Icon(Icons.child_care, size: 60, color: Colors.grey),
          Text("No Child Connected", style: AppTextStyles.headline3),
          const SizedBox(height: 20),
          CommonButton(
            text: "Add Child",
            onPressed: () => Navigator.of(context).pushNamed('/add-child'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSavePlaceDialog(
    BuildContext context,
    LatLng location,
    String address,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SavePlaceOptionsDialog(),
    );

    if (result != null && mounted) {
      if (result == 'Custom Name') {
        _showCustomNameDialog(context, location, address);
      } else {
        _savePlace(context, result, location, address);
      }
    }
  }

  Future<void> _showCustomNameDialog(
    BuildContext context,
    LatLng location,
    String address,
  ) async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Custom Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'e.g., Grandma\'s House'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      _savePlace(context, result, location, address);
    }
  }

  Future<void> _savePlace(
    BuildContext context,
    String name,
    LatLng location,
    String address,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final place = SavedPlace(
      name: name,
      latitude: location.latitude,
      longitude: location.longitude,
      address: address,
      children: [], // Defaults to all children
    );

    try {
      final success = await injector<SavedPlacesService>().savePlace(place);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save place'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _SavePlaceOptionsDialog extends StatelessWidget {
  final List<String> options = ['Home', 'School', 'Tuition', 'Custom Name'];

  IconData _getOptionIcon(String option) {
    switch (option) {
      case 'Home':
        return Icons.home;
      case 'School':
        return Icons.school;
      case 'Tuition':
        return Icons.menu_book;
      case 'Custom Name':
        return Icons.edit_location_alt;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSizes.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Save Place As',
                    style: AppTextStyles.headline6.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  ...options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.spacingS),
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, option),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.paddingM,
                            horizontal: AppSizes.paddingM,
                          ),
                          backgroundColor: AppColors.surfaceColor.withValues(
                            alpha: 0.5,
                          ),
                          side: BorderSide(
                            color: AppColors.borderColor.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusM,
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getOptionIcon(option),
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: AppSizes.spacingM),
                            Text(
                              option,
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeMapBackground extends StatefulWidget {
  final Future<BitmapDescriptor?> Function(int) loadCustomMarker;

  const _HomeMapBackground({required this.loadCustomMarker});

  @override
  State<_HomeMapBackground> createState() => _HomeMapBackgroundState();
}

class _HomeMapBackgroundState extends State<_HomeMapBackground> {
  BitmapDescriptor? _cachedMarkerIcon;
  int? _cachedBatteryPercentage;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadMarkerIcon(int batteryPercentage) async {
    if (_cachedMarkerIcon != null &&
        _cachedBatteryPercentage == batteryPercentage) {
      return;
    }
    final icon = await widget.loadCustomMarker(batteryPercentage);
    if (!mounted) return;
    setState(() {
      _cachedMarkerIcon = icon;
      _cachedBatteryPercentage = batteryPercentage;
    });
  }

  void _animateTo(LatLng target) {
    if (_mapController == null) return;

    AppLogger.info("Moving camera to $target");
    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 15.0));
  }

  Future<void> _onParentLocationPressed() async {
    try {
      final locationService = injector<LocationService>();
      final permission = await locationService.requestPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await locationService.getCurrentPosition();
        if (position != null && mounted) {
          final latLng = LatLng(position.latitude, position.longitude);
          _animateTo(latLng);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required')),
          );
        }
      }
    } catch (e) {
      AppLogger.error("Error getting parent location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomepageBloc, HomepageState>(
      listenWhen: (prev, curr) {
        if (prev is HomepageSuccess && curr is HomepageSuccess) {
          final locChanged =
              prev.currentLocation?.lat != curr.currentLocation?.lat ||
              prev.currentLocation?.lng != curr.currentLocation?.lng;
          final batteryChanged =
              prev.deviceInfo?.batteryPercentage !=
              curr.deviceInfo?.batteryPercentage;
          return locChanged || batteryChanged;
        }
        return prev.runtimeType != curr.runtimeType;
      },
      listener: (context, state) {
        if (state is HomepageSuccess && state.currentLocation != null) {
          final loc = LatLng(
            state.currentLocation!.lat,
            state.currentLocation!.lng,
          );

          // Load marker icon first
          final battery = state.deviceInfo?.batteryPercentage ?? 0;
          _loadMarkerIcon(battery);

          // Animate to location - always try to animate when location updates
          if (_mapController != null) {
            // Use a small delay to ensure map is ready
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && _mapController != null) {
                _animateTo(loc);
              }
            });
          }
        }
      },
      child: BlocBuilder<HomepageBloc, HomepageState>(
        buildWhen: (prev, curr) {
          // Always rebuild when state type changes
          if (prev.runtimeType != curr.runtimeType) {
            return true;
          }

          // For HomepageSuccess states, rebuild if location or battery changed
          if (prev is HomepageSuccess && curr is HomepageSuccess) {
            final locChanged =
                prev.currentLocation?.lat != curr.currentLocation?.lat ||
                prev.currentLocation?.lng != curr.currentLocation?.lng;
            final batteryChanged =
                prev.deviceInfo?.batteryPercentage !=
                curr.deviceInfo?.batteryPercentage;
            return locChanged || batteryChanged;
          }

          return false;
        },
        builder: (context, state) {
          final battery = state is HomepageSuccess && state.deviceInfo != null
              ? state.deviceInfo!.batteryPercentage
              : 0;
          final location =
              state is HomepageSuccess && state.currentLocation != null
              ? LatLng(state.currentLocation!.lat, state.currentLocation!.lng)
              : null;
          // Fire-and-forget load; widget will update when ready
          _loadMarkerIcon(battery);

          final markers = <Marker>{
            if (location != null) ...{
              if (_cachedMarkerIcon != null)
                Marker(
                  markerId: const MarkerId('child_location'),
                  position: location,
                  icon: _cachedMarkerIcon!,
                  anchor: const Offset(0.5, 1.0),
                )
              else
                Marker(
                  markerId: const MarkerId('child_location'),
                  position: location,
                ),
            },
          };

          return Stack(
            children: [
              MapViewWidget(
                key: const ValueKey('home_map_static'),
                width: double.infinity,
                height: double.infinity,
                interactive: true,
                currentPosition: location,
                markers: markers.toList(),
                myLocationEnabled: true,
                minZoom: 0.0,
                maxZoom: 20,
                myLocationButtonEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Animate to current location when map is created
                  if (location != null) {
                    // Use a small delay to ensure map is fully initialized
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted && _mapController != null) {
                        _animateTo(location);
                      }
                    });
                  }
                },
              ),
              Positioned(
                bottom: 250, // Moved up to clear bottom sheet (approx)
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'parent_location_fab',
                  onPressed: _onParentLocationPressed,
                  backgroundColor: AppColors.surfaceColor,
                  child: const Icon(
                    Icons.gps_fixed,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }
}
