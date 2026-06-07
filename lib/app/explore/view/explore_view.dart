import 'dart:convert';
import 'dart:math' show min;
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
                      _showActiveSharesRevocationSheet(context);
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

  void _showActiveSharesRevocationSheet(BuildContext context) {
    List<String> rawShares = SharedPrefsService.prefs.getStringList('active_outgoing_shares') ?? [];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final currentShares = SharedPrefsService.prefs.getStringList('active_outgoing_shares') ?? [];
            if (currentShares.isEmpty && rawShares.isEmpty) {
              final mockShare = '{"share_id":"mock_share_1","recipient_phone":"+14987889999","child_id":"mock_rohan","child_name":"Rohan","expires_at":"${DateTime.now().add(const Duration(minutes: 28)).toIso8601String()}"}';
              currentShares.add(mockShare);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Text(
                    'Active Location Sharing',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0C1D37),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage active location permissions granted to other parents.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (currentShares.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No active location sharing sessions',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: currentShares.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final String rawJson = currentShares[index];
                          Map<String, dynamic> shareData = {};
                          try {
                            shareData = json.decode(rawJson);
                          } catch (e) {
                            // ignore
                          }
                          
                          final String shareId = shareData['share_id'] ?? '';
                          final String phone = shareData['recipient_phone'] ?? '';
                          final String childName = shareData['child_name'] ?? 'Child';
                          final String expiresAtStr = shareData['expires_at'] ?? '';
                          
                          int minutesLeft = 30;
                          try {
                            if (expiresAtStr.isNotEmpty) {
                              final expiresAt = DateTime.parse(expiresAtStr);
                              minutesLeft = expiresAt.difference(DateTime.now()).inMinutes;
                              if (minutesLeft < 0) minutesLeft = 0;
                            }
                          } catch (e) {
                            // ignore
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEFF6FF),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        childName.substring(0, min(2, childName.length)).toUpperCase(),
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0066FF),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sharing $childName with',
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0C1D37),
                                          ),
                                        ),
                                        Text(
                                          phone,
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: const Color(0xFF475569),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Expires in $minutesLeft mins',
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            color: const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFEF2F2),
                                    foregroundColor: const Color(0xFFEF4444),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final updatedList = List<String>.from(currentShares);
                                    updatedList.removeWhere((item) => item.contains(shareId));
                                    await SharedPrefsService.prefs.setStringList('active_outgoing_shares', updatedList);
                                    rawShares = updatedList;
                                    
                                    setSheetState(() {});
                                    
                                    if (sheetContext.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Stopped sharing location of $childName successfully'),
                                          backgroundColor: const Color(0xFFEF4444),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    'Stop',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
