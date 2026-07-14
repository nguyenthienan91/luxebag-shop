import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repository;

  UserViewModel({UserRepository? repository})
      : _repository = repository ?? UserRepository();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Tải danh sách người dùng từ backend
  Future<void> loadUsers({
    String? search,
    String? role,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _repository.fetchUsers(
        search: search,
        role: role,
        isActive: isActive,
      );
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo người dùng mới
  Future<bool> createUser(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createUser(data);
      // Reload danh sách sau khi tạo thành công
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật thông tin người dùng
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _repository.updateUser(userId, data);
      
      // Đồng bộ danh sách cục bộ
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bật/Tắt trạng thái hoạt động của người dùng
  Future<bool> toggleUserStatus(String userId, bool newStatus) async {
    return await updateUser(userId, {'isActive': newStatus});
  }

  /// Xóa người dùng
  Future<bool> deleteUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteUser(userId);
      _users.removeWhere((u) => u.id == userId);
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _parseError(dynamic error) {
    if (error is String) return error;
    try {
      if (error.response?.data != null) {
        final data = error.response.data;
        if (data['message'] != null) {
          final msg = data['message'];
          if (msg is List) return msg.join(', ');
          return msg.toString();
        }
      }
    } catch (_) {}
    return error.toString();
  }
}
