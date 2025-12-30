import 'dart:async';
import 'dart:developer';

import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  IO.Socket? _socket;
  final String _serverUrl = "wss://naviq-server.codescap.com";
  final SharedPrefsService _sharedPrefsService = SharedPrefsService();
  String? _pendingChildIdForRoom;

  // Streams
  final _locationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void initSocket() {
    log('[SocketService] initSocket called - Server URL: $_serverUrl');
    if (_socket != null) {
      log('[SocketService] Existing socket found, disconnecting and disposing...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      log('[SocketService] Previous socket cleaned up');
    }

    log('[SocketService] Creating new socket instance...');
    
    // Get auth token for connection
    final token = _sharedPrefsService.getAuthToken();
    log('[SocketService] Auth token available: ${token != null && token.isNotEmpty}');
    
    // Try with https:// first (socket.io standard), if that doesn't work, we'll try wss://
    // Socket.io client typically expects https:// and handles the upgrade internally
    final url = _serverUrl.startsWith('wss://') 
        ? _serverUrl.replaceFirst('wss://', 'https://')
        : _serverUrl;
    
    log('[SocketService] Using URL: $url (converted from $_serverUrl)');
    
    // Build extra headers if token is available
    final extraHeaders = <String, dynamic>{};
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
      log('[SocketService] Adding Authorization header');
    }
    
    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Try websocket first, then polling
          .disableAutoConnect() // We'll connect manually
          .setReconnectionAttempts(double.infinity)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(30000) // 30 second timeout
          .enableForceNew()
          .setExtraHeaders(extraHeaders)
          .build(),
    );
    log('[SocketService] Socket instance created, socket is null: ${_socket == null}');
    log('[SocketService] Socket options configured: transports=[websocket, polling], autoConnect=false, timeout=30s');

    _setupListeners();
    log('[SocketService] Listeners setup complete, calling connect()...');
    connect();
  }

  void connect() {
    log('[SocketService] connect() called');
    if (_socket == null) {
      log('[SocketService] ERROR: Socket is null, cannot connect');
      return;
    }
    log('[SocketService] Socket exists, current connected status: ${_socket!.connected}');
    log('[SocketService] Socket disconnected status: ${_socket!.disconnected}');
    log('[SocketService] Attempting to connect to server: $_serverUrl');
    
    try {
      _socket!.connect();
      log('[SocketService] connect() method executed successfully');
      
      // Check connection status after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        log('[SocketService] Connection status after 500ms: ${_socket?.connected ?? false}');
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        log('[SocketService] Connection status after 2s: ${_socket?.connected ?? false}');
        if (_socket != null && !_socket!.connected) {
          log('[SocketService] ⚠️ Still not connected after 2 seconds');
        }
      });
    } catch (e, stackTrace) {
      log('[SocketService] ❌ Exception during connect(): $e');
      log('[SocketService] Stack trace: $stackTrace');
    }
  }

  void disconnect() {
    log('[SocketService] disconnect() called');
    if (_socket == null) {
      log('[SocketService] Socket is null, nothing to disconnect');
      return;
    }
    log('[SocketService] Disconnecting socket...');
    _socket!.disconnect();
    log('[SocketService] Disconnect called');
  }

  void _setupListeners() {
    log('[SocketService] _setupListeners() called');
    if (_socket == null) {
      log('[SocketService] ERROR: Socket is null in _setupListeners, cannot setup listeners');
      return;
    }
    log('[SocketService] Setting up socket event listeners...');
    log('[SocketService] Socket instance: ${_socket.hashCode}');
    log('[SocketService] Socket connected: ${_socket!.connected}');

    _socket!.onConnect((_) {
      log('[SocketService] ✅ Connection established successfully');
      log('[SocketService] Socket ID: ${_socket!.id}');
      log('[SocketService] Socket transport: ${_socket!.io.engine?.transport?.name ?? "unknown"}');
      log('[SocketService] Socket URL: ${_socket!.io.uri}');
      log('[SocketService] 🔍 Connection verified - all listeners should be active');
      _connectionStatusController.add(true);
      
      // If there's a pending childId to join, join the room now
      if (_pendingChildIdForRoom != null) {
        log('[SocketService] Auto-joining room with pending childId: $_pendingChildIdForRoom');
        joinRoom(_pendingChildIdForRoom!);
        _pendingChildIdForRoom = null;
      }
    });

    // Listen for room join confirmation from server
    _socket!.on('room_joined', (data) {
      log('[SocketService] ✅ Server confirmed: room_joined');
      log('[SocketService] Room join data: $data');
    });

    _socket!.on('joined_room', (data) {
      log('[SocketService] ✅ Server confirmed: joined_room');
      log('[SocketService] Joined room data: $data');
    });

    _socket!.on('room_join_success', (data) {
      log('[SocketService] ✅ Server confirmed: room_join_success');
      log('[SocketService] Room join success data: $data');
    });

    _socket!.onDisconnect((reason) {
      log('[SocketService] ❌ Connection Disconnected - Reason: $reason');
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((data) {
      log('[SocketService] ❌ Connect Error occurred: $data');
      log('[SocketService] Error type: ${data.runtimeType}');
      log('[SocketService] Error details: ${data.toString()}');
      if (data is Map) {
        log('[SocketService] Error map contents: $data');
      }
      _connectionStatusController.add(false);
    });

    _socket!.onError((data) {
      log('[SocketService] ❌ Socket Error: $data');
      log('[SocketService] Error type: ${data.runtimeType}');
    });

    _socket!.onReconnect((attemptNumber) {
      log('[SocketService] 🔄 Reconnecting... Attempt: $attemptNumber');
    });

    _socket!.onReconnectAttempt((attemptNumber) {
      log('[SocketService] 🔄 Reconnection attempt: $attemptNumber');
    });

    _socket!.on('connect_timeout', (_) {
      log('[SocketService] ⏱️ Connection timeout occurred');
    });

    _socket!.on('ping', (_) {
      log('[SocketService] 📡 Ping received from server');
    });

    _socket!.on('pong', (_) {
      log('[SocketService] 📡 Pong received from server');
    });

    _socket!.onReconnectError((error) {
      log('[SocketService] ❌ Reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      log('[SocketService] ❌ Reconnection failed');
    });

    // Listen for server events
    log('[SocketService] 🔧 Registering location_update listener...');
    _socket!.on('location_update', (data) {
      log('[SocketService] 📍📍📍 Received location_update event');
      log('[SocketService] 📍 Event data: $data');
      log('[SocketService] 📍 Event data type: ${data.runtimeType}');
      if (data != null && data is Map<String, dynamic>) {
        AppLogger.debug(" location_update: $data");
        log('[SocketService] 📍 Adding to location stream controller...');
        _locationController.add(data);
        log('[SocketService] ✅ Location data added to stream');
      } else {
        log('[SocketService] ⚠️ location_update data is null or invalid type: ${data.runtimeType}');
        if (data != null) {
          log('[SocketService] ⚠️ Attempting to convert data to Map...');
          try {
            final mapData = Map<String, dynamic>.from(data as Map);
            _locationController.add(mapData);
            log('[SocketService] ✅ Converted and added to stream');
          } catch (e) {
            log('[SocketService] ❌ Failed to convert: $e');
          }
        }
      }
    });
    log('[SocketService] ✅ location_update listener registered');

    // Also listen to the raw event name in case server uses different naming
    log('[SocketService] 🔧 Registering Websocket send_location listener...');
    _socket!.on('Websocket send_location', (data) {
      log('[SocketService] 📍📍📍 Received Websocket send_location event (raw)');
      log('[SocketService] 📍 Raw event data: $data');
      log('[SocketService] 📍 Raw event data type: ${data.runtimeType}');
      if (data != null && data is Map<String, dynamic>) {
        _locationController.add(data);
        log('[SocketService] ✅ Raw location data added to stream');
      } else if (data != null) {
        log('[SocketService] ⚠️ Attempting to convert raw data to Map...');
        try {
          final mapData = Map<String, dynamic>.from(data as Map);
          _locationController.add(mapData);
          log('[SocketService] ✅ Converted and added to stream');
        } catch (e) {
          log('[SocketService] ❌ Failed to convert raw data: $e');
        }
      }
    });
    log('[SocketService] ✅ Websocket send_location listener registered');

    _socket!.on('status_update', (data) {
      log('[SocketService] 📊 Received status_update event');
      log('[SocketService] 📊 Event data: $data');
      if (data != null && data is Map<String, dynamic>) {
        _statusController.add(data);
        log('[SocketService] ✅ Status data added to stream');
      } else {
        log('[SocketService] ⚠️ status_update data is null or invalid type: ${data.runtimeType}');
      }
    });

    // Also listen to the raw event name
    _socket!.on('websocket send_status', (data) {
      log('[SocketService] 📊 Received websocket send_status event (raw)');
      log('[SocketService] 📊 Raw event data: $data');
      if (data != null && data is Map<String, dynamic>) {
        _statusController.add(data);
        log('[SocketService] ✅ Raw status data added to stream');
      }
    });

    _socket!.on('trip_update', (data) {
      log('[SocketService] 🚗 Received trip_update event');
      log('[SocketService] 🚗 Event data: $data');
      if (data != null && data is Map<String, dynamic>) {
        _tripController.add(data);
        log('[SocketService] ✅ Trip data added to stream');
      } else {
        log('[SocketService] ⚠️ trip_update data is null or invalid type: ${data.runtimeType}');
      }
    });

    // Also listen to trip_started and trip_ended events
    _socket!.on('trip_started', (data) {
      log('[SocketService] 🚗 Received trip_started event');
      log('[SocketService] 🚗 Event data: $data');
      if (data != null && data is Map<String, dynamic>) {
        _tripController.add(data);
        log('[SocketService] ✅ Trip started data added to stream');
      }
    });

    _socket!.on('trip_ended', (data) {
      log('[SocketService] 🚗 Received trip_ended event');
      log('[SocketService] 🚗 Event data: $data');
      if (data != null && data is Map<String, dynamic>) {
        _tripController.add(data);
        log('[SocketService] ✅ Trip ended data added to stream');
      }
    });

    // Listen to all events for debugging - MUST BE SET UP FIRST to catch everything
    log('[SocketService] 🔧 Registering onAny listener to catch ALL events...');
    _socket!.onAny((event, data) {
      log('[SocketService] 🔔🔔🔔 Received ANY event: $event');
      log('[SocketService] 🔔 Event data type: ${data.runtimeType}');
      log('[SocketService] 🔔 Event data: $data');
      
      // Log specific known events with more detail
      final eventLower = event.toString().toLowerCase();
      if (eventLower.contains('location')) {
        log('[SocketService] 🔔🔔🔔 LOCATION EVENT DETECTED: $event');
        log('[SocketService] 🔔🔔🔔 LOCATION DATA: $data');
        log('[SocketService] 🔔🔔🔔 LOCATION DATA TYPE: ${data.runtimeType}');
      }
      if (eventLower.contains('trip')) {
        log('[SocketService] 🔔🔔🔔 TRIP EVENT DETECTED: $event');
        log('[SocketService] 🔔🔔🔔 TRIP DATA: $data');
      }
      if (eventLower.contains('status')) {
        log('[SocketService] 🔔🔔🔔 STATUS EVENT DETECTED: $event');
        log('[SocketService] 🔔🔔🔔 STATUS DATA: $data');
      }
      if (eventLower.contains('room') || eventLower.contains('join')) {
        log('[SocketService] 🔔🔔🔔 ROOM/JOIN EVENT DETECTED: $event');
        log('[SocketService] 🔔🔔🔔 ROOM/JOIN DATA: $data');
      }
    });
    
    log('[SocketService] ✅ onAny listener registered - will catch ALL events');

    log('[SocketService] ✅ All listeners setup complete');
  }

  void joinRoom(String childId) {
    log('[SocketService] joinRoom() called with childId: $childId');
    if (_socket == null) {
      log('[SocketService] ❌ Cannot join room: Socket is null');
      log('[SocketService] Storing childId for later join: $childId');
      _pendingChildIdForRoom = childId;
      return;
    }
    if (!_socket!.connected) {
      log('[SocketService] ❌ Cannot join room: Socket is not connected');
      log('[SocketService] Socket connected status: ${_socket!.connected}');
      log('[SocketService] Socket disconnected status: ${_socket!.disconnected}');
      log('[SocketService] Storing childId for later join: $childId');
      _pendingChildIdForRoom = childId;
      return;
    }
    log('[SocketService] ✅ Socket is connected, emitting join_room event');
    log('[SocketService] ✅ Socket ID: ${_socket!.id}');
    log('[SocketService] ✅ Emitting join_room event with child_id: $childId');
    
    final joinData = {'childId': childId};
    log('[SocketService] Join room data: $joinData');
    _socket!.emit('join_child_room', joinData);
    log('[SocketService] ✅ join_room event emitted');
    
    // Add a verification log after a delay to check if room join was successful
    Future.delayed(const Duration(seconds: 2), () {
      log('[SocketService] 🔍 Post-join verification: Socket connected=${_socket?.connected}, Socket ID=${_socket?.id}');
      log('[SocketService] 🔍 Waiting for location_update events for childId: $childId');
    });
    
    _pendingChildIdForRoom = null; // Clear pending since we joined successfully
    
    // Listen for confirmation that room was joined (using on instead of once to catch all)
    _socket!.on('room_joined', (data) {
      log('[SocketService] ✅✅✅ Server confirmed: room_joined');
      log('[SocketService] Room joined data: $data');
      log('[SocketService] ✅ Room join successful - should now receive location_update events');
    });
    
    _socket!.on('joined_room', (data) {
      log('[SocketService] ✅✅✅ Server confirmed: joined_room');
      log('[SocketService] Joined room data: $data');
      log('[SocketService] ✅ Room join successful - should now receive location_ update events');
    });
    
    _socket!.on('room_join_success', (data) {
      log('[SocketService] ✅✅✅ Server confirmed: room_join_success');
      log('[SocketService] Room join success data: $data');
      log('[SocketService] ✅ Room join successful - should now receive location_update events');
    });
    
    // Also listen for any error responses
    _socket!.on('room_join_error', (data) {
      log('[SocketService] ❌ Server error: room_join_error');
      log('[SocketService] Error data: $data');
    });
    
    _socket!.on('error', (data) {
      log('[SocketService] ❌ Socket error event received');
      log('[SocketService] Error data: $data');
    });
  }

  void leaveRoom(String childId) {
    log('[SocketService] leaveRoom() called with childId: $childId');
    if (_socket == null) {
      log('[SocketService] ❌ Cannot leave room: Socket is null');
      return;
    }
    if (!_socket!.connected) {
      log('[SocketService] ❌ Cannot leave room: Socket is not connected');
      return;
    }
    log('[SocketService] ✅ Emitting leave_room event with child_id: $childId');
    _socket!.emit('leave_child_room', {'childId': childId});
  }

  // Emitters
  void sendLocation(Map<String, dynamic> locationData) {
    log('[SocketService] sendLocation() called');
    log('[SocketService] Location data to send: $locationData');
    if (_socket == null) {
      log('[SocketService] ❌ Cannot send location: Socket is null');
      return;
    }
    if (!_socket!.connected) {
      log('[SocketService] ❌ Cannot send location: Socket is not connected');
      log('[SocketService] Socket connected: ${_socket!.connected}, disconnected: ${_socket!.disconnected}');
      return;
    }
    log('[SocketService] ✅ Socket is connected, emitting Websocket send_location event');
    log('[SocketService] ✅ Socket ID: ${_socket!.id}');
    log('[SocketService] ✅ Event name: Websocket send_location');
    _socket!.emit('Websocket send_location', locationData);
    log('[SocketService] ✅ Location event emitted successfully');
  }

  void sendStatus(Map<String, dynamic> statusData) {
    log('[SocketService] sendStatus() called');
    if (_socket == null) {
      log('[SocketService] ❌ Cannot send status: Socket is null');
      return;
    }
    if (!_socket!.connected) {
      log('[SocketService] ❌ Cannot send status: Socket is not connected');
      return;
    }
    log('[SocketService] ✅ Emitting websocket send_status event');
    _socket!.emit('websocket send_status', statusData);
  }

  void emitTripEvent(String eventName, Map<String, dynamic> tripData) {
    log('[SocketService] emitTripEvent() called with event: $eventName');
    if (_socket == null) {
      log('[SocketService] ❌ Cannot emit trip event: Socket is null');
      return;
    }
    if (!_socket!.connected) {
      log('[SocketService] ❌ Cannot emit trip event: Socket is not connected');
      return;
    }
    log('[SocketService] ✅ Emitting trip event: $eventName');
    _socket!.emit(eventName, tripData);
  }
}
