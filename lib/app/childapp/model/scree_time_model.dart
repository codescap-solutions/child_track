class AppScreenTimeModel {
  final String package;
  final String appName;
  final bool isSystemApp;
  final int seconds;
  final int lastTimeUsed;
  final String? iconBase64;

  AppScreenTimeModel({
    required this.package,
    this.appName = '',
    this.isSystemApp = false,
    required this.seconds,
    this.lastTimeUsed = 0,
    this.iconBase64,
  });

  factory AppScreenTimeModel.fromJson(Map<String, dynamic> json) {
    return AppScreenTimeModel(
      package: json['package'] ?? '',
      appName: json['appName'] ?? '',
      isSystemApp: json['isSystemApp'] ?? false,
      seconds: json['seconds'] ?? 0,
      lastTimeUsed: json['lastTimeUsed'] ?? 0,
      iconBase64: json['icon'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'package': package,
      'appName': appName,
      'isSystemApp': isSystemApp,
      'seconds': seconds,
      'lastTimeUsed': lastTimeUsed,
      'icon': iconBase64,
    };
  }

  AppScreenTimeModel copyWith({
    String? package,
    String? appName,
    bool? isSystemApp,
    int? seconds,
    int? lastTimeUsed,
    String? iconBase64,
  }) {
    return AppScreenTimeModel(
      package: package ?? this.package,
      appName: appName ?? this.appName,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      seconds: seconds ?? this.seconds,
      lastTimeUsed: lastTimeUsed ?? this.lastTimeUsed,
      iconBase64: iconBase64 ?? this.iconBase64,
    );
  }
}
