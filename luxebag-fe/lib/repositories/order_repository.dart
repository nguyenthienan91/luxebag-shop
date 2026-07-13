import '../models/order_model.dart';
import '../models/revenue_stats_model.dart';
import '../services/api_service.dart';

class OrderRepository {
  final ApiService _apiService;

  OrderRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<OrderModel>> fetchMyOrders() async {
    final response = await _apiService.dio.get<Map<String, dynamic>>('/orders');
    final data = response.data?['data'];

    if (data is List) {
      return data
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<OrderModel> fetchOrderById(String orderId) async {
    final response = await _apiService.dio.get<Map<String, dynamic>>('/orders/$orderId');
    final data = response.data?['data'];
    if (data != null) {
      return OrderModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Order not found');
  }

  Future<Map<String, dynamic>?> checkout({
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    final response = await _apiService.dio.post<Map<String, dynamic>>(
      '/orders/checkout',
      data: {
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
      },
    );
    return response.data?['data'] as Map<String, dynamic>?;
  }

  Future<RevenueStatsModel> fetchRevenueStats({String period = '7d'}) async {
    final response = await _apiService.dio.get<Map<String, dynamic>>(
      '/orders/revenue-stats',
      queryParameters: {'period': period},
    );
    final data = response.data?['data'];
    if (data != null) {
      return RevenueStatsModel.fromJson(data as Map<String, dynamic>);
    }
    return const RevenueStatsModel(totalRevenue: 0, period: '7d', data: []);
  }

  /// GET /orders/admin
  /// [ADMIN] lấy toàn bộ đơn hàng của hệ thống có phân trang + lọc theo trạng thái
  Future<({List<OrderModel> orders, int totalPages, int totalItems})> fetchAdminOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'itemPerPage': limit,
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _apiService.dio.get<Map<String, dynamic>>(
      '/orders/admin',
      queryParameters: queryParams,
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final list = (data['list'] as List<dynamic>?)
            ?.map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return (
      orders: list,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      totalItems: (data['totalItems'] as num?)?.toInt() ?? list.length,
    );
  }

  /// PATCH /orders/:orderId/status
  /// [ADMIN] cập nhật trạng thái đơn hàng
  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    final response = await _apiService.dio.patch<Map<String, dynamic>>(
      '/orders/$orderId/status',
      data: {'status': status},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }
}

