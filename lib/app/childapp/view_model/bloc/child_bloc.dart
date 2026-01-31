import 'dart:async';
import 'package:child_track/app/childapp/model/scree_time_model.dart';
import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:geolocator/geolocator.dart';
part 'child_event.dart';
part 'child_state.dart';

class ChildBloc extends Bloc<ChildEvent, ChildState> {
  final ChildInfoService _deviceInfoService;
  final ChildRepo _childRepo;
  final ChildGoogleMapsRepo _childLocationRepo;
  final SharedPrefsService _sharedPrefsService;

  StreamSubscription<Position>? _locationSubscription;

  ChildBloc({
    required ChildRepo childRepo,
    required ChildGoogleMapsRepo childLocationRepo,
    required SharedPrefsService sharedPrefsService,
    required ChildInfoService deviceInfoService,
  }) : _deviceInfoService = deviceInfoService,
       _childRepo = childRepo,
       _childLocationRepo = childLocationRepo,
       _sharedPrefsService = sharedPrefsService,
       super(ChildDeviceInfoLoaded.initial()) {
    on<LoadDeviceInfo>(_onLoadDeviceInfo);
    on<PostDeviceInfo>(_onPostDeviceInfo);
    on<GetScreenTime>(_onGetScreenTime);
    on<PostScreenTime>(_onPostScreenTime);
    on<OpenUsageSettings>(_onOpenUsageSettings);
    on<CheckUsagePermission>(_onCheckUsagePermission);
    on<GetChildLocation>(_onGetChildLocation);
    on<PostChildLocation>(_onPostChildLocation);
    // on<StartTripTracking>(_onStartTripTracking);
    // on<StopTripTracking>(_onStopTripTracking);
    // on<UpdateTripLocation>(_onUpdateTripLocation);
  }

  void onInitialize() {
    final childId = _sharedPrefsService.getString('child_id');
    final parentId = _sharedPrefsService.getString('parent_id');

    if (childId != null &&
        childId.isNotEmpty &&
        (parentId == null || parentId.isEmpty)) {
      AppLogger.info('ChildBloc: Initializing for child_id: $childId');
      add(LoadDeviceInfo());
      add(CheckUsagePermission());
      add(GetChildLocation());
    } else {
      AppLogger.info(
        'ChildBloc: Skipping initialization - not logged in as child',
      );
    }
  }

  //get child location
  Future<void> _onGetChildLocation(
    GetChildLocation event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;
    try {
      final location = await _childLocationRepo.getChildLocation();
      if (location != null) {
        emit(currentState.copyWith(childLocation: location));
        final lastPosted = currentState.lastPostedLocation;
        final distance = lastPosted != null
            ? await _childLocationRepo.getDistanceBetweenTwoPoints(
                lastPosted,
                location,
              )
            : 0.0;
        AppLogger.info('new logic: get child location $distance meters');

        if (lastPosted == null || distance >= 3) {
          emit(currentState.copyWith(lastPostedLocation: location));
          AppLogger.info('new logic: Posting child location $location');
          add(PostChildLocation(childLocation: location));
        }
        if (_locationSubscription == null) {
          _startChildLocationStream();
        }
      }
    } catch (e) {
      AppLogger.error('Failed to get child location: ${e.toString()}');
    }
  }

  void _startChildLocationStream() {
    _stopChildLocationStream();
    if (isClosed || !_isChildLoggedIn()) return;

    _locationSubscription = _childLocationRepo
        .getPositionStream(2)
        ?.listen(
          (Position position) async {
            AppLogger.info('new logic: get child stream');
            if (isClosed || !_isChildLoggedIn()) {
              AppLogger.info('new logic: get child stream closed');
              _stopChildLocationStream();
              return;
            }
            final currentState = state;
            if (currentState is ChildDeviceInfoLoaded) {
              AppLogger.info(
                'new logic: get child stream loaded ${position.latitude} ${position.longitude} get called',
              );
              add(GetChildLocation());
            }
          },
          onError: (e) {
            AppLogger.error('new logic: Location stream error: $e');
          },
        );
  }

