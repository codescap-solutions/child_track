// Models for the locked-apps API responses.

class LockedPackageItem {
  final String packageName;
  final String appName;
  final DateTime? lockedAt;
  final int lockDurationMinutes;
  final DateTime? lockedUntil;

  LockedPackageItem({
    required this.packageName,
    required this.appName,
    this.lockedAt,
    this.lockDurationMinutes = 0,
    this.lockedUntil,
  });

  factory LockedPackageItem.fromJson(Map<String, dynamic> json) {
    return LockedPackageItem(
      packageName: json['package_name'] ?? '',
      appName: json['app_name'] ?? json['package_name'] ?? '',
      lockedAt: json['locked_at'] != null
          ? DateTime.tryParse(json['locked_at'])
          : null,
      lockDurationMinutes: json['lock_duration_minutes'] ?? 0,
      lockedUntil: json['locked_until'] != null
          ? DateTime.tryParse(json['locked_until'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'package_name': packageName,
      'app_name': appName,
      'lock_duration_minutes': lockDurationMinutes,
    };
  }
}

class ParentLockedAppsResponse {
  final String childId;
  final List<LockedPackageItem> lockedPackages;
  final DateTime? updatedAt;

  ParentLockedAppsResponse({
    required this.childId,
    required this.lockedPackages,
    this.updatedAt,
  });

  factory ParentLockedAppsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final packages = (data['locked_packages'] as List? ?? [])
        .map((e) => LockedPackageItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return ParentLockedAppsResponse(
      childId: data['child_id'] ?? '',
      lockedPackages: packages,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'])
          : null,
    );
  }
}

class ChildLockedAppsResponse {
  final List<LockedPackageItem> lockedPackages;
  final DateTime? updatedAt;

  ChildLockedAppsResponse({required this.lockedPackages, this.updatedAt});

  factory ChildLockedAppsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final packages = (data['locked_packages'] as List? ?? [])
        .map((e) => LockedPackageItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return ChildLockedAppsResponse(
      lockedPackages: packages,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'])
          : null,
    );
  }
}
