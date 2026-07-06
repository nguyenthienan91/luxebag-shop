import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationViewModel({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;

  Future<void> loadNotifications({bool refresh = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    if (refresh) {
      _currentPage = 1;
    }
    notifyListeners();

    try {
      final result = await _repository.fetchNotifications(
        page: _currentPage,
        limit: 50,
      );
      if (refresh) {
        _notifications = result.notifications;
      } else {
        _notifications.addAll(result.notifications);
      }
      _totalPages = result.totalPages;
      _totalItems = result.totalItems;
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
      await _repository.markAsRead(id);
    } catch (e) {
      // Revert on failure
      _notifications[idx] = _notifications[idx].copyWith(isRead: false);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final oldNotifications = List<NotificationModel>.from(_notifications);

    // Optimistic update
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    try {
      await _repository.markAllAsRead();
    } catch (e) {
      // Revert on failure
      _notifications = oldNotifications;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
