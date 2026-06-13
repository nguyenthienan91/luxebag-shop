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

  List<CartItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCartItems => _cartItems.length;

  double get totalAmount => _cartItems.fold(
      0, (sum, item) => sum + (item.product.currentPrice * item.quantity));

  // ── Alias getters/methods tương thích UI cũ ──
  List<CartItemModel> get items => _cartItems;
  bool get isEmpty => _cartItems.isEmpty;
  int get totalItems => totalCartItems;
  double get subtotal => totalAmount;
  double get shippingFee => totalAmount == 0 ? 0 : (totalAmount >= 500 ? 0 : 15.0);
  double get total => subtotal + shippingFee;

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
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
    notifyListeners();

    try {
      await _repository.removeFromCart(productId);
      _cartItems.removeWhere((item) => item.product.id == productId);
    } catch (e) {
      _errorMessage = _parseError(e);
      await fetchCart();
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
