import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../models/product_model.dart';
import '../repositories/inventory_repository.dart';

class InventoryViewModel extends ChangeNotifier {
  final InventoryRepository _repository;

  InventoryViewModel({InventoryRepository? repository})
      : _repository = repository ?? InventoryRepository();

  // ── States ─────────────────────────────────────────────────────────────────
  final Map<String, InventoryModel> _inventoryMap = {};
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────
  Map<String, InventoryModel> get inventoryMap => _inventoryMap;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  InventoryModel? getInventoryForProduct(String productId) {
    return _inventoryMap[productId];
  }

  // ── Operations ─────────────────────────────────────────────────────────────

  /// Tải thông tin tồn kho cho danh sách sản phẩm song song.
  Future<void> fetchInventoryForProducts(List<ProductModel> products) async {
    if (products.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = products.map((product) async {
        try {
          final inv = await _repository.getInventory(product.id);
          _inventoryMap[product.id] = inv;
        } catch (e) {
          // Fallback: nếu sản phẩm chưa được khởi tạo kho trên backend (404),
          // ta hiển thị stock = 0 để tránh crash hoặc loading vô tận.
          if (!_inventoryMap.containsKey(product.id)) {
            _inventoryMap[product.id] = InventoryModel(
              productId: product.id,
              stock: 0,
              logs: [],
            );
          }
        }
      });

      await Future.wait(futures);
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật trực tiếp số lượng tồn kho (Tuyệt đối).
  Future<void> setStock(String productId, int stock) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final inv = await _repository.setStock(productId, stock);
      _inventoryMap[productId] = inv;
    } catch (e) {
      _errorMessage = _parseError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nhập hoặc trừ số lượng tồn kho (Tương đối).
  /// [action] nhận giá trị 'IMPORT' hoặc 'DEDUCT'.
  Future<void> adjustStock(String productId, String action, int quantity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final inv = await _repository.adjustStock(productId, action, quantity);
      _inventoryMap[productId] = inv;
    } catch (e) {
      _errorMessage = _parseError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Khởi tạo tồn kho hàng loạt cho sản phẩm chưa có record.
  Future<int> bulkInit() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final initializedCount = await _repository.bulkInit();
      return initializedCount;
    } catch (e) {
      _errorMessage = _parseError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper để phân tích lỗi từ HTTP call
  String _parseError(dynamic error) {
    if (error is String) return error;
    try {
      if (error.response?.data != null && error.response.data['message'] != null) {
        final msg = error.response.data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
    } catch (_) {}
    return error.toString();
  }
}
