import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';

/// Trip Detail View - Shows detailed trip with map and timeline
class TripDetailView extends StatelessWidget {
  const TripDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Map Section (Full screen)
          _buildMapSection(context),

          // Bottom Sheet with Trip Timeline
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.8,
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
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSizes.spacingM,
                      ),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Trip Time Range
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingL,
                      ),
                      child: Text(
                        '08:43 am - 09:20 am',
                        style: AppTextStyles.headline6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingL),

                    // Trip Timeline
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingL,
                        ),
                        children: [
                          _buildTimelineItem(
                            icon: Icons.home,
                            title: 'Home',
                            time: '08:49',
                            color: AppColors.primaryColor,
                          ),
                          _buildTimelineItem(
                            icon: Icons.directions_bus,
                            title: 'Ride',
                            subtitle: '6.4km (37min)',
                            time: null,
                            badge: 'max speed - 24.5 kmp',
                            color: AppColors.info,
                          ),
                          _buildTimelineItem(
                            icon: Icons.school,
                            title: 'School',
                            time: '09:21',
                            color: AppColors.success,
                          ),
                          // Additional items for scroll demonstration
                          _buildTimelineItem(
                            icon: Icons.restaurant,
                            title: 'Lunch Break',
                            time: '12:30',
                            color: AppColors.warning,
                          ),
                          _buildTimelineItem(
                            icon: Icons.home,
                            title: 'Home',
                            time: '21:20',
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Map Section with beach-sand color placeholder (MAP-SCREEN RULE)
  Widget _buildMapSection(BuildContext context) {
    return Container(
      color: AppColors.beach,
      child: Stack(
        children: [
          // Base beach-sand colored container
          Positioned.fill(child: Container(color: AppColors.beach)),

          // App Bar Overlay
          SafeArea(
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: AppColors.textPrimary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: const Text(
                'Trips',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              centerTitle: true,
            ),
          ),

          // Map Controls (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSizes.paddingL,
            right: AppSizes.paddingL,
            child: Column(
              children: [
                // Map Layers Icon
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
                // Share Icon
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
                    Icons.share,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Purple Route Line
          Positioned(
            left: 80,
            right: 80,
            top: 200,
            bottom: 300,
            child: CustomPaint(painter: _RoutePainter(), child: Container()),
          ),

          // START Marker (Green with house icon)
          Positioned(
            left: 60,
            top: 200,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.home,
                    size: 20,
                    color: AppColors.surfaceColor,
                  ),
                  const SizedBox(width: AppSizes.spacingXS),
                  Text(
                    'START',
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.surfaceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FINISH Marker (Green with tree icon)
          Positioned(
            right: 60,
            bottom: 350,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.park,
                    size: 20,
                    color: AppColors.surfaceColor,
                  ),
                  const SizedBox(width: AppSizes.spacingXS),
                  Text(
                    'FINISH',
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.surfaceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location Labels (Placeholder)
          Positioned(
            left: AppSizes.paddingL,
            top: 150,
            child: _buildLocationLabel('RAJAJINAGAR'),
          ),
          Positioned(
            right: AppSizes.paddingL,
            top: 180,
            child: _buildLocationLabel('Bengaluru'),
          ),
          Positioned(
            left: AppSizes.paddingL,
            bottom: 400,
            child: _buildLocationLabel('HEBBAL'),
          ),
          Positioned(
            right: AppSizes.paddingL,
            bottom: 450,
            child: _buildLocationLabel('BANASHANKARI'),
          ),
        ],
      ),
    );
  }

  // Location Label Widget
  Widget _buildLocationLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingS,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  // Timeline Item Widget
  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? time,
    String? badge,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and icon
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(width: 2, height: 60, color: AppColors.borderColor),
            ],
          ),

          const SizedBox(width: AppSizes.spacingM),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSizes.spacingXS),
                            Text(
                              subtitle,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (badge != null) ...[
                            const SizedBox(height: AppSizes.spacingXS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingS,
                                vertical: AppSizes.paddingXS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusS,
                                ),
                              ),
                              child: Text(
                                badge,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (time != null)
                      Text(
                        time,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Route Line
class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.6,
      size.width,
      size.height * 0.8,
    );

    canvas.drawPath(path, paint);

    // Draw bus stop markers along route
    final markerPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final t = i / 5.0;
      final x = size.width * (0.2 + t * 0.6);
      final y = size.height * (0.3 + t * 0.5);
      canvas.drawCircle(Offset(x, y), 8, markerPaint);
      canvas.drawCircle(Offset(x, y), 8, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
