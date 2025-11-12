import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/services/location_service.dart';
import 'package:flutter_svg/svg.dart';
import '../../settings/view/settings_view.dart';
import '../../social_apps/view/social_apps_view.dart';
import 'trips_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Show bottom sheet after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStickyBottomSheet(context);
    });
  }

  void _showStickyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
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
                Container(
                  margin: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.paddingL),
                      child: _buildChildLocationCardContent(context),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
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
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsView()),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Naidu'),
              background: const MapSection(),
            ),
          ),

          // Main content with collapsing effect
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Second View: Trip Today Card
                _buildTripTodayCard(context),

                // Activity Today Card
                _buildActivityTodayCard(),

                // Screentime Card
                _buildScreentimeCard(context),

                // Infinite Real-Time Tracking Card
                _buildInfiniteTrackingCard(),

                const SizedBox(height: AppSizes.spacingXL),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // First View: Child Location Info Card Content
  Widget _buildChildLocationCardContent(BuildContext context) {
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
                      'Kid at School',

                      style: AppTextStyles.headline3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      'Since 09:30am (02:00hours)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Save Place button
              OutlinedButton.icon(
                
                onPressed: () {},
                icon: const Icon(Icons.bookmark, size: 16,color: AppColors.textSecondary,),
                label:  Text('save place',style: AppTextStyles.caption,),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.transparent),
                  backgroundColor: AppColors.containerBackground,
                  
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
                  shape: RoundedRectangleBorder(
                  
                  side: BorderSide(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(
                    
                      AppSizes.radiusM,),
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
                      '90%',
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
                      'connected',
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
                      'Sound',
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
                    MaterialPageRoute(builder: (_) => const SocialAppsView()),
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
                CommonButton(padding: 
                EdgeInsets.zero,
                  height:  28,
                  width: 78,
                  fontSize: 10,
                  text: 'View all', onPressed: () {},)
              ],
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.only(left: AppSizes.paddingS,right: 0,top: AppSizes.paddingS,bottom: 0),
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
                alignment:Alignment.bottomCenter,
                  decoration: BoxDecoration(
                    //borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: SvgPicture.asset(icon,width: 60,),
                ),
          ],
        ),
      ),
    );
  }

  // Trip Today Card
  Widget _buildTripTodayCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip today',
            style: AppTextStyles.headline6.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            '08:43 am - 21:20 pm (12hrs)',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            'Kamakshi Palaya - Cubbon Park',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingS,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text('4 Events', style: AppTextStyles.caption),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingS,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  'today',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              CommonButton(
                
                text: 'View all',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TripsView()),
                ),
                height: 36,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Activity Today Card
  Widget _buildActivityTodayCard() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingL),
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity today',
            style: AppTextStyles.headline6.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Row(
            children: [
              // Activity metrics
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActivityMetric('241', 'Steps'),
                    const SizedBox(height: AppSizes.spacingS),
                    _buildActivityMetric('03.1 km', 'walking'),
                    const SizedBox(height: AppSizes.spacingS),
                    _buildActivityMetric('26.6 km', 'entire route'),
                    const SizedBox(height: AppSizes.spacingS),
                    _buildActivityMetric('65 km/h', 'maxi speed'),
                  ],
                ),
              ),
              // Progress indicator
              Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: 0.3,
                            strokeWidth: 8,
                            backgroundColor: AppColors.borderColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor,
                            ),
                          ),
                        ),
                        Text(
                          '30%',
                          style: AppTextStyles.subtitle1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXS),
                  Text(
                    'more distance walked than last day',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            'Track your child\'s weekly progress and get personalized growth tips!',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                  vertical: AppSizes.paddingS,
                ),
              ),
              child: const Text('View all'),
            ),
          ),
        ],
      ),
    );
  }

  // Activity Metric Widget
  Widget _buildActivityMetric(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: AppTextStyles.subtitle1.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: AppSizes.spacingXS),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // Screentime Card
  Widget _buildScreentimeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: const Icon(
              Icons.grid_view,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2.3hrs of screentime',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXS),
                Row(
                  children: [
                    // App icons placeholder
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingXS),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingXS),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingXS),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingXS),
                    Text(
                      'and more yesterday',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CommonButton(
            text: 'View all',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SocialAppsView()),
            ),
            height: 36,
          ),
        ],
      ),
    );
  }

  // Infinite Real-Time Tracking Card (Bottom)
  Widget _buildInfiniteTrackingCard() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingL),
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFINITE REAL-TIME TRACKING',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    4,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSizes.spacingXS,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: AppSizes.spacingXS),
                          Text(
                            'Unlimited Updated, just for you',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Gift box placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AppColors.primaryColor,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Map Section Widget with Google Maps
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

          // Child's profile picture in top right
          Positioned(
            top: AppSizes.paddingL,
            right: AppSizes.paddingL,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const CircleAvatar(
                backgroundColor: AppColors.surfaceColor,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: AppColors.primaryColor,
                ),
              ),
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
