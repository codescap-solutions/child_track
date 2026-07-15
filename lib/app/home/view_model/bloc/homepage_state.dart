import 'package:child_track/app/home/model/cards_model.dart';
import 'package:child_track/app/home/model/child_tracking_snapshot.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/home/model/home_model.dart';
import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/model/location_info_model.dart';
import 'package:child_track/app/home/model/trip_detail_model.dart';
import 'package:child_track/app/home/model/trip_list_model.dart';
import 'package:child_track/app/home/model/yesterday_trip_summary_model.dart';
import 'package:equatable/equatable.dart';

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
  final bool webFilteringEnabled;
  final bool waitingForSilentSyncResponse;
  final String? childAvatar;

  // New Visual Section models from updated HomeResponse
  final FeatureSummary? features;
  final RouteMapSummary? todayRoute;
  final ScreentimeTodaySummary? screentimeToday;

  // Shared children list
  final List<SharedChild> sharedChildren;

  // Trips data
  final List<Trip> trips;
  final int? tripsPage;
  final int? tripsPageSize;
  final int? tripsTotalItems;
  final bool isLoadingTrips;
  final bool hasReachedMax; // New field
  // Trip detail data
  final TripDetailResponse? selectedTripDetail;
  final bool isLoadingTripDetail;
  final String? selectedTripId;

  // Live active trip (from /parent/home active_trip)
  final ActiveTrip? activeTrip;

  // Tracking snapshot
  final ChildTrackingSnapshot? trackingSnapshot;

  const HomepageSuccess({
    required this.deviceInfo,
    this.currentLocation,
    this.yesterdayTrips = const [],
    this.yesterdayTripSummary,
    this.cards,
    this.isLoading = false,
    this.hasNoChild = false,
    this.webFilteringEnabled = false,
    this.waitingForSilentSyncResponse = false,
    this.childAvatar,
    this.features,
    this.todayRoute,
    this.screentimeToday,
    this.sharedChildren = const [],
    this.trips = const [],
    this.tripsPage,
    this.tripsPageSize,
    this.tripsTotalItems,
    this.isLoadingTrips = false,
    this.hasReachedMax = false, // Initialize
    this.selectedTripDetail,
    this.isLoadingTripDetail = false,
    this.selectedTripId,
    this.activeTrip,
    this.trackingSnapshot,
  });

  // initial
  const HomepageSuccess.initial()
    : this(
        deviceInfo: null,
        currentLocation: null,
        yesterdayTrips: const [],
        yesterdayTripSummary: null,
        cards: null,
        isLoading: false,
        hasNoChild: false,
        webFilteringEnabled: false,
        waitingForSilentSyncResponse: false,
        childAvatar: null,
        features: null,
        todayRoute: null,
        screentimeToday: null,
        sharedChildren: const [],
        trips: const [],
        tripsPage: null,
        tripsPageSize: null,
        tripsTotalItems: null,
        isLoadingTrips: false,
        hasReachedMax: false, // Initialize
        selectedTripDetail: null,
        isLoadingTripDetail: false,
        selectedTripId: null,
        activeTrip: null,
        trackingSnapshot: null,
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
    webFilteringEnabled,
    waitingForSilentSyncResponse,
    if (childAvatar != null) childAvatar!,
    if (features != null) features!,
    if (todayRoute != null) todayRoute!,
    if (screentimeToday != null) screentimeToday!,
    sharedChildren,
    trips,
    if (tripsPage != null) tripsPage!,
    if (tripsPageSize != null) tripsPageSize!,
    if (tripsTotalItems != null) tripsTotalItems!,
    isLoadingTrips,
    hasReachedMax, // Add to props
    if (selectedTripDetail != null) selectedTripDetail!,
    isLoadingTripDetail,
    if (selectedTripId != null) selectedTripId!,
    if (activeTrip != null) activeTrip!,
    if (trackingSnapshot != null) trackingSnapshot!,
  ];

  HomepageSuccess copyWith({
    DeviceInfo? deviceInfo,
    LocationInfo? currentLocation,
    List<TripSegment>? yesterdayTrips,
    YesterdayTripSummary? yesterdayTripSummary,
    Cards? cards,
    bool? isLoading,
    bool? hasNoChild,
    bool? webFilteringEnabled,
    bool? waitingForSilentSyncResponse,
    String? childAvatar,
    FeatureSummary? features,
    RouteMapSummary? todayRoute,
    ScreentimeTodaySummary? screentimeToday,
    List<SharedChild>? sharedChildren,
    List<Trip>? trips,
    int? tripsPage,
    int? tripsPageSize,
    int? tripsTotalItems,
    bool? isLoadingTrips,
    bool? hasReachedMax, // Add to copyWith params
    TripDetailResponse? selectedTripDetail,
    bool? isLoadingTripDetail,
    String? selectedTripId,
    ActiveTrip? activeTrip,
    ChildTrackingSnapshot? trackingSnapshot,
  }) {
    return HomepageSuccess(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      currentLocation: currentLocation ?? this.currentLocation,
      yesterdayTrips: yesterdayTrips ?? this.yesterdayTrips,
      yesterdayTripSummary: yesterdayTripSummary ?? this.yesterdayTripSummary,
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      hasNoChild: hasNoChild ?? this.hasNoChild,
      webFilteringEnabled: webFilteringEnabled ?? this.webFilteringEnabled,
      waitingForSilentSyncResponse:
          waitingForSilentSyncResponse ?? this.waitingForSilentSyncResponse,
      childAvatar: childAvatar ?? this.childAvatar,
      features: features ?? this.features,
      todayRoute: todayRoute ?? this.todayRoute,
      screentimeToday: screentimeToday ?? this.screentimeToday,
      sharedChildren: sharedChildren ?? this.sharedChildren,
      trips: trips ?? this.trips,
      tripsPage: tripsPage ?? this.tripsPage,
      tripsPageSize: tripsPageSize ?? this.tripsPageSize,
      tripsTotalItems: tripsTotalItems ?? this.tripsTotalItems,
      isLoadingTrips: isLoadingTrips ?? this.isLoadingTrips,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax, // Assign
      selectedTripDetail: selectedTripDetail ?? this.selectedTripDetail,
      isLoadingTripDetail: isLoadingTripDetail ?? this.isLoadingTripDetail,
      selectedTripId: selectedTripId ?? this.selectedTripId,
      activeTrip: activeTrip ?? this.activeTrip,
      trackingSnapshot: trackingSnapshot ?? this.trackingSnapshot,
    );
  }
}

final class HomepageError extends HomepageState {
  final String message;
  const HomepageError({required this.message});
  @override
  List<Object> get props => [message];
}
