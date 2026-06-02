import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartViewModel extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItemModel> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _items.isEmpty;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  double get shippingFee {
    if (_items.isEmpty) return 0;
    final hasFreeShipping = subtotal >= 500;
    return hasFreeShipping ? 0 : 15;
  }

  double get total => subtotal + shippingFee;

  void addToCart(ProductModel product) {
    final idx = _items.indexWhere((e) => e.productId == product.id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + 1);
    } else {
      _items.add(
        CartItemModel(
          productId: product.id,
          title: product.title,
          brand: product.brand,
          thumbnailUrl: product.thumbnailUrl,
          price: product.currentPrice,
          originalPrice: product.isOnSale ? product.retailPrice : null,
        ),
      );
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final idx = _items.indexWhere((e) => e.productId == productId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((e) => e.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Checks if a product is in cart
  bool hasProduct(String productId) =>
      _items.any((e) => e.productId == productId);

  int quantityOf(String productId) {
    final idx = _items.indexWhere((e) => e.productId == productId);
    return idx >= 0 ? _items[idx].quantity : 0;
  }
}
