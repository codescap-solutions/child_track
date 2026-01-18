import 'dart:async';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/model/location_info_model.dart';
import 'package:child_track/app/home/model/yesterday_trip_summary_model.dart';
import 'package:child_track/app/home/model/cards_model.dart';
import 'package:child_track/app/home/model/trip_list_model.dart';
import 'package:child_track/app/home/model/trip_detail_model.dart';
import 'package:child_track/app/home/view_model/home_repo.dart';
import 'package:child_track/app/map/view_model/map_bloc.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/socket_service.dart';
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
  final SocketService _socketService;
  StreamSubscription? _locationSubscription;

  HomepageBloc({
    required HomeRepository homeRepository,
    required MapBloc mapBloc,
    SharedPrefsService? sharedPrefsService,
    required SocketService socketService,
  }) : _homeRepository = homeRepository,
       _mapBloc = mapBloc,
       _sharedPrefsService = sharedPrefsService ?? SharedPrefsService(),
       _socketService = socketService,
       super(HomepageSuccess.initial()) {
    on<GetHomepageData>(_onGetHomepageData);
    on<GetTrips>(_onGetTrips);
    on<GetTripDetail>(_onGetTripDetail);
    on<UpdateSocketLocation>(_onUpdateSocketLocation);
  }

  void _initSocketListeners(String childId) {
    _socketService.initSocket();
    _socketService.joinRoom(childId);

    _locationSubscription?.cancel();
    _locationSubscription = _socketService.locationStream.listen((data) {
      add(UpdateSocketLocation(data));
    });
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _socketService.disconnect();
    return super.close();
  }

  Future<void> _onGetHomepageData(
    GetHomepageData event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;

    final childId = _sharedPrefsService.getString('child_id');

    if (childId != null) {
      _initSocketListeners(childId);
    }

    final HomepageSuccess startingState = currentState is HomepageSuccess
        ? currentState
        : const HomepageSuccess.initial();

    emit(startingState.copyWith(isLoading: true));
    try {
      final response = await _homeRepository.getHomeData(childId: childId);
      if (response.isSuccess && response.data != null) {
        final homeData = response.data!;

        if (homeData.childName != null) {
          await _sharedPrefsService.setString(
            'child_name',
            homeData.childName!,
          );
        }
        if (homeData.childCode != null) {
          await _sharedPrefsService.setString(
            'child_code',
            homeData.childCode!,
          );
        }

        final tripsToUse = homeData.yesterdayTrips;
        _mapBloc.add(
          UpdateChildLocation(
            LatLng(homeData.currentLocation.lat, homeData.currentLocation.lng),
          ),
        );
        emit(
          startingState.copyWith(
            deviceInfo: homeData.deviceInfo,
            yesterdayTrips: tripsToUse,
            yesterdayTripSummary: homeData.yesterdayTripSummary,
            cards: homeData.cards,
            currentLocation: homeData.currentLocation,
            isLoading: false,
            hasNoChild: false,
          ),
        );
      } else {
        // Check if error is due to no child connected
        if (response.message.toLowerCase().contains('child') ||
            response.message.toLowerCase().contains('not found')) {
          emit(startingState.copyWith(isLoading: false, hasNoChild: true));
        } else {
          emit(HomepageError(message: response.message));
        }
      }
    } catch (e) {
      AppLogger.error('Error fetching home data: ${e.toString()}');
      emit(HomepageError(message: 'Failed to load home data: ${e.toString()}'));
    }
  }

  Future<void> _onGetTrips(GetTrips event, Emitter<HomepageState> emit) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;
    emit(currentState.copyWith(isLoadingTrips: true));
    try {
      final response = await _homeRepository.getTrips(
        childId: _sharedPrefsService.getString('child_id'),
        page: event.page,
        pageSize: event.pageSize,
        includePoints: true,
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

  Future<void> _onUpdateSocketLocation(
    UpdateSocketLocation event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;

    try {
      final data = event.locationData;
      AppLogger.info('[HomepageBloc] Processing socket location update: $data');

      // Helper to safely extract double value
      double toDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      // Extract lat/lng
      final lat = toDouble(data['lat'] ?? data['latitude']);
      final lng = toDouble(data['lng'] ?? data['longitude']);

      if (lat == 0.0 && lng == 0.0) {
        AppLogger.warning(
          '[HomepageBloc] Invalid location data: lat=$lat, lng=$lng',
        );
        return;
      }

      // Update MapBloc
      _mapBloc.add(UpdateChildLocation(LatLng(lat, lng)));

      // Extract other fields using the payload keys provided
      final address = data['address'] as String? ?? 'Unknown Location';
      // Map 'timestamp' from socket (or 'since') to the 'since' field in model
      final since =
          data['timestamp'] ??
          data['since'] ??
          DateTime.now().toIso8601String();
      // Extract place name logic
      String finalPlaceName = 'Unknown Place';
      final rawPlace =
          data['current_place'] ?? data['place_name'] ?? data['placeName'];

      if (rawPlace is Map) {
        finalPlaceName =
            rawPlace['placeName'] ?? rawPlace['place_name'] ?? 'Unknown Place';
      } else if (rawPlace is String) {
        finalPlaceName = rawPlace;
      }

      // Update state.currentLocation
      LocationInfo updatedLocation;
      if (currentState.currentLocation != null) {
        // Update existing location
        updatedLocation = currentState.currentLocation!.copyWith(
          lat: lat,
          lng: lng,
          address: address,
          placeName: finalPlaceName,
          since: since,
          // Preserving durationMinutes as it's not in the new payload, or default to 0
          durationMinutes: currentState.currentLocation!.durationMinutes,
        );
      } else {
        // Create new location if it doesn't exist
        updatedLocation = LocationInfo(
          lat: lat,
          lng: lng,
          address: address,
          placeName: finalPlaceName,
          since: since,
          durationMinutes: 0,
        );
      }

      emit(currentState.copyWith(currentLocation: updatedLocation));
    } catch (e, stackTrace) {
      AppLogger.error('Error handling socket location update: $e');
      AppLogger.error('Stack trace: $stackTrace');
    }
  }
}