  void _stopChildLocationStream() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  bool _isChildLoggedIn() {
    final childId = _sharedPrefsService.getString('child_id');
    return childId != null && childId.isNotEmpty;
  }

  @override
  Future<void> close() {
    _stopChildLocationStream();
    return super.close();
  }

  // to post child location to api in background
  Future<void> _onPostChildLocation(
    PostChildLocation event,
    Emitter<ChildState> emit,
  ) async {
    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        AppLogger.warning('new logic: child_id is null, post location');
        return;
      }

      // Get dynamic address and place name from coordinates
      final locationInfo = await _childLocationRepo.getAddressAndPlaceName(
        event.childLocation.latitude,
        event.childLocation.longitude,
      );
      final requestBody = {
        "address": locationInfo?['address'] ?? locationInfo?.values.first,
        "place_name": locationInfo?['place_name'] ?? locationInfo?.values.last,
        "child_id": childId,
        "lat": event.childLocation.latitude,
        "lng": event.childLocation.longitude,
        "accuracy_m": event.childLocation.accuracy,
        "speed_mps": event.childLocation.speed,
        "bearing": event.childLocation.heading,
        "timestamp": DateTime.now().toIso8601String(),
      };
      AppLogger.info(
        'new logic: child location posting to api: locationInfo: $locationInfo, reqest $requestBody',
      );

