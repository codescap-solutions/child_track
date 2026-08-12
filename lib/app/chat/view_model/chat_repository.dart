import 'package:child_track/core/models/chat_models.dart';
import 'package:child_track/core/services/api_endpoints.dart';
import 'package:child_track/core/services/base_service.dart';
import 'package:child_track/core/services/dio_client.dart';

class ChatRepository extends BaseService {
  ChatRepository({required DioClient dioClient}) : super(dioClient);

  Future<BaseResponse<List<ChatConversation>>> getChatList() async {
    final response = await get<dynamic>(ApiEndpoints.chat);

    if (response.isSuccess && response.data != null) {
      try {
        final List<dynamic> list = response.data;
        final conversations =
            list.map((e) => ChatConversation.fromJson(e)).toList();
        return BaseResponse.success(data: conversations, message: response.message);
      } catch (e) {
        return BaseResponse.error(
          message: 'Failed to parse chat list: ${e.toString()}',
        );
      }
    }

    return BaseResponse.error(
      message: response.message,
      statusCode: response.statusCode,
    );
  }

  Future<BaseResponse<List<ChatMessage>>> getMessageHistory(
    String chatId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await get<dynamic>(
      ApiEndpoints.chatMessages(chatId),
      queryParameters: {'page': page, 'limit': limit},
    );

    if (response.isSuccess && response.data != null) {
      try {
        final List<dynamic> list = response.data;
        final messages = list.map((e) => ChatMessage.fromJson(e)).toList();
        return BaseResponse.success(data: messages, message: response.message);
      } catch (e) {
        return BaseResponse.error(
          message: 'Failed to parse message history: ${e.toString()}',
        );
      }
    }

    return BaseResponse.error(
      message: response.message,
      statusCode: response.statusCode,
    );
  }

  Future<BaseResponse<ChatConversation>> startChat(String recipientId) async {
    final response = await post<Map<String, dynamic>>(
      ApiEndpoints.chat,
      data: {'recipientId': recipientId},
    );

    if (response.isSuccess && response.data != null) {
      try {
        final conversation = ChatConversation.fromJson(response.data!);
        return BaseResponse.success(
          data: conversation,
          message: response.message,
        );
      } catch (e) {
        return BaseResponse.error(
          message: 'Failed to parse chat data: ${e.toString()}',
        );
      }
    }

    return BaseResponse.error(
      message: response.message,
      statusCode: response.statusCode,
    );
  }

  Future<BaseResponse> markAsRead(String chatId) async {
    return await put(ApiEndpoints.markChatRead(chatId));
  }
}
