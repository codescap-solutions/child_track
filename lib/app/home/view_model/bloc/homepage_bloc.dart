import 'dart:async';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/home/model/home_model.dart';
import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/model/location_info_model.dart';
import 'package:child_track/app/home/model/yesterday_trip_summary_model.dart';
import 'package:child_track/app/home/model/cards_model.dart';
import 'package:child_track/app/home/model/trip_list_model.dart';
import 'package:child_track/app/home/model/trip_detail_model.dart';
import 'package:child_track/app/home/view_model/home_repo.dart';
import 'package:child_track/app/map/view_model/map_bloc.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'homepage_event.dart';
part 'homepage_state.dart';

class HomepageBloc extends Bloc<HomepageEvent, HomepageState> {
  final HomeRepository _homeRepository;
  final MapBloc _mapBloc;
  final SharedPrefsService _sharedPrefsService;
  Timer? _pollingTimer;
  String? _lastChildId;

  // Sample data fallback for yesterday trips
  static const List<Map<String, dynamic>> _sampleYesterdayTrips = [
    {
      "segment_id": "S1",
      "type": "ride",
      "start_latitude": 11.2488,
      "start_longitude": 75.7839,
      "end_latitude": 11.354909,
      "end_longitude": 75.790219,
      "start_time": "10:00am",
      "end_time": "12:00pm",
      "start_point": {"name": "Home"},
      "end_point": {"name": "Mall"},
      "distance_km": 6.0,
      "duration_minutes": 120,
      "max_speed_kmph": 40,
      "polyline_points": [
        {"latitude": 11.2488, "longitude": 75.7839},
        {"latitude": 11.354909, "longitude": 75.790219},
      ],
      "progress": 30,
    },
    {
      "segment_id": "S2",
      "type": "ride",
      "start_time": "11:00pm",
      "end_time": "11:30pm",
      "start_point": {"name": "Mall"},
      "end_point": {"name": "Park"},
      "distance_km": 10.5,
      "duration_minutes": 180,
      "max_speed_kmph": 55,
      "start_latitude": 11.433278,
      "start_longitude": 75.785960,
      "end_latitude": 11.390055,
      "end_longitude": 75.774120,
      "polyline_points": [
        {"latitude": 11.433278, "longitude": 75.785960},
        {"latitude": 11.390055, "longitude": 75.774120},
      ],
      "progress": 60,
    },
    {
      "segment_id": "S3",
      "type": "walk",
      "start_time": "10:30pm",
      "end_time": "12:00am",
      "start_latitude": 11.390055,
      "start_longitude": 75.774120,
      "end_latitude": 11.354909,
      "end_longitude": 75.790219,
      "start_point": {"name": "Park"},
      "end_point": {"name": "Ice Cream Shop"},
      "distance_km": 1.2,
      "duration_minutes": 30,
      "max_speed_kmph": 6,
      "polyline_points": [
        {"latitude": 11.390055, "longitude": 75.774120},
        {"latitude": 11.354909, "longitude": 75.790219},
      ],
      "progress": 100,
    },
  ];

  HomepageBloc({
    required HomeRepository homeRepository,
    required MapBloc mapBloc,
    SharedPrefsService? sharedPrefsService,
  }) : _homeRepository = homeRepository,
       _mapBloc = mapBloc,
       _sharedPrefsService = sharedPrefsService ?? SharedPrefsService(),
       super(HomepageSuccess.initial()) {
    on<GetHomepageData>(_onGetHomepageData);
    on<FetchChildCurrentDetails>(_onFetchChildCurrentDetails);
    on<GetTrips>(_onGetTrips);
    on<GetTripDetail>(_onGetTripDetail);
  }

  void _startPolling(String? childId) {
    _lastChildId = childId;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      add(GetHomepageData(childId: _lastChildId));
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }

  /// Convert sample data to TripSegment objects
  List<TripSegment> _getSampleTripSegments() {
    return _sampleYesterdayTrips
        .map((json) => TripSegment.fromJson(json))
        .toList();
  }

