import '../models/inventory_model.dart';
import '../services/api_service.dart';

class InventoryRepository {
  final ApiService _apiService;

  InventoryRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// GET /inventory/:productId
  /// Lấy thông tin tồn kho của 1 sản phẩm.
  Future<InventoryModel> getInventory(String productId) async {
    final response = await _apiService.dio.get<Map<String, dynamic>>(
      '/inventory/$productId',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return InventoryModel.fromJson(data);
  }

  /// PATCH /inventory/:productId/stock
  /// ADMIN set số lượng tồn kho (giá trị tuyệt đối).
  Future<InventoryModel> setStock(String productId, int stock) async {
    final response = await _apiService.dio.patch<Map<String, dynamic>>(
      '/inventory/$productId/stock',
      data: {'stock': stock},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return InventoryModel.fromJson(data);
  }

  /// PATCH /inventory/:productId
  /// ADMIN import hoặc deduct tồn kho (giá trị tương đối).
  /// [action] nhận 'IMPORT' hoặc 'DEDUCT'.
  Future<InventoryModel> adjustStock(
    String productId,
    String action,
    int quantity,
  ) async {
    final response = await _apiService.dio.patch<Map<String, dynamic>>(
      '/inventory/$productId',
      data: {'action': action, 'quantity': quantity},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return InventoryModel.fromJson(data);
  }

  /// POST /inventory/bulk-init
  /// ADMIN init inventory cho tất cả products chưa có record.
  Future<int> bulkInit() async {
    final response = await _apiService.dio.post<Map<String, dynamic>>(
      '/inventory/bulk-init',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return (data['initialized'] as num?)?.toInt() ?? 0;
  }
}
