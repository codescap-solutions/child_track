import 'package:equatable/equatable.dart';

class NotificationSettingsModel extends Equatable {
  final bool? masterEnabled;
  final Map<String, bool>? movements;
  final Map<String, bool>? deviceHealth;
  final Map<String, bool>? communication;
  final Map<String, bool>? health;
  final Map<String, bool>? reports;
  final Map<String, bool>? family;

  const NotificationSettingsModel({
    this.masterEnabled,
    this.movements,
    this.deviceHealth,
    this.communication,
    this.health,
    this.reports,
    this.family,
  });

  factory NotificationSettingsModel.initial() {
    return const NotificationSettingsModel(
      masterEnabled: true,
      movements: {},
      deviceHealth: {},
      communication: {},
      health: {},
      reports: {},
      family: {},
    );
  }

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    Map<String, bool> parse(dynamic map) => Map<String, bool>.from(map ?? {});

    return NotificationSettingsModel(
      masterEnabled: json['master_enabled'] ?? true,
      movements: parse(json['movements']),
      deviceHealth: parse(json['device_health']),
      communication: parse(json['communication']),
      health: parse(json['health']),
      reports: parse(json['reports']),
      family: parse(json['family']),
    );
  }

  Map<String, dynamic> toJson() => {
    "master_enabled": masterEnabled,
    "movements": movements,
    "device_health": deviceHealth,
    "communication": communication,
    "health": health,
    "reports": reports,
    "family": family,
  };

  NotificationSettingsModel copyWith({
    bool? masterEnabled,
    Map<String, bool>? movements,
    Map<String, bool>? deviceHealth,
    Map<String, bool>? communication,
    Map<String, bool>? health,
    Map<String, bool>? reports,
    Map<String, bool>? family,
  }) {
    return NotificationSettingsModel(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      movements: movements ?? this.movements,
      deviceHealth: deviceHealth ?? this.deviceHealth,
      communication: communication ?? this.communication,
      health: health ?? this.health,
      reports: reports ?? this.reports,
      family: family ?? this.family,
    );
  }

  NotificationSettingsModel updateSingle(
    String category,
    String key,
    bool value,
  ) {
    Map<String, bool> updated;

    switch (category) {
      case 'movements':
        updated = {...movements!, key: value};
        return copyWith(movements: updated);
      case 'device_health':
        updated = {...deviceHealth!, key: value};
        return copyWith(deviceHealth: updated);
      case 'communication':
        updated = {...communication!, key: value};
        return copyWith(communication: updated);
      case 'health':
        updated = {...health!, key: value};
        return copyWith(health: updated);
      case 'reports':
        updated = {...reports!, key: value};
        return copyWith(reports: updated);
      case 'family':
        updated = {...family!, key: value};
        return copyWith(family: updated);
      default:
        return this;
    }
  }

  @override
  List<Object?> get props => [
    masterEnabled,
    movements,
    deviceHealth,
    communication,
    health,
    reports,
    family,
  ];
}
