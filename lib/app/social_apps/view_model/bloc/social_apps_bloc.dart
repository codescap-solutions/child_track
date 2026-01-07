import 'package:child_track/app/social_apps/model/app_usage_model.dart';
import 'package:child_track/app/social_apps/view_model/social_apps_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'social_apps_event.dart';
part 'social_apps_state.dart';

class SocialAppsBloc extends Bloc<SocialAppsEvent, SocialAppsState> {
  final SocialAppsRepository _repository;
  final SharedPrefsService _sharedPrefsService;
  final ChildInfoService _childInfoService;

  SocialAppsBloc({
    required SocialAppsRepository repository,
    required SharedPrefsService sharedPrefsService,
    required ChildInfoService childInfoService,
  }) : _repository = repository,
       _sharedPrefsService = sharedPrefsService,
       _childInfoService = childInfoService,
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
        var appUsageResponse = response.data!;

        try {
          final localApps = await _childInfoService.getScreenTime();
          final iconMap = <String, String>{};
          for (var app in localApps) {
            if (app.iconBase64 != null) {
              iconMap[app.package] = app.iconBase64!;
            }
          }

          final enrichedDailyUsage = <String, List<AppUsageItem>>{};
          appUsageResponse.dailyUsage.forEach((date, items) {
            enrichedDailyUsage[date] = items.map((item) {
              final icon = iconMap[item.packageName];
              if (icon != null) {
                return AppUsageItem(
                  date: item.date,
                  appName: item.appName,
                  packageName: item.packageName,
                  usageTime: item.usageTime,
                  usageTimeFormatted: item.usageTimeFormatted,
                  platform: item.platform,
                  openCount: item.openCount,
                  iconBase64: icon,
                );
              }
              return item;
            }).toList();
          });

          appUsageResponse = AppUsageResponse(
            userId: appUsageResponse.userId,
            totalUsageTime: appUsageResponse.totalUsageTime,
            totalUsageTimeFormatted: appUsageResponse.totalUsageTimeFormatted,
            totalApps: appUsageResponse.totalApps,
            dailyUsage: enrichedDailyUsage,
          );
        } catch (e) {
          // Continue with original data if icon fetch fails
        }

        emit(
          SocialAppsLoaded(
            data: appUsageResponse,
            selectedDate: event.date,
            currentDate: DateTime.now(),
          ),
        );
      } else {
        emit(SocialAppsError(response.message ));
      }
    } catch (e) {
      emit(SocialAppsError(e.toString()));
    }
  }
}
