import 'dart:ui' as ui;
import 'package:child_track/core/navigation/app_router.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:flutter/services.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_bloc.dart';
import 'package:child_track/app/map/view/map_view.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../settings/view/settings_view.dart';
import '../../social_apps/view/social_apps_view.dart';
import '../../addplace/add_and_saveplace.dart';
import 'child_location_detail_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _bottomSheetScrollController = ScrollController();
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _bottomSheetScrollController.addListener(_onScroll);
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

  /// Create battery icon as image bytes using CustomPainter
  Future<Uint8List> _createBatteryIconBytes(
    double size,
    int batteryPercentage,
  ) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Responsive battery size
    final double width = size * 1; // FIXED: No more hard-coded 300
    final double height = size * 0.5;
    final double cornerRadius = size * 0.1;
    final double terminalWidth = size * 0.12;
    final double terminalHeight = size * 0.25;

    // Battery body
    final RRect batteryRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (size - height) / 2, width - terminalWidth, height),
      Radius.circular(cornerRadius),
    );

    // Battery terminal
    final RRect terminalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        width - terminalWidth,
        (size - terminalHeight) / 2,
        terminalWidth,
        terminalHeight,
      ),
      Radius.circular(cornerRadius * 0.5),
    );

    // Colors
    final Color batteryColor = batteryPercentage > 20
        ? AppColors.success
        : AppColors.error;

    // Outline
    final Paint batteryPaint = Paint()
      ..color = batteryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.06;

    canvas.drawRRect(batteryRect, batteryPaint);
    canvas.drawRRect(terminalRect, batteryPaint);

    // Battery fill
    final Paint fillPaint = Paint()
      ..color = batteryColor
      ..style = PaintingStyle.fill;

    final double clampedPercentage = batteryPercentage.clamp(0, 100) / 100;

    final double fillWidth = (width - terminalWidth) * clampedPercentage;

    final RRect fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (size - height) / 2, fillWidth, height),
      Radius.circular(cornerRadius),
    );

    canvas.drawRRect(fillRect, fillPaint);

    // Convert to image — keep a proper aspect
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width.toInt(), size.toInt());

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    picture.dispose();
    image.dispose();

    return byteData!.buffer.asUint8List();
  }

  /// Composite marker image with battery icon
  Future<Uint8List> _compositeMarkerWithBattery(
    Uint8List markerBytes,
    Uint8List batteryBytes,
  ) async {
    // Decode marker image
    final ui.Codec markerCodec = await ui.instantiateImageCodec(markerBytes);
    final ui.FrameInfo markerFrame = await markerCodec.getNextFrame();
    final ui.Image markerImage = markerFrame.image;

    // Decode battery icon
    final ui.Codec batteryCodec = await ui.instantiateImageCodec(batteryBytes);
    final ui.FrameInfo batteryFrame = await batteryCodec.getNextFrame();
    final ui.Image batteryImage = batteryFrame.image;

    // Create a canvas to composite the images
    final int markerWidth = markerImage.width;
    final int markerHeight = markerImage.height;
    final int batterySize = (markerWidth * 0.3)
        .round(); // Battery icon is 30% of marker size

    // Create a recorder and canvas
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Draw the main marker image
    canvas.drawImage(markerImage, Offset.zero, Paint());

    // Draw the battery icon in the top-right corner
    // Position it with some padding from the edges
    final double batteryX = markerWidth - batterySize - (markerWidth * 0.05);
    final double batteryY = markerWidth * 0.05;

    // Resize battery image if needed
    ui.Image resizedBattery = batteryImage;
    if (batteryImage.width != batterySize) {
      final ui.Codec resizedCodec = await ui.instantiateImageCodec(
        batteryBytes,
        targetWidth: batterySize,
      );
      final ui.FrameInfo resizedFrame = await resizedCodec.getNextFrame();
      resizedBattery = resizedFrame.image;
    }

    canvas.drawImage(resizedBattery, Offset(batteryX, batteryY), Paint());

    // Convert canvas to image
    final ui.Picture picture = recorder.endRecording();
    final ui.Image compositeImage = await picture.toImage(
      markerWidth,
      markerHeight,
    );

    // Convert to bytes
    final ByteData? byteData = await compositeImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    // Dispose images to free memory
    markerImage.dispose();
    batteryImage.dispose();
    if (resizedBattery != batteryImage) {
      resizedBattery.dispose();
    }
    compositeImage.dispose();

    return byteData!.buffer.asUint8List();
  }

  Future<BitmapDescriptor?> _loadCustomMarker(int batteryPercentage) async {
    try {
      // Load main marker image
      final Uint8List markerIconBytes = await _getBytesFromAsset(
        'assets/images/images.png',
        250,
      );

      // Create battery icon with dynamic battery percentage
      Uint8List batteryIconBytes;
      try {
        batteryIconBytes = await _createBatteryIconBytes(
          300,
          batteryPercentage,
        );
      } catch (e) {
        // Fallback: use marker without battery
        return BitmapDescriptor.bytes(markerIconBytes);
      }

      // Composite the images
      final Uint8List compositeBytes = await _compositeMarkerWithBattery(
        markerIconBytes,
        batteryIconBytes,
      );

      return BitmapDescriptor.bytes(compositeBytes);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _bottomSheetScrollController.removeListener(_onScroll);
    _bottomSheetScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Navigate when scroll reaches the end
    if (_bottomSheetScrollController.hasClients && !_hasNavigated) {
      final maxScroll = _bottomSheetScrollController.position.maxScrollExtent;
      final currentScroll = _bottomSheetScrollController.offset;

      // Check if scrolled to the end (with a small threshold for better UX)
      if (currentScroll >= maxScroll - 10) {
        _hasNavigated = true;
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => const ChildLocationDetailView(),
              ),
            )
            .then((_) {
              // Reset flag when returning from detail view
              if (mounted) {
                _hasNavigated = false;
              }
            });
      }
    }
  }

  void _navigateToDetail() {
    if (!_hasNavigated) {
      _hasNavigated = true;
      Navigator.of(context)
          .push(
            MaterialPageRoute(builder: (_) => const ChildLocationDetailView()),
          )
          .then((_) {
            // Reset flag when returning from detail view
            if (mounted) {
              _hasNavigated = false;
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.4;
    return BlocProvider.value(
      value: injector<HomepageBloc>()
        ..add(
          GetHomepageData(),
        ), // Will get from SharedPreferences
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // App Bar with collapsing effect
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.7,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.surfaceColor,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  actions: [
                    IconButton(
                      icon: CircleAvatar(
                        backgroundColor: AppColors.surfaceColor,
                        child: Icon(Icons.person, color: AppColors.success),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsView()),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _HomeMapBackground(
                      defaultLocation: const LatLng(13.082680, 80.270721),
                      loadCustomMarker: _loadCustomMarker,
                    ),
                  ),
                ),
              ],
            ),
            // Bottom sheet container
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: bottomSheetHeight,
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusXL),
                    topRight: Radius.circular(AppSizes.radiusXL),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    GestureDetector(
                      onTap: _navigateToDetail,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: AppSizes.spacingS,
                        ),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _bottomSheetScrollController,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSizes.paddingL,
                          ),
                          child: _buildChildLocationCardContent(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                    context.read<HomepageBloc>().add(
                      GetHomepageData(),
                    );
                  },
                ),
              ],
            ),
          );
        }

        if (state is! HomepageSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show "no child connected" UI
        if (state.hasNoChild) {
          return _buildNoChildConnectedUI(context);
        }

        return Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
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
                        Text(
                          '${state.currentLocation?.placeName} at ${state.currentLocation?.address}',
                          style: AppTextStyles.headline3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                  // Save Place button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddandSavePlace(
                            initialLocation: LatLng(
                              state.currentLocation?.lat ?? 0,
                              state.currentLocation?.lng ?? 0,
                            ),
                          ),
                        ),
                      );
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingS,
                      vertical: AppSizes.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.volume_up,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: AppSizes.spacingXS),
                        Text(
                          state.deviceInfo?.soundProfile.toUpperCase() ?? '',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  // Action icons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.share_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingM),

              // Feature Cards Row
              Row(
                children: [
                  // Geo Guard card

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
                      onTap: () {},
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

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return 'Unknown time';
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

  Widget _buildNoChildConnectedUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
              ),
              child: const Icon(
                Icons.child_care_outlined,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXL),
            Text(
              'Child Not Connected',
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              'Please connect and add a matched child to view tracking information.',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingXL),
            CommonButton(
              text: 'Add Child',
              onPressed: () {
                // Navigate to add child screen or connect screen
                Navigator.of(context).pushNamed('/add-child');
              },
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dedicated map background that avoids full-page rebuilds and flicker.
class _HomeMapBackground extends StatefulWidget {
  final LatLng defaultLocation;
  final Future<BitmapDescriptor?> Function(int) loadCustomMarker;

  const _HomeMapBackground({
    required this.defaultLocation,
    required this.loadCustomMarker,
  });

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
    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 15.0));
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
        if (state is HomepageSuccess) {
          final loc = state.currentLocation != null
              ? LatLng(state.currentLocation!.lat, state.currentLocation!.lng)
              : widget.defaultLocation;
          _animateTo(loc);
          final battery = state.deviceInfo?.batteryPercentage ?? 0;
          _loadMarkerIcon(battery);
        }
      },
      child: BlocBuilder<HomepageBloc, HomepageState>(
        buildWhen: (prev, curr) {
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
        builder: (context, state) {
          final battery = state is HomepageSuccess && state.deviceInfo != null
              ? state.deviceInfo!.batteryPercentage
              : 0;
          final location =
              state is HomepageSuccess && state.currentLocation != null
              ? LatLng(state.currentLocation!.lat, state.currentLocation!.lng)
              : widget.defaultLocation;
          // Fire-and-forget load; widget will update when ready
          _loadMarkerIcon(battery);

          final markers = <Marker>{
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
          };

          return MapViewWidget(
            key: const ValueKey('home_map_static'),
            width: double.infinity,
            height: double.infinity,
            interactive: true,
            currentPosition: location,
            markers: markers.toList(),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _animateTo(location);
            },
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
