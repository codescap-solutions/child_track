import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
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
              background: _buildMapSection(context),
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

  // Map section with beach-sand colored container placeholder
  Widget _buildMapSection(BuildContext context) {
    return Container(
      color: AppColors.beach,
      child: Stack(
        children: [
          // Map placeholder - beach colored container
          Positioned.fill(child: Container(color: AppColors.beach)),

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

          // Location pin placeholder (red marker)
          Positioned(
            bottom: 100,
            left: MediaQuery.of(context).size.width * 0.4,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceColor, width: 2),
              ),
              child: const Icon(
                Icons.place,
                color: AppColors.surfaceColor,
                size: 24,
              ),
            ),
          ),

          // Map controls at bottom
          Positioned(
            bottom: AppSizes.paddingM,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(width: AppSizes.spacingM),
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
                    Icons.my_location,
                    color: AppColors.textSecondary,
                  ),
                ),
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
