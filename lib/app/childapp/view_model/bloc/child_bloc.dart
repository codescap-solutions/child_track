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
    on<StartTripTracking>(_onStartTripTracking);
    on<StopTripTracking>(_onStopTripTracking);
    on<UpdateTripLocation>(_onUpdateTripLocation);
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

        if (lastPosted == null || distance >= 10) {
          emit(currentState.copyWith(lastPostedLocation: location));
          AppLogger.info('new logic: Posting child location $location');
          add(PostChildLocation(childLocation: location));

          // Trip Logic
          if (currentState.isTripTracking) {
            add(UpdateTripLocation(location: location));
          } else {
            // Start trip if not already tracking and moved > 10m
            _processTripStartLogic(location, currentState, emit);
          }
        }
        if (_locationSubscription == null) {
          _startChildLocationStream();
        }
      }
    } catch (e) {
      AppLogger.error('Failed to get child location: ${e.toString()}');
    }
  }

  void _processTripStartLogic(
    Position location,
    ChildDeviceInfoLoaded currentState,
    Emitter<ChildState> emit,
  ) {
    // 1. FILTER NOISE
    if (location.accuracy > 30.0) {
      AppLogger.info(
        'TripCandidate: Ignored poor accuracy point (${location.accuracy}m)',
      );
      return;
    }

    // 2. SLIDING WINDOW MANAGEMENT
    List<Position> newWindow = List.from(currentState.candidatePoints);
    newWindow.add(location);

    // Keep last 15 points max (to allow catching 100m vehicle moves with ~10m gaps)
    if (newWindow.length > 15) {
      newWindow.removeAt(0);
    }

    // 3. CHECK FOR RESET (TIMEOUT)
    if (newWindow.isNotEmpty) {
      final lastPoint = newWindow.last;

      // Check gap from previous point to detect stale window
      if (newWindow.length > 1) {
        final prevPoint = newWindow[newWindow.length - 2];
        final gap = lastPoint.timestamp
            .difference(prevPoint.timestamp)
            .inSeconds;
        // If we haven't moved 10m in 5 minutes, reset window.
        // Child might have stopped and started again later.
        if (gap > 300) {
          AppLogger.info(
            'TripCandidate: Gap too large ($gap s), resetting window',
          );
          newWindow = [location];
        }
      }
    }

    // 4. ANALYZE WINDOW SIGNALS
    if (newWindow.length < 3) {
      // Not enough points yet
      emit(
        currentState.copyWith(
          candidatePoints: newWindow,
          detectionStatus: TripDetectionStatus.candidate,
        ),
      );
      return;
    }

    // Calculate Metrics
    double totalDistance = 0;
    for (int i = 0; i < newWindow.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        newWindow[i].latitude,
        newWindow[i].longitude,
        newWindow[i + 1].latitude,
        newWindow[i + 1].longitude,
      );
    }

    final startPoint = newWindow.first;
    final endPoint = newWindow.last;
    final straightDist = Geolocator.distanceBetween(
      startPoint.latitude,
      startPoint.longitude,
      endPoint.latitude,
      endPoint.longitude,
    );

    final durationSeconds = endPoint.timestamp
        .difference(startPoint.timestamp)
        .inSeconds;

    // Avoid division by zero or super short duration
    if (durationSeconds < 1) return;

    final avgSpeed = totalDistance / durationSeconds;
    final consistencyRatio = totalDistance > 0
        ? straightDist / totalDistance
        : 0.0;

    AppLogger.info(
      'TripCandidate: Window=${newWindow.length} pts, Dur=${durationSeconds}s, '
      'Dist=${totalDistance.toStringAsFixed(1)}m, Speed=${avgSpeed.toStringAsFixed(1)}m/s, '
      'Consistency=${consistencyRatio.toStringAsFixed(2)}',
    );

    // 5. DETERMINE MODE & CHECK RULES
    TripMode? estimatedMode;
    bool rulesMet = false;

    // Mode Thresholds
    // Walking: > 30m, Speed 0.6-1.8 m/s, Duration > 30s
    if (avgSpeed >= 0.6 && avgSpeed <= 1.8) {
      if (totalDistance >= 30 && durationSeconds >= 30) {
        estimatedMode = TripMode.walking;
        rulesMet = true;
      }
    }
    // Cycling/Running: > 60m, Speed 1.8-5.0 m/s
    else if (avgSpeed > 1.8 && avgSpeed <= 5.0) {
      if (totalDistance >= 60 && durationSeconds >= 20) {
        // Treating as vehicle for now or specifically cycling if supported
        estimatedMode = TripMode.vehicle;
        rulesMet = true;
      }
    }
    // Vehicle: > 100m, Speed > 5.0 m/s
    else if (avgSpeed > 5.0) {
      if (totalDistance >= 100 && durationSeconds >= 20) {
        estimatedMode = TripMode.vehicle;
        rulesMet = true;
      }
    }

    // 6. DIRECTION CONSISTENCY CHECK
    if (rulesMet) {
      if (consistencyRatio < 0.6) {
        AppLogger.info(
          'TripCandidate: Rejected due to low consistency ($consistencyRatio)',
        );
        rulesMet = false;
      }
    }

    // 7. DECISION
    if (rulesMet && estimatedMode != null) {
      AppLogger.info('TripCandidate: TRIP CONFIRMED! Mode: $estimatedMode');
      add(StartTripTracking(initialMode: estimatedMode));
      // ALSO: Clear the candidate window?
      // Optional, but good practice.
      // But `StartTripTracking` handler will reset some state?
      // Actually `StartTripTracking` logic (which I saw earlier) resets `tripStartTime` but maybe not `candidatePoints`.
      // It's safer to clear it here or let `StartTripTracking` handle it.
      // `StartTripTracking` handler sets `tripStatus` to moving.
      // I'll leave candidatePoints as is, they might be useful for history or just ignored once tracking starts.
    } else {
      emit(
        currentState.copyWith(
          candidatePoints: newWindow,
          detectionStatus: TripDetectionStatus.candidate,
        ),
      );
    }
  }

  void _startChildLocationStream() {
    _stopChildLocationStream();
    if (isClosed || !_isChildLoggedIn()) return;

    _locationSubscription = _childLocationRepo
        .getPositionStream(5)
        ?.listen(
          (Position position) async {
            AppLogger.debug('new logic: get child stream');
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

  Future<void> _onStartTripTracking(
    StartTripTracking event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;
    const double kWalkingSpeedThreshold = 2.5; // m/s
    TripMode _determineTripMode(double speed) {
      return speed < kWalkingSpeedThreshold
          ? TripMode.walking
          : TripMode.vehicle;
    }

    AppLogger.info('Tripping... Starting trip tracking');

    try {
      final location = await _childLocationRepo.getChildLocation();
      if (location != null) {
        final now = DateTime.now();
        final mode = event.initialMode ?? _determineTripMode(location.speed);

        emit(
          currentState.copyWith(
            isTripTracking: true,
            tripStartTime: now,
            tripLocations: [location],
            lastTrackedLocation: location,
            childLocation: location,
            tripStatus: TripStatus.moving,
            tripMode: mode,
            waitingStartTime: null,
          ),
        );

        // Immediately trigger update to log the start point
        add(UpdateTripLocation(location: location));
      }
    } catch (e) {
      AppLogger.error('Failed to start trip tracking: ${e.toString()}');
    }
  }

  Future<void> _onStopTripTracking(
    StopTripTracking event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded ||
        !currentState.isTripTracking) {
      return;
    }
    AppLogger.info('Tripping... Stopping trip tracking');
    emit(
      currentState.copyWith(
        isTripTracking: false,
        tripLocations: [],
        tripStartTime: null,
        lastTrackedLocation: null,
      ),
    );
  }

  Future<void> _onUpdateTripLocation(
    UpdateTripLocation event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded ||
        !currentState.isTripTracking) {
      return;
    }

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        return;
      }

      final newLocation = event.location;

      // Update local state
      final updatedLocations = [...currentState.tripLocations, newLocation];
      emit(
        currentState.copyWith(
          tripLocations: updatedLocations,
          lastTrackedLocation: newLocation,
        ),
      );

      // Prepare API Payload
      final requestBody = {
        "points": [
          {
            "lat": newLocation.latitude,
            "lng": newLocation.longitude,
            "speed": newLocation.speed,
            "accuracy": newLocation.accuracy,
            "ts": DateTime.now().toUtc().toIso8601String(),
            "battery": (await _deviceInfoService.getBatteryPercentage()),
          },
        ],
      };

      AppLogger.info('Tripping... Post Trip Location Request: $requestBody');

      final response = await _childRepo.postTripLocation(
        childId: childId,
        data: requestBody,
      );

      // Handle stop logic here if needed based on response,
      // but for now user said stop logic will be discussed later.
      if (response.isSuccess && response.data != null) {
        // Placeholder for response handling
      }
    } catch (e) {
      AppLogger.error('Failed to update trip location: ${e.toString()}');
    }
  }

  void stopChildTracking() {
    _stopChildLocationStream();
  }
}
