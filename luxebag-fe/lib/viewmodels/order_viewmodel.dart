import 'package:flutter/foundation.dart';
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

  List<OrderModel> get myOrders => List.unmodifiable(_myOrders);
  List<OrderModel> get adminOrders => List.unmodifiable(_adminOrders);
  RevenueStatsModel? get revenueStats => _revenueStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  Future<bool> checkout(
    String address,
    String paymentMethod,
    CartViewModel cartViewModel,
  ) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.checkout(
        shippingAddress: address,
        paymentMethod: paymentMethod,
      );

      // LOGIC ĐỒNG BỘ QUAN TRỌNG: Dọn dẹp giỏ hàng cục bộ ngay lập tức!
      cartViewModel.clearCart();

      // Cập nhật lại lịch sử đơn hàng
      await fetchMyOrders();

      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('connectionTimeout') ||
        msg.contains('connectionError') ||
        msg.contains('SocketException')) {
      return 'Cannot connect to server.';
    }
    return msg.replaceAll('Exception: ', '');
  }
}
