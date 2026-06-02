import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

class OrderViewModel extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<OrderModel> getByStatus(OrderStatus? status) {
    if (status == null) return orders;
    return _orders.where((o) => o.status == status).toList();
  }

  Future<void> loadOrders() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: replace with GET /orders API call
      await Future.delayed(const Duration(milliseconds: 1000));
      _orders = _mockOrders();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addOrder(OrderModel order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Mock Data ──────────────────────────────────────────────────────────────
  List<OrderModel> _mockOrders() {
    final now = DateTime.now();
    return [
      OrderModel(
        id: 'ord1',
        orderCode: 'LB-20260601-0001',
        items: [
          const OrderItemModel(
            productId: 'p1',
            title: 'Classic Tote Bag',
            brand: 'Louis Vuitton',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=200',
            price: 1200,
            quantity: 1,
          ),
        ],
        subtotal: 1200,
        shippingFee: 0,
        total: 1200,
        status: OrderStatus.delivered,
        paymentMethod: 'Credit Card',
        shippingAddress: '123 Example St, Ho Chi Minh City',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      OrderModel(
        id: 'ord2',
        orderCode: 'LB-20260525-0042',
        items: [
          const OrderItemModel(
            productId: 'p2',
            title: 'Mini Crossbody Bag',
            brand: 'Gucci',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=200',
            price: 850,
            quantity: 1,
          ),
          const OrderItemModel(
            productId: 'p3',
            title: 'Leather Clutch',
            brand: 'Prada',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1566150905458-1bf1fc113f0d?w=200',
            price: 420,
            quantity: 2,
          ),
        ],
        subtotal: 1690,
        shippingFee: 0,
        total: 1690,
        status: OrderStatus.shipped,
        paymentMethod: 'COD',
        shippingAddress: '456 Another St, Ha Noi',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      OrderModel(
        id: 'ord3',
        orderCode: 'LB-20260520-0033',
        items: [
          const OrderItemModel(
            productId: 'p4',
            title: 'Structured Shoulder Bag',
            brand: 'Chanel',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1575032617751-6ddec2089882?w=200',
            price: 2400,
            quantity: 1,
          ),
        ],
        subtotal: 2400,
        shippingFee: 15,
        total: 2415,
        status: OrderStatus.cancelled,
        paymentMethod: 'Bank Transfer',
        shippingAddress: '789 Third St, Da Nang',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      OrderModel(
        id: 'ord4',
        orderCode: 'LB-20260601-0055',
        items: [
          const OrderItemModel(
            productId: 'p5',
            title: 'Quilted Flap Bag',
            brand: 'Dior',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=200',
            price: 3200,
            quantity: 1,
          ),
        ],
        subtotal: 3200,
        shippingFee: 0,
        total: 3200,
        status: OrderStatus.pending,
        paymentMethod: 'Credit Card',
        shippingAddress: '321 Fourth Ave, Ho Chi Minh City',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }
}
