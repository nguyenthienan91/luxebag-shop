import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationRepository {
  final ApiService _apiService;

  NotificationRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Lấy danh sách thông báo của user hiện tại (hỗ trợ phân trang)
  Future<({List<NotificationModel> notifications, int totalPages, int totalItems})>
  fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final list = (data['list'] as List<dynamic>)
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return (
      notifications: list,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      totalItems: (data['totalItems'] as num?)?.toInt() ?? list.length,
    );
  }

  /// Đánh dấu đã đọc cho một thông báo cụ thể
  Future<NotificationModel> markAsRead(String id) async {
    final response = await _apiService.dio.put<Map<String, dynamic>>('/notifications/$id/read');
    final data = response.data!['data'] as Map<String, dynamic>;
    return NotificationModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Đánh dấu đã đọc toàn bộ thông báo
  Future<int> markAllAsRead() async {
    final response = await _apiService.dio.put<Map<String, dynamic>>('/notifications/read-all');
    final data = response.data!['data'] as Map<String, dynamic>;
    return (data['modifiedCount'] as num?)?.toInt() ?? 0;
  }
}
