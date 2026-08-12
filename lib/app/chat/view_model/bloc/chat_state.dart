import 'package:equatable/equatable.dart';
import 'package:child_track/core/models/chat_models.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatListLoaded extends ChatState {
  final List<ChatConversation> conversations;
  const ChatListLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class ChatHistoryLoaded extends ChatState {
  final List<ChatMessage> messages;
  final String chatId;
  const ChatHistoryLoaded({required this.messages, required this.chatId});

  @override
  List<Object?> get props => [messages, chatId];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatConversationStarted extends ChatState {
  final ChatConversation conversation;
  const ChatConversationStarted(this.conversation);

  @override
  List<Object?> get props => [conversation];
}
