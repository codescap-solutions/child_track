import 'package:child_track/app/map/view/map_view.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:flutter_svg/svg.dart';
import '../../settings/view/settings_view.dart';
import '../../social_apps/view/social_apps_view.dart';
import 'child_location_detail_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStickyBottomSheet(context);
    });
  }

  //

  void _showStickyBottomSheet(BuildContext context) {
    final ValueNotifier<bool> hasNavigated = ValueNotifier<bool>(false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              // Detect when sheet is dragged/scrolled significantly
              // Navigate when sheet size is above 0.7 (70% of screen)
              if (notification.extent > 0.7 && !hasNavigated.value) {
                hasNavigated.value = true;
                Navigator.of(context).pop(); // Close bottom sheet
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChildLocationDetailView(),
                  ),
                );
                return true;
              }
              return false;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              builder: (context, sheetScrollController) {
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
                      GestureDetector(
                        onTap: () {
                          // Navigate when drag handle is tapped
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChildLocationDetailView(),
                            ),
                          );
                        },
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
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            // Navigate when user scrolls down significantly
                            if (notification is ScrollUpdateNotification) {
                              if (notification.metrics.pixels > 200 &&
                                  !hasNavigated.value) {
                                hasNavigated.value = true;
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ChildLocationDetailView(),
                                  ),
                                );
                                return true;
                              }
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            controller: sheetScrollController,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSizes.paddingL,
                              ),
                              child: _buildChildLocationCardContent(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
                icon: CircleAvatar(
                  backgroundColor: AppColors.surfaceColor,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.primaryColor,
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsView()),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(''),

              // background: const MapSection(),
              background: const MapViewWidget(width: 400, height: 500),
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
