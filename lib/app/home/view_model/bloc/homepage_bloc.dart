import 'dart:developer';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/home/model/home_model.dart';
import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/model/location_info_model.dart';
import 'package:child_track/app/home/model/yesterday_trip_summary_model.dart';
import 'package:child_track/app/home/model/cards_model.dart';
import 'package:child_track/app/home/view_model/home_repo.dart';
import 'package:child_track/app/map/view_model/map_bloc.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'homepage_event.dart';
part 'homepage_state.dart';

class HomepageBloc extends Bloc<HomepageEvent, HomepageState> {
  final HomeRepository _homeRepository;
  final MapBloc _mapBloc;
  HomepageBloc({
    required HomeRepository homeRepository,
    required MapBloc mapBloc,
  }) : _homeRepository = homeRepository,
       _mapBloc = mapBloc,
       super(HomepageSuccess.initial()) {
    on<GetHomepageData>(_onGetHomepageData);
    on<FetchChildCurrentDetails>(_onFetchChildCurrentDetails);
  }

  Future<void> _onGetHomepageData(
    GetHomepageData event,
    Emitter<HomepageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomepageSuccess) return;
    emit(currentState.copyWith(isLoading: true));
    try {
      final response = await _homeRepository.getHomeData(
        childId: event.childId,
      );
      if (response.isSuccess && response.data != null) {
        final homeData = response.data!;
        emit(
          HomepageSuccess(
            deviceInfo: homeData.deviceInfo,
            currentLocation: homeData.currentLocation,
            yesterdayTrips: homeData.yesterdayTrips,
            yesterdayTripSummary: homeData.yesterdayTripSummary,
            cards: homeData.cards,
          ),
        );
      } else {
        emit(HomepageError(message: response.message));
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
}
