import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class ChatRepository {
  final ApiService _apiService;

  ChatRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Lấy danh sách các admin shop
  Future<List<UserModel>> fetchShopAdmins() async {
    final response = await _apiService.dio.get<Map<String, dynamic>>('/messages/shop');
    final rawList = response.data!['data'] as List<dynamic>;
    return rawList.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Lấy lịch sử chat với shop (có phân trang)
  Future<List<MessageModel>> fetchMessages(
    String shopId,
    String currentUserId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.dio.get<Map<String, dynamic>>(
      '/messages/$shopId',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final rawList = response.data!['data'] as List<dynamic>;

    return rawList.map((e) {
      final json = Map<String, dynamic>.from(e as Map);
      final senderId = json['senderId'] as String;
      final isUser = (senderId == currentUserId);

      return MessageModel(
        id: (json['_id'] ?? json['id'] ?? '') as String,
        content: (json['messageText'] ?? json['content'] ?? '') as String,
        sender: isUser ? MessageSender.user : MessageSender.shop,
        sentAt: DateTime.parse(
          json['createdAt'] ??
              json['sentAt'] ??
              DateTime.now().toIso8601String(),
        ),
        isRead: json['isRead'] as bool? ?? false,
        orderId: json['orderId'] as String?,
        orderCodeSnapshot: json['orderCodeSnapshot'] as String?,
      );
    }).toList();
  }

  /// Lấy danh sách các cuộc hội thoại của admin
  Future<List<Map<String, dynamic>>> fetchConversations() async {
    final response = await _apiService.dio.get<Map<String, dynamic>>('/messages/conversations');
    final data = response.data?['data'] as List<dynamic>?;
    if (data != null) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Lấy thông tin chi tiết của người dùng qua ID
  Future<UserModel> fetchUserById(String userId) async {
    final response = await _apiService.dio.get<Map<String, dynamic>>('/users/$userId');
    final data = response.data?['data'] ?? response.data!;
    return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Đánh dấu đã đọc tin nhắn với một user khác qua REST API
  Future<void> markAsRead(String otherUserId) async {
    await _apiService.dio.post<Map<String, dynamic>>('/messages/read/$otherUserId');
  }
}
