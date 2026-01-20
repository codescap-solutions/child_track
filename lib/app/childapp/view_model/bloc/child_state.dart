part of 'child_bloc.dart';

sealed class ChildState extends Equatable {
  const ChildState();

  @override
  List<Object> get props => [];
}

final class ChildDeviceInfoLoaded extends ChildState {
  final DeviceInfo deviceInfo;
  final List<AppScreenTimeModel> screenTime;
  final Position? childLocation;
  final bool isTripTracking;
  final List<Position> tripLocations;
  final DateTime? tripStartTime;
  final Position? lastTrackedLocation;
  final bool hasUsagePermission;
  final TripStatus tripStatus;
  final TripMode tripMode;
  final DateTime? waitingStartTime;
  final int consecutiveMovingPoints;
  final DateTime? candidateStartTime;
  final Position? candidateStartLocation;

  const ChildDeviceInfoLoaded({
    required this.deviceInfo,
    this.screenTime = const [],
    this.childLocation,
    this.isTripTracking = false,
    this.tripLocations = const [],
    this.tripStartTime,
    this.lastTrackedLocation,
    this.hasUsagePermission = false,
    this.tripStatus = TripStatus.idle,
    this.tripMode = TripMode.unknown,
    this.waitingStartTime,
    this.consecutiveMovingPoints = 0,
    this.candidateStartTime,
    this.candidateStartLocation,
  });

  @override
  List<Object> get props => [
    deviceInfo,
    screenTime,
    isTripTracking,
    tripLocations,
    if (childLocation != null) childLocation!,
    if (tripStartTime != null) tripStartTime!,
    if (lastTrackedLocation != null) lastTrackedLocation!,
    hasUsagePermission,
    tripStatus,
    tripMode,
    if (waitingStartTime != null) waitingStartTime!,
    consecutiveMovingPoints,
    if (candidateStartTime != null) candidateStartTime!,
    if (candidateStartLocation != null) candidateStartLocation!,
  ];

  ChildDeviceInfoLoaded copyWith({
    DeviceInfo? deviceInfo,
    List<AppScreenTimeModel>? screenTime,
    Position? childLocation,
    bool? isTripTracking,
    List<Position>? tripLocations,
    DateTime? tripStartTime,
    Position? lastTrackedLocation,
    bool? hasUsagePermission,
    TripStatus? tripStatus,
    TripMode? tripMode,
    DateTime? waitingStartTime,
    int? consecutiveMovingPoints,
    DateTime? candidateStartTime,
    Position? candidateStartLocation,
  }) {
    return ChildDeviceInfoLoaded(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      screenTime: screenTime ?? this.screenTime,
      childLocation: childLocation ?? this.childLocation,
      isTripTracking: isTripTracking ?? this.isTripTracking,
      tripLocations: tripLocations ?? this.tripLocations,
      tripStartTime: tripStartTime ?? this.tripStartTime,
      lastTrackedLocation: lastTrackedLocation ?? this.lastTrackedLocation,
      hasUsagePermission: hasUsagePermission ?? this.hasUsagePermission,
      tripStatus: tripStatus ?? this.tripStatus,
      tripMode: tripMode ?? this.tripMode,
      waitingStartTime: waitingStartTime ?? this.waitingStartTime,
      consecutiveMovingPoints:
          consecutiveMovingPoints ?? this.consecutiveMovingPoints,
      candidateStartTime: candidateStartTime ?? this.candidateStartTime,
      candidateStartLocation:
          candidateStartLocation ?? this.candidateStartLocation,
    );
  }

  static ChildDeviceInfoLoaded initial() {
    return ChildDeviceInfoLoaded(
      deviceInfo: DeviceInfo(
        batteryPercentage: 0,
        networkStatus: '',
        networkType: '',
        soundProfile: '',
        isOnline: false,
        onlineSince: '',
      ),
      screenTime: [],
      hasUsagePermission: false,
    );
  }
}

final class SosError extends ChildState {
  final String message;

  const SosError({required this.message});

  @override
  List<Object> get props => [message];
}

enum TripStatus { idle, moving, waiting, ended }

enum TripMode { unknown, walking, vehicle }
