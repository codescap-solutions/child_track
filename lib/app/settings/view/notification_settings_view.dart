import 'package:flutter/cupertino.dart' show CupertinoSwitch, CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  final _sharedPrefsService = SharedPrefsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Off-white background matching Settings
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leadingWidth: 56,
        leading: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
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
          'Notification Settings',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0C1D37),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // 1. Movements
              _buildSectionHeader("MOVEMENTS"),
              _buildSectionCard(
                children: [
                  _buildNotificationTile('Entering a Place'),
                  _buildDivider(),
                  _buildNotificationTile('Leaving a Place'),
                  _buildDivider(),
                  _buildNotificationTile('New Place'),
                  _buildDivider(),
                  _buildNotificationTile('Starting Trip'),
                  _buildDivider(),
                  _buildNotificationTile('Route Deviation'),
                  _buildDivider(),
                  _buildNotificationTile('Estimated arrival at a place'),
                  _buildDivider(),
                  _buildNotificationTile('Movement speed'),
                  _buildDivider(),
                  _buildNotificationTile('Geofences Boundary Alerts'),
                  _buildDivider(),
                  _buildNotificationTile('Route Deviation Warning'),
                  _buildDivider(),
                  _buildNotificationTile('Unusual Stop Detection'),
                ],
              ),

              // 2. Device & App Health Alerts
              _buildSectionHeader("DEVICE & APP HEALTH ALERTS"),
              _buildSectionCard(
                children: [
                  _buildNotificationTile('Low Battery Notification'),
                  _buildDivider(),
                  _buildNotificationTile('Signal Loss/GPS Offline Alert'),
                  _buildDivider(),
                  _buildNotificationTile('Device Tampering Alert'),
                  _buildDivider(),
                  _buildNotificationTile('Connectivity Loss Alert'),
                  _buildDivider(),
                  _buildNotificationTile('App Status Alert'),
                ],
              ),

              // 3. Communication Alerts
              _buildSectionHeader("COMMUNICATION ALERTS"),
              _buildSectionCard(
                children: [
                  _buildNotificationTile('New Message Notification'),
                  _buildDivider(),
                  _buildNotificationTile('Missed Communication Alert'),
                  _buildDivider(),
                  _buildNotificationTile('Scheduled School Delivery'),
                  _buildDivider(),
                  _buildNotificationTile('Manual Whistle Clock'),
                ],
              ),

              // 4. Health, Activity & Wellness
              _buildSectionHeader("HEALTH, ACTIVITY & WELLNESS"),
              _buildSectionCard(
                children: [
                  _buildNotificationTile('Daily Step Count Report'),
                  _buildDivider(),
                  _buildNotificationTile('Prolonged Inactivity Alert'),
                ],
              ),

              // 5. Daily/Weekly
              _buildSectionHeader("DAILY/WEEKLY"),
              _buildSectionCard(
                children: [
                  _buildNotificationTile('Daily Movement Summary'),
                  _buildDivider(),
                  _buildNotificationTile('Weekly Safety & Activity Report'),
                  _buildDivider(),
                  _buildNotificationTile('Real-time Accurate Notification'),
                  _buildDivider(),
                  _buildNotificationTile('Weather Report'),
                ],
              ),

              // 6. Family & App Usage
              _buildSectionHeader("FAMILY & APP USAGE"),
              _buildSectionCard(
                children: [
                  _buildNotificationTile('New Family Member Alert'),
                  _buildDivider(),
                  _buildNotificationTile('App Updates/Reminder Alert'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 0, bottom: 8, top: 18),
        child: Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1.0,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1D37).withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNotificationTile(String title) {
    final String key =
        'notif_${title.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_').replaceAll('&', '_')}';
    final bool value = _sharedPrefsService.getBool(key, defaultValue: true);

    return InkWell(
      onTap: () {
        final newValue = !value;
        _sharedPrefsService.setBool(key, newValue);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0C1D37),
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: CupertinoSwitch(
                activeTrackColor: const Color(0xFF22C55E),
                value: value,
                onChanged: (newValue) async {
                  await _sharedPrefsService.setBool(key, newValue);
                  setState(() {});
                },
              ),
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
      indent: 16,
      endIndent: 16,
    );
  }
}
