import '../models/cart_item_model.dart';
import '../services/api_service.dart';

class CartRepository {
  final ApiService _apiService;

  CartRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<CartItemModel>> fetchCart() async {
    final response = await _apiService.dio.get<Map<String, dynamic>>('/cart');
    final rawData = response.data!['data'];
    print('=== DEBUG CART: RAW DATA: $rawData ===');
    
    // API có thể trả về data là mảng trực tiếp hoặc object chứa items/list
    final items = rawData is List 
        ? rawData 
        : (rawData['items'] ?? rawData['list'] ?? []);
        
    return (items as List)
        .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToCart(String productId, int quantity) async {
    await _apiService.dio.post('/cart/add', data: {
      'productId': productId,
      'quantity': quantity,
    });
  }

  Future<void> updateCartQuantity(String productId, int quantity) async {
    await _apiService.dio.put('/cart/update', data: {
      'productId': productId,
      'quantity': quantity,
    });
  }

  Future<void> removeFromCart(String productId) async {
    await _apiService.dio.delete('/cart/remove/$productId');
  }

  Future<void> clearCart() async {
    await _apiService.dio.delete('/cart/clear');
  }
}
