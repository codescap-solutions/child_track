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

  /// Helper to format seconds into "Xh Ym Zs"
  static String _formatSecs(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  factory AppUsageResponse.fromJson(Map<String, dynamic> json) {
    // BaseResponse.fromJson already extracts json['data'], so when called
    // from the repo, json IS the inner data object (records, child_id, etc.).
    // Fall back to json itself if json['data'] doesn't exist.
    var rawData = json['data'] ?? json;
    Map<String, List<AppUsageItem>> dailyUsageMap = {};
    int totalSeconds = 0;

    if (rawData is Map<String, dynamic>) {
      // ── Format 2: parent/screentime endpoint ──
      //  data.records: [ { date, totalSeconds, apps: [{packageName, seconds}] } ]
      if (rawData.containsKey('records') && rawData['records'] is List) {
        final records = rawData['records'] as List;
        totalSeconds = rawData['totalSeconds'] ?? 0;

        for (final record in records) {
          if (record is Map<String, dynamic>) {
            // Extract date key (e.g. "2026-02-18")
            final rawDate = record['date'] ?? '';
            final dateKey = rawDate.toString().split('T')[0];
            final apps = record['apps'] as List? ?? [];

            dailyUsageMap[dateKey] = apps.map((app) {
              final appMap = app as Map<String, dynamic>;
              return AppUsageItem(
                date: dateKey,
                appName: appMap['appName'] ?? appMap['packageName'] ?? '',
                packageName: appMap['packageName'] ?? '',
                usageTime: appMap['seconds'] ?? appMap['usageTime'] ?? 0,
                usageTimeFormatted: _formatSecs(
                  appMap['seconds'] ?? appMap['usageTime'] ?? 0,
                ),
                platform: appMap['platform'] ?? 'android',
                openCount: appMap['openCount'] ?? 0,
              );
            }).toList();
          }
        }
      } else {
        // ── Format 1: app-usage endpoint ──
        //  data: { "2026-02-18": [ {date, appName, usageTime, ...} ] }
        rawData.forEach((key, value) {
          if (value is List) {
            dailyUsageMap[key] = value
                .map((e) => AppUsageItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        });
      }
    }

    return AppUsageResponse(
      userId: json['userId'] ?? rawData?['child_id'] ?? '',
      totalUsageTime: json['totalUsageTime'] ?? totalSeconds,
      totalUsageTimeFormatted:
          json['totalUsageTimeFormatted'] ?? _formatSecs(totalSeconds),
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
    final seconds = json['usageTime'] ?? json['seconds'] ?? 0;
    return AppUsageItem(
      date: json['date'] ?? '',
      appName: json['appName'] ?? json['packageName'] ?? '',
      packageName: json['packageName'] ?? '',
      usageTime: seconds,
      usageTimeFormatted:
          json['usageTimeFormatted'] ?? AppUsageResponse._formatSecs(seconds),
      platform: json['platform'] ?? 'android',
      openCount: json['openCount'] ?? 0,
    );
  }
}
