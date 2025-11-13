import 'package:child_track/app/home/view/trips_view.dart';
import 'package:child_track/app/home/view/widget/homemap.dart';
import 'package:child_track/app/home/view/widget/trip_route_map.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:flutter_svg/svg.dart';
import '../../social_apps/view/social_apps_view.dart';

class ChildLocationDetailView extends StatelessWidget {
  const ChildLocationDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Kid Location Details'),
      ),
      body: SingleChildScrollView(
        child:
         Column(
           children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: const TripRouteMap()),
             _buildChildLocationCardContent(context),
           ],
         ),
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
        Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Second View: Trip Today Card
              //  _buildTripTodayCard(context),
            
                // Activity Today Card
                _buildActivityTodayCard(),
                const SizedBox(height: AppSizes.spacingM),

                // Screentime Card
                _buildScreentimeCard(context),
                const SizedBox(height: AppSizes.spacingM),

                // Infinite Real-Time Tracking Card
                _buildInfiniteTrackingCard(),
            
                const SizedBox(height: AppSizes.spacingXL),
              ],
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
                  subtitle,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
              ],
            ),
            const Spacer(),
            Container(
              alignment: Alignment.bottomCenter,
              decoration: const BoxDecoration(),
              child: SvgPicture.asset(icon, width: 60),
            ),
          ],
        ),
      ),
    );
  }


 

  // Activity Today Card
  Widget _buildActivityTodayCard() {
    return Container(
      // margin: const EdgeInsets.all(AppSizes.paddingM),
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
                    Row(
                      children: [
                        _buildActivityMetric('241', 'Steps'),
                         const SizedBox(width: AppSizes.spacingS),
                    _buildActivityMetric('03.1 km', 'walking'),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    Row(
                      children: [
                    _buildActivityMetric('26.6 km', 'entire route'),
                         const SizedBox(width: AppSizes.spacingS),
                    _buildActivityMetric('65 km/h', 'maxi speed'),
                      ],
                    ),
                   
                    
                  ],
                ),
              ),
              // Progress indicator
             // Progress indicator
Expanded(
  flex: 1,
  child: Row(
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
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
      const SizedBox(width: AppSizes.spacingS),
      Expanded(
        child: Text(
          'more distance walked than last day',
          maxLines: 3,
          textAlign: TextAlign.start,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ],
  ),
),

            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          Divider(
            color: AppColors.borderColor,
            thickness: 1,
          ),
          Row(
            children: [
              Text(
                'Track your child\'s weekly progress\nand get personalized growth tips!',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                
              ),
              const Spacer(),
                Align(

            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 78,
              height:27,
              child: OutlinedButton(
                
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.textPrimary),
                  padding: const EdgeInsets.symmetric(
                
                  ),
                ),
                child:  Text('View all',style: AppTextStyles.caption,),
              ),
            ),
          ),
            ],
          ),
        
        ],
      ),
    );
  }

  // Activity Metric Widget
  Widget _buildActivityMetric(String value, String label) {
    return Column(
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
      // margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
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
          const SizedBox(width: AppSizes.spacingXS),
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
                    const SizedBox(width: 2),
                Row(
                  children: [
                    // App icons placeholder
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 15,
                      height: 15,
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
                    padding: EdgeInsets.zero,
                    width: 70,
                    text: 'View all',
                    fontSize: 12,
                    textColor: AppColors.surfaceColor,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TripsView()),
                    ),
                    height: 26,
                  ),
        ],
      ),
    );
  }

  // Infinite Real-Time Tracking Card (Bottom)
  Widget _buildInfiniteTrackingCard() {
    return Container(
      // margin: const EdgeInsets.all(AppSizes.paddingL),
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

