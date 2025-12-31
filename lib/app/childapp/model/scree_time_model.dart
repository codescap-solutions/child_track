class AppScreenTimeModel {
  final String package;
  final String appName;
  final bool isSystemApp;
  final int seconds;

  AppScreenTimeModel({
    required this.package,
    this.appName = '',
    this.isSystemApp = false,
    required this.seconds,
  });

  factory AppScreenTimeModel.fromJson(Map<String, dynamic> json) {
    return AppScreenTimeModel(
      package: json['package'] ?? '',
      appName: json['appName'] ?? '',
      isSystemApp: json['isSystemApp'] ?? false,
      seconds: json['seconds'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'package': package,
      'appName': appName,
      'isSystemApp': isSystemApp,
      'seconds': seconds,
    };
  }

  AppScreenTimeModel copyWith({
    String? package,
    String? appName,
    bool? isSystemApp,
    int? seconds,
  }) {
    return AppScreenTimeModel(
      package: package ?? this.package,
      appName: appName ?? this.appName,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      seconds: seconds ?? this.seconds,
    );
  }
}
