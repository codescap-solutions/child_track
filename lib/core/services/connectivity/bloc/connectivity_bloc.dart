import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:child_track/core/constants/enums.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:child_track/core/utils/app_logger.dart';
part 'connectivity_event.dart';
part 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity connectivity;
  StreamSubscription? _connectivitySubscription;
  bool _hasInitialCheckCompleted = false;
  bool _shouldSkipFirstStreamEmission = false;
  List<ConnectivityResult>? _lastKnownConnectivity;

  ConnectivityBloc({required this.connectivity})
    : super(ConnectivityInitial()) {
    on<ConnectivityChanged>(_onConnectivityChanged);

    // Check initial connectivity status first, then subscribe to stream
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResult = await connectivity.checkConnectivity();
      _lastKnownConnectivity = connectivityResult;
      _hasInitialCheckCompleted = true;

      // Check if initial result is valid (not none)
      final hasValidConnection = _hasValidConnection(connectivityResult);

      // If we have a valid connection, skip the first stream emission
      // (it might be a false 'none' from the stream)
      _shouldSkipFirstStreamEmission = hasValidConnection;

      add(ConnectivityChanged(connectivityResult));

      // Subscribe to stream only after initial check is complete
      _connectivitySubscription = connectivity.onConnectivityChanged.listen((
        connectivityResult,
      ) {
        // Skip first emission if it's 'none' and we have a valid connection
        if (_shouldSkipFirstStreamEmission) {
          if (_isNone(connectivityResult)) {
            AppLogger.info(
              'Skipping first stream emission (none) - keeping last known connectivity: $_lastKnownConnectivity',
            );
            _shouldSkipFirstStreamEmission = false;
            return;
          }
          _shouldSkipFirstStreamEmission = false;
        }

        // Update last known connectivity
        _lastKnownConnectivity = connectivityResult;

        // Process the stream event
        if (_hasInitialCheckCompleted) {
          add(ConnectivityChanged(connectivityResult));
        }
      });
    } catch (e) {
      AppLogger.error('Error checking initial connectivity: $e');
      _hasInitialCheckCompleted = true;
      // If check fails, subscribe to stream anyway
      _connectivitySubscription = connectivity.onConnectivityChanged.listen((
        connectivityResult,
      ) {
        _lastKnownConnectivity = connectivityResult;
        if (_hasInitialCheckCompleted) {
          add(ConnectivityChanged(connectivityResult));
        }
      });
    }
  }

  bool _isNone(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  bool _hasValidConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
  }

  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    // Check if any connectivity result indicates online status
    final hasOnlineConnection = _hasValidConnection(event.connectivityResult);

    if (hasOnlineConnection) {
      AppLogger.info('Connectivity is online: ${event.connectivityResult}');
      emit(const ConnectivityOnline(status: ConnectivityStatus.online));
    } else {
      AppLogger.info('Connectivity is offline: ${event.connectivityResult}');
      emit(const ConnectivityOffline());
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
