class OrderItemModel {
  final String productId;
  final String title;
  final String brand;
  final String thumbnailUrl;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.title,
    required this.brand,
    required this.thumbnailUrl,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] as String,
      title: json['title'] as String,
      brand: json['brand'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
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
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class OrderModel {
  final String id;
  final String orderCode;
  final List<OrderItemModel> items;
  final double subtotal;
  final double shippingFee;
  final double total;
  final OrderStatus status;
  final String paymentMethod;
  final String shippingAddress;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.orderCode,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderCode: json['orderCode'] as String,
      items: (json['items'] as List)
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      shippingFee: (json['shippingFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: OrderStatusExt.fromString(json['status'] as String),
      paymentMethod: json['paymentMethod'] as String,
      shippingAddress: json['shippingAddress'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
