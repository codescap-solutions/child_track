class DeviceInfo {
  final int batteryPercentage;
  final String networkStatus;
  final String networkType;
  final String soundProfile;
  final bool isOnline;
  final String onlineSince;

  DeviceInfo({
    required this.batteryPercentage,
    required this.networkStatus,
    required this.networkType,
    required this.soundProfile,
    required this.isOnline,
    required this.onlineSince,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      batteryPercentage: json['battery_percentage'] ?? 0,
      networkStatus: json['network_status'] ?? '',
      networkType: json['network_type'] ?? '',
      soundProfile: json['sound_profile'] ?? '',
      isOnline: json['is_online'] ?? false,
      onlineSince: json['online_since'] ?? '',
    );
  }
}
