import 'dart:async';
import 'package:child_track/app/home/model/home_model.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/model/location_info_model.dart';
import 'package:child_track/app/home/model/yesterday_trip_summary_model.dart';
import 'package:child_track/app/home/model/cards_model.dart';
import 'package:child_track/app/home/model/trip_list_model.dart';
import 'package:child_track/app/home/model/trip_detail_model.dart';
import 'package:child_track/app/home/model/child_tracking_snapshot.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_state.dart';
import 'package:child_track/app/home/view_model/home_repo.dart';
import 'package:child_track/app/map/view_model/map_bloc.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/socket_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'homepage_event.dart';

class HomepageBloc extends Bloc<HomepageEvent, HomepageState> {
  final HomeRepository _homeRepository;
  final MapBloc _mapBloc;
  final SharedPrefsService _sharedPrefsService;
  final SocketService _socketService;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _statusSubscription;
  Timer? _snapshotPollTimer;
  String? _joinedRoomChildId;

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
    on<RefreshTrackingSnapshot>(_onRefreshTrackingSnapshot);
  }

  void _initSocketListeners(String childId) {
    // Only tear down and recreate the socket when it isn't already connected.
    // This used to run unconditionally on every GetHomepageData dispatch —
    // including the internal 2.5s "progress fetch" that follows every initial
    // load, the "silent refresh" fired after a socket update, and the resume
    // refresh — which meant a perfectly healthy, actively-streaming connection
    // got disposed and rebuilt from scratch on a routine basis. Rebuilding the
    // connection takes a moment (disconnect + reconnect + re-auth + rejoin the
    // room), and any location_update the child emits during that window is
    // lost — most noticeable exactly while the child is moving and posting
    // updates frequently. Listener subscriptions are still refreshed every
    // call since they're cheap and idempotent.
    if (!_socketService.isConnected) {
      _socketService.initSocket();
    }
    // join_child_room was never paired with a leave when the parent switches
    // which child they're viewing, so the socket stayed joined to every
    // room ever viewed this session — the root cause of location/status
    // updates for a different linked child leaking into the current view
    // (see the child_id guards in _onUpdateSocketLocation/_onUpdateSocketStatus,
    // which are the actual fix; this just stops the stale traffic at the
    // source instead of only filtering it after arrival).
    if (_joinedRoomChildId != null && _joinedRoomChildId != childId) {
      _socketService.leaveRoom(_joinedRoomChildId!);
    }
    _socketService.joinRoom(childId);
    _joinedRoomChildId = childId;

    _locationSubscription?.cancel();
    _locationSubscription = _socketService.locationStream.listen((data) {
      add(UpdateSocketLocation(data));
    });

    _statusSubscription?.cancel();
    _statusSubscription = _socketService.statusStream.listen((data) {
      add(UpdateSocketStatus(data));
    });

    // The tracking-snapshot-driven stale/offline banner (see home_page.dart)
    // otherwise only refreshes on initial load, app resume, or manual
    // pull-to-refresh — so a child going stale/offline while the parent sits
    // on an already-open Home screen wouldn't be reflected until one of those
    // happens. Poll it lightly in the background instead.
    _snapshotPollTimer?.cancel();
    _snapshotPollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      add(const RefreshTrackingSnapshot());
    });
  }

  Future<void> _onRefreshTrackingSnapshot(
    RefreshTrackingSnapshot event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;

    final childId = _sharedPrefsService.getString('child_id');
    if (childId == null || childId.isEmpty) return;

    try {
      final response = await _homeRepository.getTrackingSnapshot(childId);
      if (response.isSuccess && response.data != null) {
        final freshState = state is HomepageSuccess
            ? state as HomepageSuccess
            : currentState;
        emit(
          freshState.copyWith(
            trackingSnapshot: ChildTrackingSnapshot.fromJson(response.data!),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error polling tracking snapshot: ${e.toString()}');
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    _snapshotPollTimer?.cancel();
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
          hasReachedMax: event.isProgressFetching
              ? startingState.hasReachedMax
              : false,
          tripsPage: event.isProgressFetching ? startingState.tripsPage : 1,
          waitingForSilentSyncResponse: !event.isProgressFetching,
        ),
      );
    }

    try {
      final response = await _homeRepository.getHomeData(childId: childId);

      ChildTrackingSnapshot? trackingSnapshot;
      if (childId != null) {
        final snapshotResponse = await _homeRepository.getTrackingSnapshot(
          childId,
        );
        if (snapshotResponse.isSuccess && snapshotResponse.data != null) {
          trackingSnapshot = ChildTrackingSnapshot.fromJson(
            snapshotResponse.data!,
          );
        }
      }

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
            trackingSnapshot: trackingSnapshot ?? freshState.trackingSnapshot,
            isLoading: false,
            hasNoChild: false,
            waitingForSilentSyncResponse:
                (event.isSilentRefresh || event.isProgressFetching)
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
          emit(
            startingState.copyWith(
              isLoading: false,
              hasNoChild: true,
              waitingForSilentSyncResponse: false,
            ),
          );
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
      final freshState = state is HomepageSuccess
          ? state as HomepageSuccess
          : startingState;
      if (event.isProgressFetching || event.isSilentRefresh) {
        emit(freshState.copyWith(isLoading: false));
      } else {
        emit(
          HomepageError(message: 'Failed to load home data: ${e.toString()}'),
        );
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

      // The socket connection accumulates a joined room for every child the
      // parent has ever viewed this session (join_child_room is never paired
      // with a leave when switching), so a location ping from a DIFFERENT
      // linked child can still arrive here well after the parent has moved
      // on to viewing someone else. The server always includes child_id in
      // this payload — drop anything that doesn't match who's currently
      // selected instead of overwriting the map with the wrong child.
      final eventChildId = data['child_id']?.toString();
      final selectedChildId = _sharedPrefsService.getString('child_id');
      if (eventChildId != null &&
          selectedChildId != null &&
          eventChildId != selectedChildId) {
        AppLogger.info(
          '[HomepageBloc] Ignoring location_update for $eventChildId — currently viewing $selectedChildId',
        );
        return;
      }

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

      // Same cross-child leakage risk as _onUpdateSocketLocation — the
      // socket stays joined to every room the parent has viewed this
      // session, so a status_update for a different linked child can still
      // arrive here.
      final eventChildId = data['child_id']?.toString();
      final selectedChildId = _sharedPrefsService.getString('child_id');
      if (eventChildId != null &&
          selectedChildId != null &&
          eventChildId != selectedChildId) {
        AppLogger.info(
          '[HomepageBloc] Ignoring status_update for $eventChildId — currently viewing $selectedChildId',
        );
        return;
      }

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
    if (currentState is HomepageSuccess &&
        currentState.currentLocation != null) {
      final updatedLocation = currentState.currentLocation!.copyWith(
        placeName: event.newName,
      );
      emit(currentState.copyWith(currentLocation: updatedLocation));
    }
  }
}
