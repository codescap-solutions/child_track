import 'package:child_track/app/social_apps/model/app_usage_model.dart';
import 'package:child_track/app/social_apps/view_model/social_apps_repo.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'social_apps_event.dart';
part 'social_apps_state.dart';

class SocialAppsBloc extends Bloc<SocialAppsEvent, SocialAppsState> {
  final SocialAppsRepository _repository;
  final SharedPrefsService _sharedPrefsService;

  SocialAppsBloc({
    required SocialAppsRepository repository,
    required SharedPrefsService sharedPrefsService,
  }) : _repository = repository,
       _sharedPrefsService = sharedPrefsService,
       super(SocialAppsInitial()) {
    on<FetchAppUsage>(_onFetchAppUsage);
  }

  Future<void> _onFetchAppUsage(
    FetchAppUsage event,
    Emitter<SocialAppsState> emit,
  ) async {
    emit(SocialAppsLoading());

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        emit(const SocialAppsError('No child selected'));
        return;
      }

      final response = await _repository.getAppUsage(
        childId: childId,
        date: event.date,
      );

      if (response.isSuccess) {
        emit(
          SocialAppsLoaded(
            data: response.data!,
            selectedDate: event.date,
            currentDate: DateTime.now(),
          ),
        );
      } else {
        emit(SocialAppsError(response.message ?? 'Failed to fetch app usage'));
      }
    } catch (e) {
      emit(SocialAppsError(e.toString()));
    }
  }
}
