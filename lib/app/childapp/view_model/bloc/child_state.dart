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
  final Position? lastPostedLocation;
  final List<Position> candidatePoints;
  final TripDetectionStatus detectionStatus;

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
    this.lastPostedLocation,
    this.candidatePoints = const [],
    this.detectionStatus = TripDetectionStatus.idle,
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
    if (lastPostedLocation != null) lastPostedLocation!,
    candidatePoints,
    detectionStatus,
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
    Position? lastPostedLocation,
    List<Position>? candidatePoints,
    TripDetectionStatus? detectionStatus,
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
      lastPostedLocation: lastPostedLocation ?? this.lastPostedLocation,
      candidatePoints: candidatePoints ?? this.candidatePoints,
      detectionStatus: detectionStatus ?? this.detectionStatus,
    );
  }

  static ChildDeviceInfoLoaded initial() {
    return ChildDeviceInfoLoaded(
      deviceInfo: DeviceInfo(
        isCharging: false,
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

enum TripDetectionStatus { idle, candidate }
