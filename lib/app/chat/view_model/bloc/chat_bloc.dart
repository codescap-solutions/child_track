import 'dart:async';
import 'package:child_track/core/models/chat_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/app/chat/view_model/bloc/chat_event.dart';
import 'package:child_track/app/chat/view_model/bloc/chat_state.dart';
import 'package:child_track/app/chat/view_model/chat_repository.dart';
import 'package:child_track/core/services/chat_socket_service.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final ChatSocketService _chatSocketService;
  final SharedPrefsService _sharedPrefsService;
  StreamSubscription? _socketSubscription;

  ChatBloc({
    required ChatRepository chatRepository,
    required ChatSocketService chatSocketService,
    required SharedPrefsService sharedPrefsService,
  }) : _chatRepository = chatRepository,
       _chatSocketService = chatSocketService,
       _sharedPrefsService = sharedPrefsService,
       super(ChatInitial()) {
    on<LoadChatList>(_onLoadChatList);
    on<LoadMessageHistory>(_onLoadMessageHistory);
    on<StartChatWithRecipient>(_onStartChatWithRecipient);
    on<SendChatMessage>(_onSendChatMessage);
    on<ReceiveNewMessage>(_onReceiveNewMessage);
    on<MarkChatAsRead>(_onMarkChatAsRead);

    // Listen for socket messages
    _socketSubscription = _chatSocketService.messageStream.listen((message) {
      add(ReceiveNewMessage(message));
    });

    // Ensure socket is initialized and connected
    _chatSocketService.initSocket();
  }

  Future<void> _onLoadChatList(
    LoadChatList event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final response = await _chatRepository.getChatList();
    if (response.isSuccess) {
      emit(ChatListLoaded(response.data ?? []));
    } else {
      emit(ChatError(response.message));
    }
  }

  Future<void> _onLoadMessageHistory(
    LoadMessageHistory event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final response = await _chatRepository.getMessageHistory(event.chatId);
    if (response.isSuccess) {
      _chatSocketService.joinChat(event.chatId);
      emit(
        ChatHistoryLoaded(messages: response.data ?? [], chatId: event.chatId),
      );
    } else {
      emit(ChatError(response.message));
    }
  }

  Future<void> _onStartChatWithRecipient(
    StartChatWithRecipient event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final response = await _chatRepository.startChat(event.recipientId);
    if (response.isSuccess && response.data != null) {
      _chatSocketService.joinChat(response.data!.id);
      emit(ChatConversationStarted(response.data!));
    } else {
      emit(ChatError(response.message));
    }
  }

  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<ChatState> emit,
  ) async {
    final senderId =
        _sharedPrefsService.getString('parent_id') ??
        _sharedPrefsService.getString('child_id') ??
        '';

    _chatSocketService.sendMessage(
      event.chatId,
      senderId,
      event.recipientId,
      event.text,
    );
  }

  void _onReceiveNewMessage(ReceiveNewMessage event, Emitter<ChatState> emit) {
    if (state is ChatHistoryLoaded) {
      final currentState = state as ChatHistoryLoaded;
      if (currentState.chatId == event.message.chatId) {
        final updatedMessages = List<ChatMessage>.from(currentState.messages)
          ..insert(0, event.message);
        emit(
          ChatHistoryLoaded(
            messages: updatedMessages,
            chatId: currentState.chatId,
          ),
        );
      }
    }
    // Also trigger chat list refresh if needed or update unread counts
  }

  Future<void> _onMarkChatAsRead(
    MarkChatAsRead event,
    Emitter<ChatState> emit,
  ) async {
    await _chatRepository.markAsRead(event.chatId);
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
