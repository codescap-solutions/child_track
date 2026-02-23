import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import '../models/notification_settings_model.dart';
import '../view_model/notification_bloc/notification_bloc.dart';
import '../view_model/notification_bloc/notification_event.dart';
import '../view_model/notification_bloc/notification_state.dart';
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
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is NotificationLoaded) {
            final model = state.model;

            return ListView(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              children: [
                /// MASTER SWITCH
                SectionCard(
                  child: SettingTile(
                    leading: const Icon(Icons.notifications_active),
                    title: 'Enable Notifications',
                    trailing: Switch(
                      value: (model.masterEnabled ?? false),
                      onChanged: (value) {
                        context.read<NotificationBloc>().add(
                          ToggleMasterNotification(value),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingS),

                _Group(
                  title: 'Movements',
                  category: 'movements',
                  model: model,
                  items: model.movements ?? {},
                ),

                _Group(
                  title: 'Device & App Health Alerts',
                  category: 'device_health',
                  model: model,
                  items: model.deviceHealth ?? const {},
                ),

                _Group(
                  title: 'Communication Alerts',
                  category: 'communication',
                  model: model,
                  items: model.communication ?? {},
                ),

                _Group(
                  title: 'Health, Activity & Wellness',
                  category: 'health',
                  model: model,
                  items: model.health ?? const {},
                ),

                _Group(
                  title: 'Daily/Weekly',
                  category: 'reports',
                  model: model,
                  items: model.reports ?? const {},
                ),

                _Group(
                  title: 'Family & App Usage',
                  category: 'family',
                  model: model,
                  items: model.family ?? const {},
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final String category;
  final NotificationSettingsModel model;
  final Map<String, bool> items; // UI title -> API key

  const _Group({
    required this.title,
    required this.category,
    required this.model,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final categoryMap = _getCategoryMap();

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
          ...categoryMap.entries.map((entry) {
            return Column(
              children: [
                SettingTile(
                  leading: const Icon(
                    Icons.circle_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  title: formatKeyToTitle(entry.key),
                  trailing: Switch(
                    value: entry.value,
                    onChanged: (model.masterEnabled ?? false)
                        ? (newValue) {
                            context.read<NotificationBloc>().add(
                              UpdateNotificationItem(
                                category: category,
                                key: entry.key,
                                value: newValue,
                              ),
                            );
                          }
                        : null,
                  ),
                ),
                if (entry.key != items.keys.last) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  String formatKeyToTitle(String key) {
    if (key.isEmpty) return "";

    return key
        .split('_') // Split the string into a list of words
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        ) // Capitalize each word
        .join(' '); // Join them back with spaces
  }

  Map<String, bool> _getCategoryMap() {
    switch (category) {
      case 'movements':
        return model.movements ?? {};
      case 'device_health':
        return model.deviceHealth ?? {};
      case 'communication':
        return model.communication ?? {};
      case 'health':
        return model.health ?? {};
      case 'reports':
        return model.reports ?? {};
      case 'family':
        return model.family ?? {};
      default:
        return {};
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:child_track/core/constants/app_colors.dart';
// import 'package:child_track/core/constants/app_sizes.dart';
// import 'widgets/section_card.dart';
// import 'widgets/setting_tile.dart';

// class NotificationSettingsView extends StatelessWidget {
//   const NotificationSettingsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, size: 18),
//           onPressed: () => Navigator.of(context).maybePop(),
//         ),
//         title: const Text('Notification Settings'),
//         backgroundColor: AppColors.surfaceColor,
//         elevation: 0,
//         foregroundColor: AppColors.textPrimary,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(AppSizes.paddingL),
//         children: const [
//           _Group(
//             title: 'Movements',
//             items: [
//               'Entering a Place',
//               'Leaving a Place',
//               'New Place',
//               'Starting Trip',
//               'Route Deviation',
//               'Estimated arrival at a place',
//               'Movement speed',
//               'Geofences Boundary Alerts',
//               'Route Deviation Warning',
//               'Unusual Stop Detection',
//             ],
//           ),
//           _Group(
//             title: 'Device & App Health Alerts',
//             items: [
//               'Low Battery Notification',
//               'Signal Loss/GPS Offline Alert',
//               'Device Tampering Alert',
//               'Connectivity Loss Alert',
//               'App Status Alert',
//             ],
//           ),
//           _Group(
//             title: 'Communication Alerts',
//             items: [
//               'New Message Notification',
//               'Missed Communication Alert',
//               'Scheduled School Delivery',
//               'Manual Whistle Clock',
//             ],
//           ),
//           _Group(
//             title: 'Health, Activity & Wellness',
//             items: ['Daily Step Count Report', 'Prolonged Inactivity Alert'],
//           ),
//           _Group(
//             title: 'Daily/Weekly',
//             items: [
//               'Daily Movement Summary',
//               'Weekly Safety & Activity Report',
//               'Real-time Accurate Notification',
//               'Weather Report',
//             ],
//           ),
//           _Group(
//             title: 'Family & App Usage',
//             items: ['New Family Member Alert', 'App Updates/Reminder Alert'],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Group extends StatelessWidget {
//   final String title;
//   final List<String> items;
//   const _Group({required this.title, required this.items});

//   @override
//   Widget build(BuildContext context) {
//     return SectionCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
//             child: Text(
//               title,
//               style: const TextStyle(fontWeight: FontWeight.w700),
//             ),
//           ),
//           ...items.map(
//             (e) => Column(
//               children: [
//                 SettingTile(
//                   leading: const Icon(
//                     Icons.circle_outlined,
//                     size: 18,
//                     color: AppColors.textSecondary,
//                   ),
//                   title: e,
//                   trailing: Switch(value: true, onChanged: (_) {}),
//                 ),
//                 if (e != items.last) const Divider(height: 1),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
