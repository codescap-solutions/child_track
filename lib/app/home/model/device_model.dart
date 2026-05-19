class DeviceInfo {
  final int batteryPercentage;
  final String networkStatus;
  final String networkType;
  final String soundProfile;
  final bool isOnline;
  final String onlineSince;
  final bool isCharging;

  DeviceInfo({
    required this.batteryPercentage,
    required this.networkStatus,
    required this.networkType,
    required this.soundProfile,
    required this.isOnline,
    required this.onlineSince,
    required this.isCharging,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      batteryPercentage: json['battery_percentage'] ?? 0,
      networkStatus: json['network_status'] ?? '',
      networkType: json['network_type'] ?? '',
      soundProfile: json['sound_profile'] ?? '',
      isOnline: json['is_online'] ?? false,
      onlineSince: json['last_update'] ?? '',
      isCharging: json['is_charging'] ?? false,
    );
  }

  DeviceInfo copyWith({
    int? batteryPercentage,
    String? networkStatus,
    String? networkType,
    String? soundProfile,
    bool? isOnline,
    String? onlineSince,
    bool? isCharging,
  }) {
    return DeviceInfo(
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      networkStatus: networkStatus ?? this.networkStatus,
      networkType: networkType ?? this.networkType,
      soundProfile: soundProfile ?? this.soundProfile,
      isOnline: isOnline ?? this.isOnline,
      onlineSince: onlineSince ?? this.onlineSince,
      isCharging: isCharging ?? this.isCharging,
    );
  }
}
