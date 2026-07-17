import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../repositories/cart_repository.dart';

class CartViewModel extends ChangeNotifier {
  final CartRepository _repository;

  CartViewModel({CartRepository? repository})
      : _repository = repository ?? CartRepository();

  List<CartItemModel> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _loadingItems = {}; // Khóa nút bấm từng item
  final Set<String> _selectedItems = {}; // Sản phẩm được chọn

  List<CartItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<String> get selectedItems => _selectedItems;

  int get totalCartItems => _cartItems.length;

  double get totalAmount => _cartItems.fold(
      0, (sum, item) => sum + (item.product.currentPrice * item.quantity));

  // ── Alias getters/methods tương thích UI cũ ──
  List<CartItemModel> get items => _cartItems;
  bool get isEmpty => _cartItems.isEmpty;
  int get totalItems => totalCartItems;
  
  // Tính tổng tiền chỉ cho các sản phẩm ĐƯỢC CHỌN
  double get subtotal => _cartItems
      .where((item) => _selectedItems.contains(item.productId))
      .fold(0, (sum, item) => sum + (item.product.currentPrice * item.quantity));
  
  double get shippingFee => 0.0;
  double get total => subtotal + shippingFee;
  
  // ── Selection Logic ──
  void toggleItemSelection(String productId) {
    if (_selectedItems.contains(productId)) {
      _selectedItems.remove(productId);
    } else {
      _selectedItems.add(productId);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedItems.addAll(_cartItems.map((e) => e.productId));
    notifyListeners();
  }

  void deselectAll() {
    _selectedItems.clear();
    notifyListeners();
  }

  bool get isAllSelected => 
      _cartItems.isNotEmpty && _selectedItems.length == _cartItems.length;

  void clearCartLocal() {
    _cartItems.clear();
    _selectedItems.clear();
    notifyListeners();
  }

  Future<void> clearAllCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.clearCart();
      _cartItems.clear();
      _selectedItems.clear();
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String productId, int quantity) =>
      updateCartQuantity(productId, quantity);

  Future<void> removeItem(String productId) => removeFromCart(productId);

  bool isItemLoading(String productId) => _loadingItems.contains(productId);

  Future<void> fetchCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cartItems = await _repository.fetchCart();
      // Loại bỏ những item đã bị xóa khỏi _selectedItems (nếu có)
      _selectedItems.retainWhere((id) => _cartItems.any((item) => item.productId == id));
      print('=== DEBUG CART: fetchCart SUCCESS, items: ${_cartItems.length} ===');
    } catch (e, stack) {
      print('=== DEBUG CART ERROR ===');
      print(e);
      print(stack);
      print('========================');
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(String productId, int quantity) async {
    _loadingItems.add(productId);
    notifyListeners();

    try {
      await _repository.addToCart(productId, quantity);
      await fetchCart(); // Refresh toàn bộ giỏ hàng để lấy info populate
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _loadingItems.remove(productId);
      notifyListeners();
    }
  }

  Future<void> updateCartQuantity(String productId, int newQuantity) async {
    if (newQuantity < 1) return;

    _loadingItems.add(productId);
    notifyListeners();

    try {
      await _repository.updateCartQuantity(productId, newQuantity);

      // Optimistic update
      final index =
          _cartItems.indexWhere((item) => item.product.id == productId);
      if (index != -1) {
        _cartItems[index].quantity = newQuantity;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
      await fetchCart(); // Đồng bộ lại nếu lỗi
    } finally {
      _loadingItems.remove(productId);
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String productId) async {
    _loadingItems.add(productId);
    
    // Optimistic removal
    final removedIndex = _cartItems.indexWhere((item) => item.product.id == productId);
    CartItemModel? removedItem;
    if (removedIndex != -1) {
      removedItem = _cartItems.removeAt(removedIndex);
      _selectedItems.remove(productId);
    }
    notifyListeners();

    try {
      await _repository.removeFromCart(productId);
    } catch (e) {
      _errorMessage = _parseError(e);
      // Revert if error
      if (removedItem != null && removedIndex != -1) {
        _cartItems.insert(removedIndex, removedItem);
      } else {
        await fetchCart();
      }
    } finally {
      _loadingItems.remove(productId);
      notifyListeners();
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('connectionTimeout') ||
        msg.contains('connectionError') ||
        msg.contains('SocketException')) {
      return 'Không thể kết nối đến server.';
    }
    return 'Lỗi xử lý giỏ hàng. Vui lòng thử lại.';
  }
}