      await _childRepo.postChildLocation(requestBody);
    } catch (e) {
      AppLogger.error(
        'new logic: Failed to post child location: ${e.toString()}',
      );
    }
  }

  // to load device info
  Future<void> _onLoadDeviceInfo(
    LoadDeviceInfo event,
    Emitter<ChildState> emit,
  ) async {
    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      emit(ChildDeviceInfoLoaded(deviceInfo: deviceInfo));
      add(PostDeviceInfo(deviceInfo: deviceInfo));
    } catch (e) {
      AppLogger.error('Failed to load device info: ${e.toString()}');
    }
  }

  // to post device info
  Future<void> _onPostDeviceInfo(
    PostDeviceInfo event,
    Emitter<ChildState> emit,
  ) async {
    try {
      final childId = _sharedPrefsService.getString('child_id');
      final requestBody = {
        "child_id": childId,
        "battery_percentage": event.deviceInfo.batteryPercentage,
        "network_status": event.deviceInfo.networkStatus,
        "network_type": event.deviceInfo.networkType,
        "sound_profile": event.deviceInfo.soundProfile,
        "is_online": event.deviceInfo.isOnline,
        "timestamp": DateTime.now().toIso8601String(),
      };
      await _childRepo.postChildData(requestBody);
    } catch (e) {
      AppLogger.error('Failed to post device info: ${e.toString()}');
    }
  }

  // to get permission to get child used apps
  Future<void> _onCheckUsagePermission(
    CheckUsagePermission event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) {
      AppLogger.warning(
        'ChildBloc: Ignore check permission, state is $currentState',
      );
      return;
    }
    AppLogger.info('ChildBloc: Checking usage permission...');
    final hasPermission = await _deviceInfoService.checkUsagePermission();
    AppLogger.info('ChildBloc: Usage permission result: $hasPermission');
    emit(currentState.copyWith(hasUsagePermission: hasPermission));
    if (hasPermission) {
      add(GetScreenTime());
    }
  }

  // to get child used apps
  Future<void> _onGetScreenTime(
    GetScreenTime event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;

    // Check permission first
    if (!currentState.hasUsagePermission) {
      final hasPermission = await _deviceInfoService.checkUsagePermission();
      if (!hasPermission) {
        emit(currentState.copyWith(hasUsagePermission: false, screenTime: []));
        return;
      } else {
        emit(currentState.copyWith(hasUsagePermission: true));
      }
    }

    try {
      final installedApps = await _deviceInfoService.getInstalledApps();
      final screenTimeUsage = await _deviceInfoService.getScreenTime();

      // Popular apps allowlist (package names)
      final allowList = {
        'com.google.android.youtube', // YouTube
        'com.facebook.katana', // Facebook
        'com.instagram.android', // Instagram
        'com.whatsapp', // WhatsApp
        'com.snapchat.android', // Snapchat
        'com.zhiliaoapp.musically', // TikTok
        'org.telegram.messenger', // Telegram
        'com.twitter.android', // Twitter/X
        'com.google.android.apps.maps', // Maps
        'com.spotify.music', // Spotify
        'com.netflix.mediaclient', // Netflix
      };

      // Create a map of usage data for quick lookup
      final usageMap = {for (var app in screenTimeUsage) app.package: app};

      // Merge installed apps with usage data
      final List<AppScreenTimeModel> mergedScreenTime = [];

      for (var app in installedApps) {
        bool shouldInclude =
            !app.isSystemApp || allowList.contains(app.packageName);

        if (shouldInclude) {
          final usageModel = usageMap[app.packageName];
          final seconds = usageModel?.seconds ?? 0;
          final lastTimeUsed = usageModel?.lastTimeUsed ?? 0;

          mergedScreenTime.add(
            AppScreenTimeModel(
              package: app.packageName,
              appName: app.appName,
              isSystemApp: app.isSystemApp,
              seconds: seconds,
              lastTimeUsed: lastTimeUsed,
              iconBase64: usageModel?.iconBase64,
            ),
          );
        }
        usageMap.remove(app.packageName);
      }

      // Add remaining apps from usageMap
      usageMap.forEach((package, usageModel) {
        mergedScreenTime.add(
          usageModel.copyWith(
            appName: usageModel.appName.isNotEmpty
                ? usageModel.appName
                : package,
          ),
        );
      });

      // Sort by seconds
      mergedScreenTime.sort((a, b) => b.seconds.compareTo(a.seconds));

      emit(currentState.copyWith(screenTime: mergedScreenTime));
      add(PostScreenTime(appScreenTimes: mergedScreenTime));
    } catch (e) {
      AppLogger.error('Failed to get screen time: ${e.toString()}');
    }
  }

  // to post child used apps
  Future<void> _onPostScreenTime(
    PostScreenTime event,
    Emitter<ChildState> emit,
  ) async {
    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        AppLogger.warning(
          'ChildBloc: child_id is null, stopping screen time timer',
        );
        return;
      }

      // 1. Sync Screentime Data (Critical Path)
      // Send usage data without icons
      final appsData = event.appScreenTimes.map((app) {
        final json = app.toJson();
        json.remove('icon'); // Remove icon from sync payload
        return json;
      }).toList();

      final requestBody = {
        "child_id": childId,
        "date": DateTime.now().toIso8601String().split('T')[0],
        "total_seconds": event.appScreenTimes.fold(
          0,
          (sum, app) => sum + app.seconds,
        ),
        "apps": appsData,
      };

      await _childRepo.postScreenTime(requestBody);
      AppLogger.info('ChildBloc: Screentime synced successfully');

      // 2. Check Available Icons (Cache Refresh)
      final iconsResponse = await _childRepo.getAvailableIcons();
      Set<String> availableIcons = {};

      if (iconsResponse.isSuccess && iconsResponse.data != null) {
        final data = iconsResponse.data!;
        if (data['data'] != null && data['data']['packages'] != null) {
          final packages = List<String>.from(data['data']['packages']);
          availableIcons = packages.toSet();
        }
      }

      // 3. Upload New Icons (Background)
      final Map<String, String> iconsToUpload = {};

      for (var app in event.appScreenTimes) {
        if (!availableIcons.contains(app.package) &&
            app.iconBase64 != null &&
            app.iconBase64!.isNotEmpty) {
          iconsToUpload[app.package] = app.iconBase64!;
        }
      }

      if (iconsToUpload.isNotEmpty) {
        AppLogger.info(
          'ChildBloc: Uploading ${iconsToUpload.length} missing icons',
        );
        await _childRepo.uploadIcons(iconsToUpload);
      }
    } catch (e) {
      AppLogger.error('Failed to post screen time: ${e.toString()}');
    }
  }

  // to open usage settings to allow app to access usage data
  Future<void> _onOpenUsageSettings(
    OpenUsageSettings event,
    Emitter<ChildState> emit,
  ) async {
    await _deviceInfoService.openUsageSettings();
  }

  void stopChildTracking() {}
}
