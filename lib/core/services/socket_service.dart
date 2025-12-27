import 'dart:async';

import 'package:child_track/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  IO.Socket? _socket;
  final String _serverUrl = "wss://naviq-server.codescap.com";

  // Streams
  final _locationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get tripStream => _tripController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void initSocket() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _socket = IO.io(
      _serverUrl,
      IO.OptionBuilder()
          .setTransports(['polling', 'websocket']) // Try polling first
          .enableAutoConnect()
          .setReconnectionAttempts(double.infinity)
          .build(),
    );

    _setupListeners();
    connect();
  }

  void connect() {
    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void _setupListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('Connection established');
      _connectionStatusController.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('Connection Disconnected');
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((data) {
      debugPrint('Connect Error: $data');
      _connectionStatusController.add(false);
    });

    _socket!.onError((data) {
      debugPrint('Error: $data');
    });

    // Listen for server events
    _socket!.on('location_update', (data) {
      if (data != null && data is Map<String, dynamic>) {
        AppLogger.debug(" location_update: $data");
        _locationController.add(data);
      }
    });

    _socket!.on('status_update', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _statusController.add(data);
      }
    });

    _socket!.on('trip_update', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _tripController.add(data);
      }
    });
  }

  void joinRoom(String childId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_room', {'child_id': childId});
    }
  }

  void leaveRoom(String childId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_room', {'child_id': childId});
    }
  }

  // Emitters
  void sendLocation(Map<String, dynamic> locationData) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_location', locationData);
    }
  }

  void sendStatus(Map<String, dynamic> statusData) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_status', statusData);
    }
  }

  void emitTripEvent(String eventName, Map<String, dynamic> tripData) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(eventName, tripData);
    }
  }
}
