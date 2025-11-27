part of 'homepage_bloc.dart';

sealed class HomepageState extends Equatable {
  const HomepageState();

  @override
  List<Object> get props => [];
}

final class HomepageSuccess extends HomepageState {
  final DeviceInfo? deviceInfo;
  final LocationInfo? currentLocation;
  final List<TripSegment> yesterdayTrips;
  final YesterdayTripSummary? yesterdayTripSummary;
  final Cards? cards;
  final bool isLoading;
  const HomepageSuccess({
    required this.deviceInfo,
    required this.currentLocation,
    this.yesterdayTrips = const [],
    this.yesterdayTripSummary,
    this.cards,
    this.isLoading = false,
  });
  //inital
  const HomepageSuccess.initial()
    : this(
        deviceInfo: null,
        currentLocation: null,
        yesterdayTrips: const [],
        yesterdayTripSummary: null,
        cards: null,
        isLoading: false,
      );
  @override
  List<Object> get props => [
    ?deviceInfo,
    ?currentLocation,
    yesterdayTrips,
    if (yesterdayTripSummary != null) yesterdayTripSummary!,
    if (cards != null) cards!,
    isLoading,
  ];
  HomepageSuccess copyWith({
    DeviceInfo? deviceInfo,
    LocationInfo? currentLocation,
    List<TripSegment>? yesterdayTrips,
    YesterdayTripSummary? yesterdayTripSummary,
    Cards? cards,
    bool? isLoading,
  }) {
    return HomepageSuccess(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      currentLocation: currentLocation ?? this.currentLocation,
      yesterdayTrips: yesterdayTrips ?? this.yesterdayTrips,
      yesterdayTripSummary: yesterdayTripSummary ?? this.yesterdayTripSummary,
      cards: cards ?? this.cards,
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
