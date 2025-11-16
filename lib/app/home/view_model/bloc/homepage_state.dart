part of 'homepage_bloc.dart';

sealed class HomepageState extends Equatable {
  const HomepageState();

  @override
  List<Object> get props => [];
}

final class HomepageInitial extends HomepageState {}

final class HomepageLoading extends HomepageState {}

final class HomepageSuccess extends HomepageState {
  final DeviceInfo deviceInfo;
  final LocationInfo currentLocation;
  final List<TripSegment> yesterdayTrips;
  final bool isLoading;
  const HomepageSuccess({
    required this.deviceInfo,
    required this.currentLocation,
    required this.yesterdayTrips,
    this.isLoading = false,
  });
  @override
  List<Object> get props => [deviceInfo, currentLocation, yesterdayTrips];
  HomepageSuccess copyWith({
    DeviceInfo? deviceInfo,
    LocationInfo? currentLocation,
    List<TripSegment>? yesterdayTrips,
    bool? isLoading,
  }) {
    return HomepageSuccess(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      currentLocation: currentLocation ?? this.currentLocation,
      yesterdayTrips: yesterdayTrips ?? this.yesterdayTrips,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final class HomepageError extends HomepageState {
  final String message;
  const HomepageError({required this.message});
  @override
  List<Object> get props => [message];
}

// Map-related states
final class MapInitial extends HomepageState {}
