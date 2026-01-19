import 'dart:async';
import 'package:child_track/app/childapp/model/scree_time_model.dart';
import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
part 'child_event.dart';
part 'child_state.dart';

class ChildBloc extends Bloc<ChildEvent, ChildState> {
  final ChildInfoService _deviceInfoService;
  final ChildRepo _childRepo;
  final ChildGoogleMapsRepo _childLocationRepo;
  final SharedPrefsService _sharedPrefsService;
  // Timers
  Timer? _deviceInfoTimer; // 10 minutes
  Timer? _screenTimeTimer; // 1 hour
  // Timer? _childLocationTimer; // Replaced by _locationSubscription
  Timer? _tripLocationTimer; // 10 seconds for trip tracking

  ChildBloc({
    required SharedPrefsService sharedPrefsService,
    required ChildInfoService deviceInfoService,
    required ChildRepo childRepo,
    required ChildGoogleMapsRepo childLocationRepo,
  }) : _deviceInfoService = deviceInfoService,
       _childRepo = childRepo,
       _childLocationRepo = childLocationRepo,
       _sharedPrefsService = sharedPrefsService,
       super(ChildDeviceInfoLoaded.initial()) {
    on<LoadDeviceInfo>(_onLoadDeviceInfo);
    on<PostDeviceInfo>(_onPostDeviceInfo);
    on<GetScreenTime>(_onGetScreenTime);
    on<PostScreenTime>(_onPostScreenTime);
    on<GetChildLocation>(_onGetChildLocation);
    on<PostChildLocation>(_onPostChildLocation);
    on<StartTripTracking>(_onStartTripTracking);
    on<StopTripTracking>(_onStopTripTracking);
    on<UpdateTripLocation>(_onUpdateTripLocation);
    on<CheckUsagePermission>(_onCheckUsagePermission);
    on<OpenUsageSettings>(_onOpenUsageSettings);
  }
  void onInitialize() {
    final childId = _sharedPrefsService.getString('child_id');
    final parentId = _sharedPrefsService.getString('parent_id');

    // Only initialize if user is logged in as child (has child_id) and NOT as parent
    if (childId != null &&
        childId.isNotEmpty &&
        (parentId == null || parentId.isEmpty)) {
      AppLogger.info('ChildBloc: Initializing for child_id: $childId');
      add(LoadDeviceInfo());
      add(CheckUsagePermission());
      _startChildLocationTimer(); // Start location stream
      // add(GetChildLocation()); // Removed one-off call, stream will handle it
    } else {
      AppLogger.info(
        'ChildBloc: Skipping initialization - not logged in as child',
      );
      // Stop any running timers
      _stopAllTimers();
    }
  }

  /// Stop all timers and cleanup
  void _stopAllTimers() {
    _stopDeviceInfoTimer();
    _stopScreenTimeTimer();
    _stopChildLocationTimer();
    _stopTripLocationTimer();
  }

  /// Public method to stop all NAVIQing activities
  void stopChildTracking() {
    AppLogger.info('ChildBloc: Stopping all NAVIQing activities');
    _stopAllTimers();
  }

  /// Check if user is logged in as child
  bool _isChildLoggedIn() {
    final childId = _sharedPrefsService.getString('child_id');
    final parentId = _sharedPrefsService.getString('parent_id');
    return childId != null &&
        childId.isNotEmpty &&
        (parentId == null || parentId.isEmpty);
  }

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

