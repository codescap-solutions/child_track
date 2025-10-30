import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'widgets/section_card.dart';
import 'widgets/setting_tile.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        children: const [
          _Group(
            title: 'Movements',
            items: [
              'Entering a Place',
              'Leaving a Place',
              'New Place',
              'Starting Trip',
              'Route Deviation',
              'Estimated arrival at a place',
              'Movement speed',
              'Geofences Boundary Alerts',
              'Route Deviation Warning',
              'Unusual Stop Detection',
            ],
          ),
          _Group(
            title: 'Device & App Health Alerts',
            items: [
              'Low Battery Notification',
              'Signal Loss/GPS Offline Alert',
              'Device Tampering Alert',
              'Connectivity Loss Alert',
              'App Status Alert',
            ],
          ),
          _Group(
            title: 'Communication Alerts',
            items: [
              'New Message Notification',
              'Missed Communication Alert',
              'Scheduled School Delivery',
              'Manual Whistle Clock',
            ],
          ),
          _Group(
            title: 'Health, Activity & Wellness',
            items: ['Daily Step Count Report', 'Prolonged Inactivity Alert'],
          ),
          _Group(
            title: 'Daily/Weekly',
            items: [
              'Daily Movement Summary',
              'Weekly Safety & Activity Report',
              'Real-time Accurate Notification',
              'Weather Report',
            ],
          ),
          _Group(
            title: 'Family & App Usage',
            items: ['New Family Member Alert', 'App Updates/Reminder Alert'],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<String> items;
  const _Group({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ...items.map(
            (e) => Column(
              children: [
                SettingTile(
                  leading: const Icon(
                    Icons.circle_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  title: e,
                  trailing: Switch(value: true, onChanged: (_) {}),
                ),
                if (e != items.last) const Divider(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
