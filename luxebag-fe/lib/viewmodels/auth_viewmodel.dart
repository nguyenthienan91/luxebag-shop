import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      // TODO: Replace with actual API call via repository
      await Future.delayed(const Duration(milliseconds: 1200));
      _currentUser = UserModel(id: '1', name: 'User', email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      // TODO: Replace with actual API call via repository
      await Future.delayed(const Duration(milliseconds: 1200));
      _currentUser = UserModel(id: '1', name: name, email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      // TODO: Replace with actual API call via repository
      await Future.delayed(const Duration(milliseconds: 1200));
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    _setLoading(true);
    try {
      // TODO: replace with PUT /users/profile API call
      await Future.delayed(const Duration(milliseconds: 1000));
      _currentUser = _currentUser?.copyWith(name: name, phone: phone);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
}
