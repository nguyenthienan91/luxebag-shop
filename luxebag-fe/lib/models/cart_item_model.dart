import 'product_model.dart';

class CartItemModel {
  final String id;
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.id,
    required this.product,
    this.quantity = 1,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productData = json['productId'] ?? json['product'];
    return CartItemModel(
      id: json['_id'] as String? ?? '',
      product: ProductModel.fromJson(productData as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  // Getters tương thích với code UI hiện tại
  String get productId => product.id;
  String get title => product.title;
  String get brand => product.brand;
  String get thumbnailUrl => product.thumbnailUrl;
  double get price => product.currentPrice;
  double? get originalPrice => product.isOnSale ? product.retailPrice : null;
  double get subtotal => price * quantity;
}
