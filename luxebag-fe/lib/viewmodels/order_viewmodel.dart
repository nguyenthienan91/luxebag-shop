import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/order_model.dart';
import '../models/revenue_stats_model.dart';
import '../repositories/order_repository.dart';
import 'cart_viewmodel.dart';

class OrderViewModel extends ChangeNotifier {
  final OrderRepository _repository;

  OrderViewModel({OrderRepository? repository})
      : _repository = repository ?? OrderRepository();

  List<OrderModel> _myOrders = [];
  List<OrderModel> _adminOrders = [];
  RevenueStatsModel? _revenueStats;
  bool _isLoading = false;
  String? _errorMessage;

  // Admin orders pagination state
  int _adminTotalPages = 1;
  int _adminTotalItems = 0;
  int _adminCurrentPage = 1;
  bool _isAdminLoadingMore = false;

  List<OrderModel> get myOrders => List.unmodifiable(_myOrders);
  List<OrderModel> get adminOrders => List.unmodifiable(_adminOrders);
  RevenueStatsModel? get revenueStats => _revenueStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get adminTotalPages => _adminTotalPages;
  int get adminTotalItems => _adminTotalItems;
  int get adminCurrentPage => _adminCurrentPage;
  bool get isAdminLoadingMore => _isAdminLoadingMore;
  bool get adminHasMore => _adminOrders.length < _adminTotalItems;

  List<OrderModel> getByStatus(OrderStatus? status) {
    if (status == null) return myOrders;
    return _myOrders.where((o) => o.status == status).toList();
  }

  Future<void> fetchMyOrders() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myOrders = await _repository.fetchMyOrders();
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> fetchOrderById(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _repository.fetchOrderById(orderId);
      
      // Sync order in local list if it exists
      final index = _myOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final list = List<OrderModel>.from(_myOrders);
        list[index] = order;
        _myOrders = list;
      }

      return order;
    } catch (e) {
      _errorMessage = _parseError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isLoadingStats = false;
  bool get isLoadingStats => _isLoadingStats;

  Future<void> fetchRevenueStats({String period = '7d'}) async {
    _isLoadingStats = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _revenueStats = await _repository.fetchRevenueStats(period: period);
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> checkout(
    String address,
    String paymentMethod,
    CartViewModel cartViewModel,
  ) async {
    if (_isLoading) return null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.checkout(
        shippingAddress: address,
        paymentMethod: paymentMethod,
        selectedProductIds: cartViewModel.selectedItems.toList(),
      );

      // LOGIC ĐỒNG BỘ QUAN TRỌNG: Cập nhật giỏ hàng từ server vì nó chỉ xóa những mặt hàng đã thanh toán
      await cartViewModel.fetchCart();

      // Cập nhật lại lịch sử đơn hàng
      await fetchMyOrders();

      return result;
    } catch (e) {
      _errorMessage = _parseError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchAdminOrders({
    int page = 1,
    OrderStatus? status,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      if (_isAdminLoadingMore || !adminHasMore) return;
      _isAdminLoadingMore = true;
    } else {
      if (_isLoading) return;
      _isLoading = true;
      _errorMessage = null;
      _adminCurrentPage = 1;
      _adminOrders = [];
    }
    notifyListeners();

    try {
      final statusStr = status?.name;
      final result = await _repository.fetchAdminOrders(
        page: page,
        status: statusStr,
      );

      if (isLoadMore) {
        _adminOrders = [..._adminOrders, ...result.orders];
        _adminCurrentPage = page;
      } else {
        _adminOrders = result.orders;
      }
      _adminTotalPages = result.totalPages;
      _adminTotalItems = result.totalItems;
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      if (isLoadMore) {
        _isAdminLoadingMore = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> cancelMyOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder = await _repository.cancelOrder(orderId);

      // Sync local myOrders list
      final index = _myOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final list = List<OrderModel>.from(_myOrders);
        list[index] = updatedOrder;
        _myOrders = list;
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> recreatePaymentUrl(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder = await _repository.recreatePaymentUrl(orderId);

      // Sync local myOrders list
      final index = _myOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final list = List<OrderModel>.from(_myOrders);
        list[index] = updatedOrder;
        _myOrders = list;
      }
      return updatedOrder;
    } catch (e) {
      _errorMessage = _parseError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus nextStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder = await _repository.updateOrderStatus(
        orderId,
        nextStatus.name,
      );

      final index = _adminOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final list = List<OrderModel>.from(_adminOrders);
        list[index] = updatedOrder;
        _adminOrders = list;
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _parseError(Object e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
    }
    final msg = e.toString();
    if (msg.contains('connectionTimeout') ||
        msg.contains('connectionError') ||
        msg.contains('SocketException')) {
      return 'Cannot connect to server.';
    }
    return msg.replaceAll('Exception: ', '');
  }
}
