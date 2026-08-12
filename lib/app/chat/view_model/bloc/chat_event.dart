import 'package:equatable/equatable.dart';
import 'package:child_track/core/models/chat_models.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatList extends ChatEvent {}

class LoadMessageHistory extends ChatEvent {
  final String chatId;
  const LoadMessageHistory(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class StartChatWithRecipient extends ChatEvent {
  final String recipientId;
  const StartChatWithRecipient(this.recipientId);

  @override
  List<Object?> get props => [recipientId];
}

class SendChatMessage extends ChatEvent {
  final String chatId;
  final String recipientId;
  final String text;

  const SendChatMessage({
    required this.chatId,
    required this.recipientId,
    required this.text,
  });

  @override
  List<Object?> get props => [chatId, recipientId, text];
}

class ReceiveNewMessage extends ChatEvent {
  final ChatMessage message;
  const ReceiveNewMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class MarkChatAsRead extends ChatEvent {
  final String chatId;
  const MarkChatAsRead(this.chatId);

  @override
  List<Object?> get props => [chatId];
}
