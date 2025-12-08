import 'dart:ui' as ui;
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
    // Create a recorder and canvas
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Draw battery icon using CustomPainter approach
    // Battery icon: rectangle with rounded corners and a small rectangle on the right
    final double width = size;
    final double height = size * 0.6;
    final double cornerRadius = size * 0.1;
    final double terminalWidth = size * 0.15;
    final double terminalHeight = size * 0.3;

    // Main battery body
    final RRect batteryRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (size - height) / 2, width - terminalWidth, height),
      Radius.circular(cornerRadius),
    );

    // Battery terminal (right side)
    final RRect terminalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        width - terminalWidth,
        (size - terminalHeight) / 2,
        terminalWidth,
        terminalHeight,
      ),
      Radius.circular(cornerRadius * 0.5),
    );

    // Determine battery color based on percentage
    final Color batteryColor = batteryPercentage > 20
        ? AppColors.success
        : AppColors.error;

    // Draw battery outline
    final Paint batteryPaint = Paint()
      ..color = batteryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08;

    canvas.drawRRect(batteryRect, batteryPaint);
    canvas.drawRRect(terminalRect, batteryPaint);

    // Fill battery (representing charge level from API)
    final Paint fillPaint = Paint()
      ..color = batteryColor
      ..style = PaintingStyle.fill;

    // Clamp battery percentage between 0 and 100
    final double clampedPercentage = batteryPercentage.clamp(0, 100) / 100;
    final double fillWidth = (width - terminalWidth) * clampedPercentage;
    final RRect fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (size - height) / 2, fillWidth, height),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(fillRect, fillPaint);

    // Convert to image
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    // Clean up
    picture.dispose();
    image.dispose();

    if (byteData == null) {
      throw Exception('Failed to create battery icon bytes');
    }

    return byteData.buffer.asUint8List();
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
        180,
      );

      // Create battery icon with dynamic battery percentage
      Uint8List batteryIconBytes;
      try {
        batteryIconBytes = await _createBatteryIconBytes(80, batteryPercentage);
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
        ..add(GetHomepageData(childId: '6905a34dc1ddbf66b31a77e9')),
      child: BlocBuilder<HomepageBloc, HomepageState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Stack(
              children: [
                // Loading overlay
                if (state is HomepageSuccess && state.isLoading)
                  Container(
                    color: AppColors.backgroundColor.withValues(alpha: 0.7),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
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
                            MaterialPageRoute(
                              builder: (_) => const SettingsView(),
                            ),
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _MapViewWithMarker(
                          location:
                              state is HomepageSuccess &&
                                  state.currentLocation != null
                              ? LatLng(
                                  state.currentLocation!.lat,
                                  state.currentLocation!.lng,
                                )
                              : const LatLng(
                                  13.082680,
                                  80.270721,
                                ), // Fallback to default location
                          batteryPercentage:
                              state is HomepageSuccess &&
                                  state.deviceInfo != null
                              ? state.deviceInfo!.batteryPercentage
                              : 0,
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
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.3,
                              ),
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
          );
        },
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
                      GetHomepageData(childId: '6905a34dc1ddbf66b31a77e9'),
                    );
                  },
                ),
              ],
            ),
          );
        }

        if (state is! HomepageSuccess || state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          'Since ${state.currentLocation?.since} (${state.currentLocation?.durationMinutes ?? 0} min)',
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
                      onPressed: () {},
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
}

// Separate widget for map view with marker loading
class _MapViewWithMarker extends StatelessWidget {
  final LatLng location;
  final int batteryPercentage;
  final Future<BitmapDescriptor?> Function(int) loadCustomMarker;

  const _MapViewWithMarker({
    required this.location,
    required this.batteryPercentage,
    required this.loadCustomMarker,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BitmapDescriptor?>(
      future: loadCustomMarker(batteryPercentage),
      builder: (context, snapshot) {
        final List<Marker> markers = [];

        if (snapshot.hasData && snapshot.data != null) {
          // Use custom marker icon
          markers.add(
            Marker(
              markerId: MarkerId(
                'child_location_custom_${snapshot.data.hashCode}',
              ),
              position: location,
              icon: snapshot.data!,
              anchor: const Offset(0.5, 1.0), // Bottom center
            ),
          );
        } else {
          // Fallback to default marker while icon is loading
          markers.add(
            Marker(
              markerId: const MarkerId('child_location_default'),
              position: location,
            ),
          );
        }

        return MapViewWidget(
          key: ValueKey(
            'map_${snapshot.hasData}_${snapshot.data?.hashCode ?? 0}',
          ),
          width: double.infinity,
          height: double.infinity,
          interactive: true,
          currentPosition: location,
          markers: markers,
          onMapCreated: (controller) {
            // Focus on marker with animation
            Future.delayed(const Duration(milliseconds: 100), () {
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(location, 15.0),
              );
            });
          },
        );
      },
    );
  }
}
