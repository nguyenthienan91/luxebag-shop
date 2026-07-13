class OrderItemModel {
  final String productId;
  final String title;
  final String sku;
  final String? image;
  final double priceAtPurchase;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.title,
    required this.sku,
    this.image,
    required this.priceAtPurchase,
    required this.quantity,
  });

  double get subtotal => priceAtPurchase * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      image: json['image'] as String?,
      priceAtPurchase: (json['priceAtPurchase'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

enum OrderStatus { pending, processing, shipped, completed, cancelled }

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItemModel> items;
  final double totalAmount;
  final OrderStatus status;
  final String paymentMethod;
  final String? paymentStatus;
  final String shippingAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.paymentStatus,
    required this.shippingAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      items: (json['items'] as List?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatusExt.fromString(json['status'] as String? ?? 'pending'),
      paymentMethod: json['paymentMethod'] as String? ?? 'COD',
      paymentStatus: json['paymentStatus'] as String?,
      shippingAddress: json['shippingAddress'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
