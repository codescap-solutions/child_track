import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/app/home/view/trips_view.dart';
import 'package:child_track/app/geofencing/view/geo_fencing_view.dart';
import 'package:child_track/app/social_apps/view/social_apps_view.dart';
import 'package:child_track/app/settings/view/subscription_view.dart';
import 'package:child_track/core/utils/app_snackbar.dart';

class ExploreView extends StatelessWidget {
  final VoidCallback onNavigateToHome;

  const ExploreView({
    super.key,
    required this.onNavigateToHome,
  });

  @override
  Widget build(BuildContext context) {
    final sharedPrefsService = injector<SharedPrefsService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Off-white background matching mockup
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leadingWidth: 72,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: GestureDetector(
              onTap: onNavigateToHome,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Explore',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0C1D37),
          ),
        ),
        actions: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.search,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // CARD 1: Core Parental Controls
              _buildSectionCard(
                children: [
                  _buildExploreItem(
                    icon: Icons.smartphone_outlined,
                    iconColor: const Color(0xFF3B82F6), // Blue
                    iconBgColor: const Color(0xFFEFF6FF), // Soft Blue
                    title: 'Scroll',
                    subtitle: "Contacts shown on kid's device",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SocialAppsView(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildExploreItem(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFF3B82F6), // Blue
                    iconBgColor: const Color(0xFFEFF6FF), // Soft Blue
                    title: 'Geofencing',
                    subtitle: 'Set virtual location boundaries',
                    onTap: () {
                      final childId = sharedPrefsService.getString('child_id');
                      final parentId = sharedPrefsService.getString('parent_id');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GeoFencingView(
                            childId: childId,
                            parentId: parentId,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildExploreItem(
                    icon: Icons.route_outlined,
                    iconColor: const Color(0xFFEF4444), // Red
                    iconBgColor: const Color(0xFFFEF2F2), // Soft Red
                    title: 'Route History',
                    subtitle: 'View past travel routes',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TripsView(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildExploreItem(
                    icon: Icons.gps_fixed_rounded,
                    iconColor: const Color(0xFFF97316), // Orange
                    iconBgColor: const Color(0xFFFFF7ED), // Soft Orange
                    title: 'Live Tracking',
                    subtitle: 'Real-time location updates',
                    onTap: onNavigateToHome,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // CARD 2: Additional Controls
              _buildSectionCard(
                children: [
                  _buildExploreItem(
                    icon: Icons.phone_in_talk_outlined,
                    iconColor: const Color(0xFF3B82F6), // Blue
                    iconBgColor: const Color(0xFFEFF6FF), // Soft Blue
                    title: 'Parents Contact',
                    subtitle: "Contact displayed in kid's device",
                    onTap: () {
                      AppSnackbar.showInfo(
                        context,
                        'Parents Contact configuration coming soon',
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildExploreItem(
                    icon: Icons.send_outlined,
                    iconColor: const Color(0xFF3B82F6), // Blue
                    iconBgColor: const Color(0xFFEFF6FF), // Soft Blue
                    title: 'Request Tracking',
                    subtitle: 'Tracking permission of others',
                    onTap: () {
                      AppSnackbar.showInfo(
                        context,
                        'Request Tracking permission coming soon',
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildExploreItem(
                    icon: Icons.monitor_heart_outlined,
                    iconColor: const Color(0xFFEF4444), // Red
                    iconBgColor: const Color(0xFFFEF2F2), // Soft Red
                    title: 'Emergency Contact',
                    subtitle: 'People related to kid',
                    onTap: () {
                      AppSnackbar.showInfo(
                        context,
                        'Emergency Contacts coming soon',
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildExploreItem(
                    icon: Icons.credit_card_outlined,
                    iconColor: const Color(0xFFF97316), // Orange
                    iconBgColor: const Color(0xFFFFF7ED), // Soft Orange
                    title: 'Subscription',
                    subtitle: 'Your plan details',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionView(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1D37).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildExploreItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0C1D37),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFFCBD5E1),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: Color(0xFFF1F5F9),
      indent: 72,
      endIndent: 16,
    );
  }
}