  Future<void> _onPostDeviceInfo(
    PostDeviceInfo event,
    Emitter<ChildState> emit,
  ) async {
    // Check if user is still logged in as child
    if (!_isChildLoggedIn()) {
      AppLogger.warning(
        'ChildBloc: Skipping postDeviceInfo - not logged in as child',
      );
      _stopDeviceInfoTimer();
      return;
    }

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        AppLogger.warning(
          'ChildBloc: child_id is null, stopping device info timer',
        );
        _stopDeviceInfoTimer();
        return;
      }

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
    } finally {
      // Only start timer if still logged in as child
      if (_isChildLoggedIn()) {
        _startDeviceInfoTimer();
      }
    }
  }

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

  Future<void> _onOpenUsageSettings(
    OpenUsageSettings event,
    Emitter<ChildState> emit,
  ) async {
    await _deviceInfoService.openUsageSettings();
  }

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

  Future<void> _onPostScreenTime(
    PostScreenTime event,
    Emitter<ChildState> emit,
  ) async {
    // Check if user is still logged in as child
    if (!_isChildLoggedIn()) {
      AppLogger.warning(
        'ChildBloc: Skipping postScreenTime - not logged in as child',
      );
      _stopScreenTimeTimer();
      return;
    }

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        AppLogger.warning(
          'ChildBloc: child_id is null, stopping screen time timer',
        );
        _stopScreenTimeTimer();
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
    } finally {
      // Only start timer if still logged in as child
      if (_isChildLoggedIn()) {
        _startScreenTimeTimer();
      }
    }
  }

  static const double kWalkingSpeedThreshold = 2.5; // m/s
  static const double kWalkingDistanceThreshold = 30.0; // meters
  static const double kVehicleDistanceThreshold = 100.0; // meters
  static const double kWaitingSpeedThreshold = 1.0; // m/s
  static const Duration kWaitingDurationThreshold = Duration(minutes: 5);

  TripMode _determineTripMode(double speed) {
    return speed < kWalkingSpeedThreshold ? TripMode.walking : TripMode.vehicle;
  }

  Future<void> _onGetChildLocation(
    GetChildLocation event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;
    try {
      final location = await _childLocationRepo.getChildLocation();
      if (location != null) {
        final previousLocation = currentState.childLocation;
        ChildDeviceInfoLoaded newState = currentState;

        // Trip Detection Logic (Only if not already tracking)
        if (!newState.isTripTracking && previousLocation != null) {
          double speed = location.speed;
          if (speed < 0) speed = 0;

          final distance = await _childLocationRepo.getDistanceBetweenTwoPoints(
            previousLocation,
            location,
          );

          if (distance < 10) {
            AppLogger.info(
              'ChildLocation: Movement too small (${distance.toStringAsFixed(1)}m), skipping API update',
            );
            return;
          }

          // --- Trip Start Logic ---
          const double minStartSpeed = 1.2;
          const int minConsecutivePoints = 3;
          const double minStartDisplacement = 30.0;
          const int confirmationTimeSec = 30;
          const double confirmationDistance = 100.0;

          // Stage 1 Check: Moving?
          bool isMoving = speed >= minStartSpeed;

          // Candidate Phase Handling
          if (newState.candidateStartTime != null) {
            // We are in Candidate Phase (Stage 2)
            if (!isMoving) {
              AppLogger.info('TripCandidate: Stopped moving, RESET candidate');
              newState = newState.copyWith(
                consecutiveMovingPoints: 0,
                candidateStartTime: null,
                candidateStartLocation: null,
              );
              emit(newState);
            } else {
              // Check Confirmation
              final duration = DateTime.now()
                  .difference(newState.candidateStartTime!)
                  .inSeconds;
              final totalDist = await _childLocationRepo
                  .getDistanceBetweenTwoPoints(
                    newState.candidateStartLocation!,
                    location,
                  );

              AppLogger.info(
                'TripCandidate: Checking confirmation (Duration: ${duration}s, Dist: ${totalDist}m)',
              );

              if (duration >= confirmationTimeSec ||
                  totalDist >= confirmationDistance) {
                AppLogger.info('TripCandidate: TRIP CONFIRMED!');
                final mode = _determineTripMode(speed);
                add(StartTripTracking(initialMode: mode));
                return;
              }
            }
          } else {
            // Not in Candidate Phase -> Check Stage 1
            if (isMoving) {
              final newConsecutive = newState.consecutiveMovingPoints + 1;
              newState = newState.copyWith(
                consecutiveMovingPoints: newConsecutive,
              );

              bool triggerConsecutive = newConsecutive >= minConsecutivePoints;
              bool triggerDisplacement = distance >= minStartDisplacement;

              if (triggerConsecutive || triggerDisplacement) {
                AppLogger.info(
                  'TripCandidate: ENTERING CANDIDATE PHASE (Consec: $newConsecutive, Dist: $distance)',
                );
                newState = newState.copyWith(
                  candidateStartTime: DateTime.now(),
                  candidateStartLocation: location,
                );
              }
              emit(newState);
            } else {
              if (newState.consecutiveMovingPoints > 0) {
                newState = newState.copyWith(consecutiveMovingPoints: 0);
                emit(newState);
              }
            }
          }
        }

        emit(newState.copyWith(childLocation: location));
        add(PostChildLocation(childLocation: location));
      }
    } catch (e) {
      AppLogger.error('Failed to get child location: ${e.toString()}');
    }
  }

  Future<void> _onStartTripTracking(
    StartTripTracking event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;
    AppLogger.info('Tripping... Starting trip tracking');

    try {
      final location = await _childLocationRepo.getChildLocation();
      if (location != null) {
        final now = DateTime.now();
        final mode = _determineTripMode(location.speed);

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

        _startTripLocationTimer();
        AppLogger.info('Tripping... Started trip tracking Timer');
      }
    } catch (e) {
      AppLogger.error('Failed to start trip tracking: ${e.toString()}');
    }
  }

  // ... existing stop trip ...

  Future<void> _onUpdateTripLocation(
    UpdateTripLocation event,
    Emitter<ChildState> emit,
  ) async {
    if (!_isChildLoggedIn()) {
      _stopTripLocationTimer();
      return;
    }

    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded ||
        !currentState.isTripTracking) {
      return;
    }

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        _stopTripLocationTimer();
        return;
      }

      final newLocation = event.location;
      final lastLocation = currentState.lastTrackedLocation;

      // 1. Check for Waiting State vs End Trip
      final currentSpeed = newLocation.speed;
      TripStatus newStatus = currentState.tripStatus;
      DateTime? newWaitingStartTime = currentState.waitingStartTime;

      if (currentSpeed < kWaitingSpeedThreshold) {
        // Child is effectively stopped
        if (newStatus != TripStatus.waiting) {
          newStatus = TripStatus.waiting;
          newWaitingStartTime = DateTime.now();
          // AppLogger.info('Tripping... Status changed to WAITING');
        } else if (newWaitingStartTime != null) {
          // Already waiting.
          // Frontend stop logic REMOVED.
          // We just wait for backend to tell us to stop or for motion to resume.
        }
      } else {
        // Child is moving
        if (newStatus == TripStatus.waiting) {
          AppLogger.info('Tripping... Resumed MOVING');
          newStatus = TripStatus.moving;
          newWaitingStartTime = null;
        }
      }

      // 2. Check Distance for API Update
      bool shouldTrack = true;
      if (lastLocation != null) {
        final distance = await _childLocationRepo.getDistanceBetweenTwoPoints(
          lastLocation,
          newLocation,
        );
        // Use 30m threshold for updates regardless of mode for now, or adapt based on mode
        shouldTrack = distance >= 30.0;
      }

      if (shouldTrack) {
        final updatedLocations = [...currentState.tripLocations, newLocation];

        TripMode currentMode = currentState.tripMode;
        if (currentMode == TripMode.walking &&
            currentSpeed > kWalkingSpeedThreshold) {
          currentMode = TripMode.vehicle;
        }

        emit(
          currentState.copyWith(
            tripLocations: updatedLocations,
            lastTrackedLocation: newLocation,
            childLocation: newLocation,
            tripStatus: newStatus,
            tripMode: currentMode,
            waitingStartTime: newWaitingStartTime,
          ),
        );

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

        AppLogger.info(
          'Tripping... Post Trip Location Response: ${response.message}',
        );

        // Backend Driven Trip Stop Logic
        if (response.isSuccess && response.data != null) {
          final data = response.data!;
          final currentStateStr =
              data['currentState']; // "IDLE" or "ON_TRIP" (or "END_CANDIDATE" etc)

          if (currentStateStr == 'IDLE') {
            AppLogger.info('Tripping... Backend reports IDLE. Stopping trip.');

            // Optional: Log reason if available
            if (data['stateTransitions'] != null) {
              final transitions = data['stateTransitions'] as List;
              if (transitions.isNotEmpty) {
                final reason = transitions.last['reason'];
                AppLogger.info('Tripping... Stop Reason: $reason');
                if (reason == 'STATIONARY_CONFIRMED') {
                  add(StopTripTracking());
                }
              }
            }
            return;
          }
        }
      } else {
        // Even if distance didn't change enough for an API call, we can still emit waiting state.
        // But with backend logic, "Waiting" state is also backend driven potentially?
        // User asked to remove frontend stopping logic.
        // We'll keep the Waiting Display updates (UI only) but remove the timer-based Stop.

        if (newStatus != currentState.tripStatus ||
            newWaitingStartTime != currentState.waitingStartTime) {
          emit(
            currentState.copyWith(
              tripStatus: newStatus,
              waitingStartTime: newWaitingStartTime,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to update trip location: ${e.toString()}');
    }
  }

  Future<void> _onPostChildLocation(
    PostChildLocation event,
    Emitter<ChildState> emit,
  ) async {
    // Check if user is still logged in as child
    if (!_isChildLoggedIn()) {
      AppLogger.warning(
        'ChildBloc: Skipping postChildLocation - not logged in as child',
      );
      _stopChildLocationTimer();
      return;
    }

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        AppLogger.warning(
          'ChildBloc: child_id is null, stopping location timer',
        );
        _stopChildLocationTimer();
        return;
      }

      // Get dynamic address and place name from coordinates
      final locationInfo = await _childLocationRepo.getAddressAndPlaceName(
        event.childLocation.latitude,
        event.childLocation.longitude,
      );

      final requestBody = {
        "address": locationInfo?['address'] ?? 'Unknown',
        "place_name": locationInfo?['place_name'] ?? 'Unknown',
        "child_id": childId,
        "lat": event.childLocation.latitude,
        "lng": event.childLocation.longitude,
        "accuracy_m": event.childLocation.accuracy,
        "speed_mps": event.childLocation.speed,
        "bearing": event.childLocation.heading,
        "timestamp": DateTime.now().toIso8601String(),
      };
      await _childRepo.postChildLocation(requestBody);
    } catch (e) {
      AppLogger.error('Failed to post child location: ${e.toString()}');
    } finally {
      // Only start timer if still logged in as child
      // if (_isChildLoggedIn()) {
      //   _startChildLocationTimer(); // Removed to prevent infinite loop with Stream
      // }
    }
  }

  void _startDeviceInfoTimer() {
    _stopDeviceInfoTimer();
    _deviceInfoTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (isClosed || !_isChildLoggedIn()) {
        timer.cancel();
        return;
      }
      add(LoadDeviceInfo());
    });
  }

  void _stopDeviceInfoTimer() {
    _deviceInfoTimer?.cancel();
    _deviceInfoTimer = null;
  }

  void _startScreenTimeTimer() {
    _stopScreenTimeTimer();
    _screenTimeTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (isClosed || !_isChildLoggedIn()) {
        timer.cancel();
        return;
      }
      final currentState = state;
      if (currentState is ChildDeviceInfoLoaded) {
        add(GetScreenTime());
      }
    });
  }

  void _stopScreenTimeTimer() {
    _screenTimeTimer?.cancel();
    _screenTimeTimer = null;
  }

  StreamSubscription<Position>? _locationSubscription;

  void _stopChildLocationTimer() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _startChildLocationTimer() {
    _stopChildLocationTimer();

    // Check if logged in first
    if (isClosed || !_isChildLoggedIn()) return;

    // Use distanceFilter of 10 meters to reduce redundant API calls
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position? position) {
            if (isClosed || !_isChildLoggedIn()) {
              _stopChildLocationTimer();
              return;
            }
            AppLogger.info(
              'ChildBloc: Location info updated detected (moved > 10m)',
            );
            add(GetChildLocation());
          },
          onError: (e) {
            AppLogger.error('ChildBloc: Location stream error: $e');
          },
        );
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
    AppLogger.info('Tripping... Stopping trip tracking Timer');
    _stopTripLocationTimer();
    AppLogger.info('Tripping... Stopped trip tracking Timer');
    emit(
      currentState.copyWith(
        isTripTracking: false,
        tripLocations: [],
        tripStartTime: null,
        lastTrackedLocation: null,
      ),
    );
  }

  void _startTripLocationTimer() {
    _stopTripLocationTimer();
    _tripLocationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (isClosed || !_isChildLoggedIn()) {
        timer.cancel();
        return;
      }
      final currentState = state;
      if (currentState is! ChildDeviceInfoLoaded ||
          !currentState.isTripTracking) {
        _stopTripLocationTimer();
        return;
      }

      // Get current location and update trip
      _childLocationRepo
          .getChildLocation()
          .then((location) {
            if (location != null && !isClosed && _isChildLoggedIn()) {
              AppLogger.info(
                'Tripping... Updating trip location Timer $location',
              );
              add(UpdateTripLocation(location: location));
            }
          })
          .catchError((e) {
            AppLogger.error('Failed to get location for trip tracking: $e');
          });
    });
  }

  void _stopTripLocationTimer() {
    _tripLocationTimer?.cancel();
    _tripLocationTimer = null;
  }

  @override
  Future<void> close() {
    _stopDeviceInfoTimer();
    _stopScreenTimeTimer();
    _stopChildLocationTimer();
    _stopTripLocationTimer();
    return super.close();
  }
}
