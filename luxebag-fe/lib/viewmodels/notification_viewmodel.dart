import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: replace with GET /notifications API call
      await Future.delayed(const Duration(milliseconds: 700));
      _notifications = _mockNotifications();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx < 0 || _notifications[idx].isRead) return;

    // Optimistic update
    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    notifyListeners();

    try {
      // TODO: call PUT /notifications/:id/read
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      // Revert on failure
      _notifications[idx] = _notifications[idx].copyWith(isRead: false);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();
    // TODO: call PUT /notifications/read-all
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Mock Data ──────────────────────────────────────────────────────────────
  List<NotificationModel> _mockNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'n1',
        title: 'Order Shipped! 🚚',
        body:
            'Your order LB-20260525-0042 has been shipped. Expected delivery in 2-3 days.',
        type: NotificationType.order,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
        referenceId: 'ord2',
      ),
      NotificationModel(
        id: 'n2',
        title: 'Flash Sale — Up to 40% Off!',
        body:
            'Limited time offer on selected designer bags. Shop now before they\'re gone!',
        type: NotificationType.promotion,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        id: 'n3',
        title: 'Order Delivered ✅',
        body:
            'Your order LB-20260601-0001 has been delivered. Enjoy your new LuxeBag!',
        type: NotificationType.order,
        isRead: false,
        createdAt: now.subtract(const Duration(days: 1)),
        referenceId: 'ord1',
      ),
      NotificationModel(
        id: 'n4',
        title: 'Welcome to LuxeBag!',
        body:
            'Thank you for joining us. Discover our exclusive collection of luxury bags.',
        type: NotificationType.system,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      NotificationModel(
        id: 'n5',
        title: 'New Arrivals — Dior Summer 2026',
        body:
            'The Dior Summer 2026 collection has just landed. Be the first to explore!',
        type: NotificationType.promotion,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }
}
