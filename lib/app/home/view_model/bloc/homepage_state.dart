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
  final bool hasNoChild;
  // Trips data
  final List<Trip> trips;
  final int? tripsPage;
  final int? tripsPageSize;
  final int? tripsTotalItems;
  final bool isLoadingTrips;
  // Trip detail data
  final TripDetailResponse? selectedTripDetail;
  final bool isLoadingTripDetail;
  final String? selectedTripId;

  const HomepageSuccess({
    required this.deviceInfo,
    this.currentLocation,
    this.yesterdayTrips = const [],
    this.yesterdayTripSummary,
    this.cards,
    this.isLoading = false,
    this.hasNoChild = false,
    this.trips = const [],
    this.tripsPage,
    this.tripsPageSize,
    this.tripsTotalItems,
    this.isLoadingTrips = false,
    this.selectedTripDetail,
    this.isLoadingTripDetail = false,
    this.selectedTripId,
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
        hasNoChild: false,
        trips: const [],
        tripsPage: null,
        tripsPageSize: null,
        tripsTotalItems: null,
        isLoadingTrips: false,
        selectedTripDetail: null,
        isLoadingTripDetail: false,
        selectedTripId: null,
      );
  @override
  List<Object> get props => [
    if (deviceInfo != null) deviceInfo!,
    if (currentLocation != null) currentLocation!,
    yesterdayTrips,
    if (yesterdayTripSummary != null) yesterdayTripSummary!,
    if (cards != null) cards!,
    isLoading,
    hasNoChild,
    trips,
    if (tripsPage != null) tripsPage!,
    if (tripsPageSize != null) tripsPageSize!,
    if (tripsTotalItems != null) tripsTotalItems!,
    isLoadingTrips,
    if (selectedTripDetail != null) selectedTripDetail!,
    isLoadingTripDetail,
    if (selectedTripId != null) selectedTripId!,
  ];
  HomepageSuccess copyWith({
    DeviceInfo? deviceInfo,
    LocationInfo? currentLocation,
    List<TripSegment>? yesterdayTrips,
    YesterdayTripSummary? yesterdayTripSummary,
    Cards? cards,
    bool? isLoading,
    bool? hasNoChild,
    List<Trip>? trips,
    int? tripsPage,
    int? tripsPageSize,
    int? tripsTotalItems,
    bool? isLoadingTrips,
    TripDetailResponse? selectedTripDetail,
    bool? isLoadingTripDetail,
    String? selectedTripId,
  }) {
    return HomepageSuccess(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      currentLocation: currentLocation ?? this.currentLocation,
      yesterdayTrips: yesterdayTrips ?? this.yesterdayTrips,
      yesterdayTripSummary: yesterdayTripSummary ?? this.yesterdayTripSummary,
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      hasNoChild: hasNoChild ?? this.hasNoChild,
      trips: trips ?? this.trips,
      tripsPage: tripsPage ?? this.tripsPage,
      tripsPageSize: tripsPageSize ?? this.tripsPageSize,
      tripsTotalItems: tripsTotalItems ?? this.tripsTotalItems,
      isLoadingTrips: isLoadingTrips ?? this.isLoadingTrips,
      selectedTripDetail: selectedTripDetail ?? this.selectedTripDetail,
      isLoadingTripDetail: isLoadingTripDetail ?? this.isLoadingTripDetail,
      selectedTripId: selectedTripId ?? this.selectedTripId,
    );
  }
}

final class HomepageError extends HomepageState {
  final String message;
  const HomepageError({required this.message});
  @override
  List<Object> get props => [message];
}
