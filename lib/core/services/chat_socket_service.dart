import 'dart:async';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:child_track/core/models/chat_models.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();

  factory ChatSocketService() {
    return _instance;
  }

  ChatSocketService._internal();

  io.Socket? _socket;
  final String _serverUrl = "wss://naviq-server.codescap.com";
  final SharedPrefsService _sharedPrefsService = SharedPrefsService();
  
  // Streams
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void initSocket() {
    if (_socket != null) {
      AppLogger.info('[ChatSocketService] Disposing existing socket...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    final token = _sharedPrefsService.getAuthToken();
    final userId = _sharedPrefsService.getString('parent_id') ?? _sharedPrefsService.getString('child_id');

    if (userId == null) {
      AppLogger.error('[ChatSocketService] Cannot init socket: No userId found');
      return;
    }

    final extraHeaders = <String, String>{};
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': userId}) // Requirement: pass userId in query parameters
          .disableAutoConnect()
          .setReconnectionAttempts(double.infinity)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(30000)
          .enableForceNew()
          .setExtraHeaders(extraHeaders)
          .build(),
    );

    _setupListeners();
    connect();
  }

  void connect() {
    if (_socket == null) return;
    AppLogger.info('[ChatSocketService] Connecting to $_serverUrl with userId');
    _socket!.connect();
  }

  void disconnect() {
    if (_socket == null) return;
    _socket!.disconnect();
  }

  void _setupListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      AppLogger.info('[ChatSocketService] Connected: ${_socket!.id}');
      _connectionStatusController.add(true);
    });

    _socket!.onDisconnect((reason) {
      AppLogger.error('[ChatSocketService] Disconnected: $reason');
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((data) {
      AppLogger.error('[ChatSocketService] Connection Error: $data');
      _connectionStatusController.add(false);
    });

    _socket!.on('new_message', (data) {
      AppLogger.info('[ChatSocketService] New message received: $data');
      if (data != null && data is Map) {
        try {
          final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
          _messageController.add(message);
        } catch (e) {
          AppLogger.error('[ChatSocketService] Error parsing message: $e');
        }
      }
    });

    _socket!.on('error', (data) {
      AppLogger.error('[ChatSocketService] Server error: $data');
      _errorController.add(data?.toString() ?? 'Unknown error');
    });
  }

  void joinChat(String chatId) {
    if (_socket == null || !_socket!.connected) return;
    AppLogger.info('[ChatSocketService] Joining chat room: $chatId');
    _socket!.emit('join_chat', {'chatId': chatId});
  }

  void sendMessage(String chatId, String senderId, String recipientId, String text) {
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('[ChatSocketService] Cannot send message: Not connected');
      return;
    }
    
    final messageData = {
      'chatId': chatId,
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text,
    };
    
    AppLogger.info('[ChatSocketService] Sending message: $messageData');
    _socket!.emit('send_message', messageData);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _errorController.close();
    _connectionStatusController.close();
  }
}