  Future<void> _onGetHomepageData(
    GetHomepageData event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;

    // Get child_id from event or SharedPreferences
    final childId = event.childId ?? _sharedPrefsService.getString('child_id');
    
    // If no child_id, check if parent has children
    if (childId == null) {
      final childrenCount = _sharedPrefsService.getInt('children_count') ?? 0;
      if (childrenCount == 0) {
        emit(currentState.copyWith(
          isLoading: false,
          hasNoChild: true,
        ));
        return;
      }
    }

    // Start polling on first call
    if (_pollingTimer == null || !_pollingTimer!.isActive) {
      _startPolling(childId);
    }

    emit(currentState.copyWith(isLoading: true));
    try {
      final response = await _homeRepository.getHomeData(
        childId: childId,
      );
      if (response.isSuccess && response.data != null) {
        final homeData = response.data!;
        // Use sample data if yesterdayTrips is null or empty
        final tripsToUse = homeData.yesterdayTrips.isEmpty
            ? _getSampleTripSegments()
            : homeData.yesterdayTrips;

        emit(
          HomepageSuccess(
            deviceInfo: homeData.deviceInfo,
            currentLocation: homeData.currentLocation,
            yesterdayTrips: tripsToUse,
            yesterdayTripSummary: homeData.yesterdayTripSummary,
            cards: homeData.cards,
            isLoading: false,
            hasNoChild: false,
          ),
        );
      } else {
        // Check if error is due to no child connected
        if (response.message.toLowerCase().contains('child') || 
            response.message.toLowerCase().contains('not found')) {
          emit(currentState.copyWith(
            isLoading: false,
            hasNoChild: true,
          ));
        } else {
          emit(HomepageError(message: response.message));
        }
      }
    } catch (e) {
      AppLogger.error('Error fetching home data: ${e.toString()}');
      emit(HomepageError(message: 'Failed to load home data: ${e.toString()}'));
    }
  }

  Future<void> _onFetchChildCurrentDetails(
    FetchChildCurrentDetails event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;
    try {
      emit(currentState.copyWith(isLoading: true));
      final response = await _homeRepository.getCurrentLocationDetails();
      if (response.isSuccess) {
        final homeData = HomeResponse.fromJson(response.data);

        emit(
          currentState.copyWith(
            currentLocation: homeData.currentLocation,
            deviceInfo: homeData.deviceInfo,
          ),
        );
        _mapBloc.add(
          UpdateChildLocation(
            LatLng(homeData.currentLocation.lat, homeData.currentLocation.lng),
          ),
        );
      } else {
        emit(currentState.copyWith(isLoading: false));
      }
    } catch (e) {
      AppLogger.error(e.toString());
    } finally {
      emit(currentState.copyWith(isLoading: false));
    }
  }

  Future<void> _onGetTrips(GetTrips event, Emitter<HomepageState> emit) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;
    emit(currentState.copyWith(isLoadingTrips: true));
    try {
      final response = await _homeRepository.getTrips(
        childId: event.childId,
        page: event.page,
        pageSize: event.pageSize,
      );
      if (response.isSuccess && response.data != null) {
        final tripsData = response.data!;
        emit(
          currentState.copyWith(
            trips: tripsData.trips,
            tripsPage: tripsData.page,
            tripsPageSize: tripsData.pageSize,
            tripsTotalItems: tripsData.totalItems,
            isLoadingTrips: false,
          ),
        );
      } else {
        emit(currentState.copyWith(isLoadingTrips: false));
        AppLogger.error('Failed to fetch trips: ${response.message}');
      }
    } catch (e) {
      AppLogger.error('Error fetching trips: ${e.toString()}');
      emit(currentState.copyWith(isLoadingTrips: false));
    }
  }

  Future<void> _onGetTripDetail(
    GetTripDetail event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;
    emit(
      currentState.copyWith(
        isLoadingTripDetail: true,
        selectedTripId: event.tripId,
      ),
    );
    try {
      final response = await _homeRepository.getTripDetail(event.tripId);
      if (response.isSuccess && response.data != null) {
        emit(
          currentState.copyWith(
            selectedTripDetail: response.data!,
            isLoadingTripDetail: false,
          ),
        );
      } else {
        emit(currentState.copyWith(isLoadingTripDetail: false));
        AppLogger.error('Failed to fetch trip detail: ${response.message}');
      }
    } catch (e) {
      AppLogger.error('Error fetching trip detail: ${e.toString()}');
      emit(currentState.copyWith(isLoadingTripDetail: false));
    }
  }
}
