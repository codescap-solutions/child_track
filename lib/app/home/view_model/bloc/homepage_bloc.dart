import 'dart:async';
import 'package:child_track/app/home/model/home_model.dart';
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
  StreamSubscription? _statusSubscription;

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
    on<UpdateSocketStatus>(_onUpdateSocketStatus);
    on<UpdateCurrentLocationName>(_onUpdateCurrentLocationName);
  }

  void _initSocketListeners(String childId) {
    _socketService.initSocket();
    _socketService.joinRoom(childId);

    _locationSubscription?.cancel();
    _locationSubscription = _socketService.locationStream.listen((data) {
      add(UpdateSocketLocation(data));
    });

    _statusSubscription?.cancel();
    _statusSubscription = _socketService.statusStream.listen((data) {
      add(UpdateSocketStatus(data));
    });
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
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

    if (!event.isSilentRefresh) {
      emit(
        startingState.copyWith(
          isLoading: true,
          trips: event.isProgressFetching ? startingState.trips : [],
          hasReachedMax: event.isProgressFetching ? startingState.hasReachedMax : false,
          tripsPage: event.isProgressFetching ? startingState.tripsPage : 1,
          waitingForSilentSyncResponse: !event.isProgressFetching,
        ),
      );
    }

    try {
      final response = await _homeRepository.getHomeData(childId: childId);

      // Get the freshest state after the async gap to prevent overwriting other events
      final freshState = state is HomepageSuccess
          ? state as HomepageSuccess
          : startingState;

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
          freshState.copyWith(
            deviceInfo: homeData.deviceInfo,
            yesterdayTrips: tripsToUse,
            yesterdayTripSummary: homeData.yesterdayTripSummary,
            cards: homeData.cards,
            currentLocation: homeData.currentLocation,
            webFilteringEnabled: homeData.webFilteringEnabled,
            childAvatar: homeData.childAvatar,
            features: homeData.features,
            todayRoute: homeData.todayRoute,
            screentimeToday: homeData.screentimeToday,
            sharedChildren: homeData.sharedChildren ?? [],
            activeTrip: homeData.activeTrip,
            isLoading: false,
            hasNoChild: false,
            waitingForSilentSyncResponse: (event.isSilentRefresh || event.isProgressFetching)
                ? false
                : freshState.waitingForSilentSyncResponse,
          ),
        );

        // If this was the first load (not silent, not progress fetching), call again with progress fetching
        if (!event.isSilentRefresh && !event.isProgressFetching) {
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (!isClosed) {
              add(const GetHomepageData(isProgressFetching: true));
            }
          });
        }
      } else {
        // Check if error is due to no child connected
        if (response.message.toLowerCase().contains('child') ||
            response.message.toLowerCase().contains('not found')) {
          emit(startingState.copyWith(isLoading: false, hasNoChild: true, waitingForSilentSyncResponse: false));
        } else {
          if (event.isProgressFetching || event.isSilentRefresh) {
            emit(freshState.copyWith(isLoading: false));
          } else {
            emit(HomepageError(message: response.message));
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error fetching home data: ${e.toString()}');
      final freshState = state is HomepageSuccess ? state as HomepageSuccess : startingState;
      if (event.isProgressFetching || event.isSilentRefresh) {
        emit(freshState.copyWith(isLoading: false));
      } else {
        emit(HomepageError(message: 'Failed to load home data: ${e.toString()}'));
      }
    }
  }

  Future<void> _onGetTrips(GetTrips event, Emitter<HomepageState> emit) async {
    AppLogger.info('💡 [_onGetTrips] Called with page: ${event.page}');
    final currentState = state;

    if (currentState is! HomepageSuccess) {
      AppLogger.warning(
        '💡 [_onGetTrips] Returned early: state is not HomepageSuccess (${currentState.runtimeType})',
      );
      return;
    }

    // If we've already reached max and trying to fetch more (not refresh), return
    if (currentState.hasReachedMax && event.page != 1) {
      AppLogger.warning(
        '💡 [_onGetTrips] Returned early: hasReachedMax is true',
      );
      return;
    }

    // If already loading trips, avoid duplicate requests
    if (currentState.isLoadingTrips) {
      AppLogger.warning(
        '💡 [_onGetTrips] Returned early: isLoadingTrips is true',
      );
      return;
    }

    AppLogger.info('💡 [_onGetTrips] Proceeding to fetch trips...');
    emit(currentState.copyWith(isLoadingTrips: true));

    try {
      final childId = _sharedPrefsService.getString('child_id');
      AppLogger.info('💡 [_onGetTrips] using childId: $childId');

      final response = await _homeRepository.getTrips(
        childId: childId,
        page: event.page,
        pageSize: event.pageSize,
        includePoints: true,
      );

      if (response.isSuccess && response.data != null) {
        // Get freshet state here too
        final freshState = state is HomepageSuccess
            ? state as HomepageSuccess
            : currentState;

        final tripsData = response.data!;
        final newTrips = tripsData.trips;
        final totalItems = tripsData.totalItems;

        List<Trip> allTrips;
        if (event.page == 1) {
          allTrips = newTrips;
        } else {
          allTrips = List.of(freshState.trips)..addAll(newTrips);
        }

        final hasReachedMax = allTrips.length >= totalItems;

        emit(
          freshState.copyWith(
            trips: allTrips,
            tripsPage: tripsData.page,
            tripsPageSize: tripsData.pageSize,
            tripsTotalItems: totalItems,
            isLoadingTrips: false,
            hasReachedMax: hasReachedMax,
          ),
        );
      } else {
        final freshState = state is HomepageSuccess
            ? state as HomepageSuccess
            : currentState;
        emit(freshState.copyWith(isLoadingTrips: false));
        AppLogger.error('Failed to fetch trips: ${response.message}');
      }
    } catch (e) {
      final freshState = state is HomepageSuccess
          ? state as HomepageSuccess
          : currentState;
      AppLogger.error('Error fetching trips: ${e.toString()}');
      emit(freshState.copyWith(isLoadingTrips: false));
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
      final childId = _sharedPrefsService.getString('child_id');
      final response = await _homeRepository.getTripDetail(
        event.tripId,
        childId: childId,
      );

      final freshState = state is HomepageSuccess
          ? state as HomepageSuccess
          : currentState;
      if (response.isSuccess && response.data != null) {
        emit(
          freshState.copyWith(
            selectedTripDetail: response.data!,
            isLoadingTripDetail: false,
          ),
        );
      } else {
        emit(freshState.copyWith(isLoadingTripDetail: false));
        AppLogger.error('Failed to fetch trip detail: ${response.message}');
      }
    } catch (e) {
      final freshState = state is HomepageSuccess
          ? state as HomepageSuccess
          : currentState;
      AppLogger.error('Error fetching trip detail: ${e.toString()}');
      emit(freshState.copyWith(isLoadingTripDetail: false));
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

      if (currentState.waitingForSilentSyncResponse) {
        emit(currentState.copyWith(waitingForSilentSyncResponse: false));
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (!isClosed) {
            add(const GetHomepageData(isSilentRefresh: true));
          }
        });
      }

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
          data['last_update'] ??
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

  Future<void> _onUpdateSocketStatus(
    UpdateSocketStatus event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;

    try {
      final data = event.statusData;
      AppLogger.info('[HomepageBloc] Processing socket status update: $data');

      if (currentState.waitingForSilentSyncResponse) {
        emit(currentState.copyWith(waitingForSilentSyncResponse: false));
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (!isClosed) {
            add(const GetHomepageData(isSilentRefresh: true));
          }
        });
      }

      final deviceInfo = currentState.deviceInfo;
      if (deviceInfo == null) return;

      final updatedDeviceInfo = deviceInfo.copyWith(
        batteryPercentage: data['battery_percentage'] as int?,
        networkStatus: data['network_status'] as String?,
        networkType: data['network_type'] as String?,
        soundProfile: data['sound_profile'] as String?,
        isOnline: data['is_online'] as bool?,
        isCharging: data['is_charging'] as bool?,
        onlineSince: data['last_update'] as String?,
      );

      emit(currentState.copyWith(deviceInfo: updatedDeviceInfo));
    } catch (e) {
      AppLogger.error('Error handling socket status update: $e');
    }
  }

  void _onUpdateCurrentLocationName(
    UpdateCurrentLocationName event,
    Emitter<HomepageState> emit,
  ) {
    final currentState = state;
    if (currentState is HomepageSuccess && currentState.currentLocation != null) {
      final updatedLocation = currentState.currentLocation!.copyWith(
        placeName: event.newName,
      );
      emit(currentState.copyWith(currentLocation: updatedLocation));
    }
  }
}
