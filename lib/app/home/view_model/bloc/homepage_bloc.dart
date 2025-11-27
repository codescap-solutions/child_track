import 'dart:convert';
import 'dart:developer';

import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/home/model/home_model.dart';
import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/model/location_info_model.dart';
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
       super(MapInitial()) {
    on<GetHomepageData>(_onGetHomepageData);
    on<FetchChildCurrentDetails>(_onFetchChildCurrentDetails);
  }

  Future<void> _onGetHomepageData(
    GetHomepageData event,
    Emitter<HomepageState> emit,
  ) async {
    log('onGetHomepageData');
    emit(HomepageLoading());
    final response = await _homeRepository.getHomeData();
    if (response.isSuccess) {
      final homeData = response.data as HomeResponse;
      emit(
        HomepageSuccess(
          deviceInfo: homeData.deviceInfo,
          currentLocation: homeData.currentLocation,
          yesterdayTrips: homeData.yesterdayTrips,
        ),
      );
    } else {
      emit(HomepageError(message: response.message));
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
