import '../models/order_model.dart';
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

  Future<void> checkout({
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    await _apiService.dio.post(
      '/orders/checkout',
      data: {
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
      },
    );
  }
}
