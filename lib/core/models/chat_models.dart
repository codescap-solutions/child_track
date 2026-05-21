import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';

class ChatConversation {
  final String id;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    int parsedUnreadCount = 0;
    final unreadVal = json['unreadCount'];
    if (unreadVal is num) {
      parsedUnreadCount = unreadVal.toInt();
    } else if (unreadVal is Map) {
      try {
        final currentUserId = injector<SharedPrefsService>().getString('parent_id') ??
            injector<SharedPrefsService>().getString('child_id') ??
            '';
        final userUnread = unreadVal[currentUserId];
        if (userUnread is num) {
          parsedUnreadCount = userUnread.toInt();
        } else if (userUnread != null) {
          parsedUnreadCount = int.tryParse(userUnread.toString()) ?? 0;
        }
      } catch (_) {
        if (unreadVal.isNotEmpty) {
          final firstVal = unreadVal.values.first;
          if (firstVal is num) {
            parsedUnreadCount = firstVal.toInt();
          } else if (firstVal != null) {
            parsedUnreadCount = int.tryParse(firstVal.toString()) ?? 0;
          }
        }
      }
    }

    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'].toString())
        : DateTime.now();

    return ChatConversation(
      id: json['_id']?.toString() ?? '',
      participants:
          (json['participants'] as List?)
              ?.map((e) => ChatParticipant.fromJson(e))
              .toList() ??
          [],
      lastMessage: json['lastMessage'] != null
          ? (json['lastMessage'] is Map
              ? ChatMessage.fromJson(Map<String, dynamic>.from(json['lastMessage'] as Map))
              : ChatMessage(
                  id: json['lastMessage'].toString(),
                  chatId: json['_id']?.toString() ?? '',
                  senderId: '',
                  text: '',
                  createdAt: updatedAt,
                ))
          : null,
      unreadCount: parsedUnreadCount,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participants.map((e) => e.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ChatParticipant {
  final String id;
  final String name;
  final String? avatar;
  final String role;

  ChatParticipant({
    required this.id,
    required this.name,
    this.avatar,
    required this.role,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'avatar': avatar, 'role': role};
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      senderId: (json['senderId'] ??
              (json['sender'] is Map
                  ? (json['sender'] as Map)['_id']
                  : (json['sender'] ?? '')))
          ?.toString() ??
          '',
      text: json['text']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      isRead: json['isRead'] is bool
          ? json['isRead'] as bool
          : (json['isRead']?.toString() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}
