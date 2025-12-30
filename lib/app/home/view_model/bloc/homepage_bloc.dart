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
  final SocketService _socketService = SocketService();
  StreamSubscription? _locationSubscription;
  StreamSubscription? _tripSubscription;
  Timer? _pollingTimer;

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
    on<UpdateSocketLocation>(_onUpdateSocketLocation);
    on<UpdateSocketTrip>(_onUpdateSocketTrip);
  }

  void _initSocketListeners(String childId) {
    _socketService.initSocket();
    _socketService.joinRoom(childId);

    _locationSubscription?.cancel();
    _locationSubscription = _socketService.locationStream.listen((data) {
      add(UpdateSocketLocation(data));
    });

    _tripSubscription?.cancel();
    _tripSubscription = _socketService.tripStream.listen((data) {
      add(UpdateSocketTrip(data));
    });
  }

  void _startPolling(String? childId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      add(GetHomepageData());
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    _locationSubscription?.cancel();
    _tripSubscription?.cancel();
    _socketService.disconnect();
    return super.close();
  }

  Future<void> _onGetHomepageData(
    GetHomepageData event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;

    // Get child_id from event or SharedPreferences
    final childId = _sharedPrefsService.getString('child_id');
    //event.childId ?? _sharedPrefsService.getString('child_id');

    // If no child_id, check if parent has children
    // if (childId == null) {
    //   final childrenCount = _sharedPrefsService.getInt('children_count') ?? 0;
    //   if (childrenCount == 0) {
    //     emit(currentState.copyWith(
    //       isLoading: false,
    //       hasNoChild: true,
    //     ));
    //     return;
    //   }
    // }

    // Start polling on first call
    if (_pollingTimer == null || !_pollingTimer!.isActive) {
      _startPolling(childId);
      // Initialize socket listeners
      if (childId != null) {
        _initSocketListeners(childId);
      }
    }

    emit(currentState.copyWith(isLoading: true));
    try {
      final response = await _homeRepository.getHomeData(childId: childId);
      if (response.isSuccess && response.data != null) {
        final homeData = response.data!;
        // Use sample data if yesterdayTrips is null or empty
        final tripsToUse = homeData.yesterdayTrips;

        emit(
          HomepageSuccess(
            deviceInfo: homeData.deviceInfo,
            // currentLocation: homeData.currentLocation,
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
          emit(currentState.copyWith(isLoading: false, hasNoChild: true));
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
        childId: _sharedPrefsService.getString('child_id'),
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

  Future<void> _onUpdateSocketLocation(
    UpdateSocketLocation event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;

    try {
      final data = event.locationData;
      // Parse data to LocationInfoModel or just extract fields
      // Assuming data matches structure: {lat, lng, ...}

      // We need to map the raw socket data to our models.
      // This might require a helper or constructing the model here.
      // For now, let's update the MapBloc and CurrentLocation if possible.

      double lat = (data['lat'] ?? data['latitude'] as num).toDouble();
      double lng = (data['lng'] ?? data['longitude'] as num).toDouble();

      _mapBloc.add(UpdateChildLocation(LatLng(lat, lng)));

      // Update state.currentLocation
      // Note: Data structure from socket might differ from REST response.
      // We should ideally have a common parser.
      // Assuming we can patch minimal info:

      final updatedLocation = currentState.currentLocation?.copyWith(
        lat: lat,
        lng: lng,
        // Update other fields if available
      );

      if (updatedLocation != null) {
        emit(currentState.copyWith(currentLocation: updatedLocation));
      }
    } catch (e) {
      AppLogger.error('Error handling socket location update: $e');
    }
  }

  Future<void> _onUpdateSocketTrip(
    UpdateSocketTrip event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;

    try {
      final tripData = event.tripData;
      // Handle trip updates
      // IF tripData['id'] == currentState.selectedTripId, update details

      final tripId = tripData['trip_id'] ?? tripData['_id'];
      if (tripId != null && tripId == currentState.selectedTripId) {
        // This assumes we can parse tripData to TripDetailModel or similar
        // For now, let's just trigger a re-fetch or patch if model is compatible.
        // Or emit new state if we can construct the object.

        // Assuming we could just refresh:
        add(GetTripDetail(tripId: tripId));
      }

      // Also might want to refresh the list if a trip ended/started
      if (tripData['status'] == 'ended' || tripData['status'] == 'started') {
        add(GetTrips(page: 1, pageSize: 10)); // Refresh list
        add(GetHomepageData()); // Refresh summary
      }
    } catch (e) {
      AppLogger.error('Error handling socket trip update: $e');
    }
  }
}
