class CartItemModel {
  final String productId;
  final String title;
  final String brand;
  final String thumbnailUrl;
  final double price;
  final double? originalPrice;
  int quantity;

  CartItemModel({
    required this.productId,
    required this.title,
    required this.brand,
    required this.thumbnailUrl,
    required this.price,
    this.originalPrice,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      productId: productId,
      title: title,
      brand: brand,
      thumbnailUrl: thumbnailUrl,
      price: price,
      originalPrice: originalPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}
