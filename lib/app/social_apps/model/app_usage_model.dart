class AppUsageResponse {
  final String userId;
  final int totalUsageTime;
  final String totalUsageTimeFormatted;
  final int totalApps;
  final Map<String, List<AppUsageItem>> dailyUsage;

  AppUsageResponse({
    required this.userId,
    required this.totalUsageTime,
    required this.totalUsageTimeFormatted,
    required this.totalApps,
    required this.dailyUsage,
  });

  factory AppUsageResponse.fromJson(Map<String, dynamic> json) {
    var rawData = json['data'];
    Map<String, List<AppUsageItem>> dailyUsageMap = {};

    if (rawData is Map<String, dynamic>) {
      rawData.forEach((key, value) {
        if (value is List) {
          dailyUsageMap[key] = value
              .map((e) => AppUsageItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      });
    }

    return AppUsageResponse(
      userId: json['userId'] ?? '',
      totalUsageTime: json['totalUsageTime'] ?? 0,
      totalUsageTimeFormatted: json['totalUsageTimeFormatted'] ?? '0s',
      totalApps: json['totalApps'] ?? 0,
      dailyUsage: dailyUsageMap,
    );
  }
}

class AppUsageItem {
  final String date;
  final String appName;
  final String packageName;
  final int usageTime;
  final String usageTimeFormatted;
  final String platform;
  final int openCount;
  final String? iconBase64;

  AppUsageItem({
    required this.date,
    required this.appName,
    required this.packageName,
    required this.usageTime,
    required this.usageTimeFormatted,
    required this.platform,
    required this.openCount,
    this.iconBase64,
  });

  factory AppUsageItem.fromJson(Map<String, dynamic> json) {
    return AppUsageItem(
      date: json['date'] ?? '',
      appName: json['appName'] ?? '',
      packageName: json['packageName'] ?? '',
      usageTime: json['usageTime'] ?? 0,
      usageTimeFormatted: json['usageTimeFormatted'] ?? '0s',
      platform: json['platform'] ?? 'android',
      openCount: json['openCount'] ?? 0,
    );
  }
}
