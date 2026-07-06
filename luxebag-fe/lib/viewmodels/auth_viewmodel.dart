import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// ViewModel quản lý trạng thái xác thực và thông tin người dùng.
///
/// Tuân thủ nghiêm ngặt MVVM:
/// - Chứa toàn bộ logic nghiệp vụ và xử lý lỗi.
/// - Không lộ kiểu [dynamic] ra bên ngoài – UI luôn nhận [UserModel].
/// - Gọi [notifyListeners] sau mỗi thay đổi state.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  final TokenService _tokenService;

  AuthViewModel({
    AuthRepository? repository,
    TokenService? tokenService,
  })  : _repository = repository ?? AuthRepository(),
        _tokenService = tokenService ?? TokenService();

  // ── State ─────────────────────────────────────────────────────────────────────

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // ── Auto Login ────────────────────────────────────────────────────────────────

  /// Kiểm tra token đã lưu khi khởi động app.
  /// Nếu có token → gọi /users/me để khôi phục phiên.
  Future<void> tryAutoLogin() async {
    final token = await _tokenService.getAccessToken();
    if (token == null || token.isEmpty) return;

    _setLoading(true);
    try {
      _currentUser = await _repository.getProfile();
      _setLoading(false);
    } catch (_) {
      // Token hết hạn hoặc lỗi → không tự động đăng nhập
      await _tokenService.clearTokens();
      _setLoading(false);
    }
  }

  // ── Sign In ───────────────────────────────────────────────────────────────────

  /// Đăng nhập bằng email và mật khẩu.
  /// Trả về [true] nếu thành công, [false] nếu thất bại.
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      _currentUser = await _repository.signIn(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } on AuthExpiredException {
      _setError('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      return false;
    } catch (e) {
      // DEBUG: xem chính xác lỗi gì – xóa sau khi fix xong
      if (e is DioException) {
        debugPrint('=== DIO ERROR ===');
        debugPrint('type: ${e.type}');
        debugPrint('statusCode: ${e.response?.statusCode}');
        debugPrint('message: ${e.message}');
        debugPrint('error: ${e.error}');
        debugPrint('response data: ${e.response?.data}');
      } else {
        debugPrint('=== UNKNOWN ERROR ===');
        debugPrint('type: ${e.runtimeType}');
        debugPrint('toString: $e');
      }
      _setError(_parseError(e));
      return false;
    }
  }

  // ── Google Sign In ──────────────────────────────────────────────────────────

  /// Đăng nhập bằng Google Account.
  /// Trả về [true] nếu thành công, [false] nếu người dùng huỷ hoặc có lỗi.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '259814392558-301snnneauigit03p8lq533jsf07rlig.apps.googleusercontent.com',
      );

      final googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        // Người dùng huỷ đăng nhập
        _setLoading(false);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Không lấy được ID Token từ Google.');
      }

      _currentUser = await _repository.googleSignIn(idToken);
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('=== GOOGLE SIGN IN ERROR ===');
      debugPrint(e.toString());
      _setError(_parseError(e));
      return false;
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────────

  /// Đăng ký tài khoản mới.
  /// Trả về [true] nếu thành công, [false] nếu thất bại.
  Future<bool> signUp(Map<String, dynamic> registerData) async {
    _setLoading(true);
    try {
      await _repository.signUp(registerData);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_parseError(e));
      return false;
    }
  }

  // ── Get Profile ───────────────────────────────────────────────────────────────

  /// Lấy thông tin người dùng hiện tại (dùng khi khởi động hoặc cần refresh dữ liệu).
  Future<void> getProfile() async {
    _setLoading(true);
    try {
      _currentUser = await _repository.getProfile();
      _setLoading(false);
    } catch (e) {
      _setError(_parseError(e));
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────────

  /// Gửi email đặt lại mật khẩu. Trả về [true] nếu request được chấp nhận.
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _repository.forgotPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_parseError(e));
      return false;
    }
  }

  // ── Update Profile ────────────────────────────────────────────────────────────

  /// Cập nhật tên và số điện thoại. Trả về [true] nếu thành công.
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _repository.updateProfile(
        name: name,
        phone: phone,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_parseError(e));
      return false;
    }
  }

  // ── Upload Avatar ─────────────────────────────────────────────────────────────

  /// Upload ảnh đại diện từ [File] cục bộ lên server.
  /// Sau khi backend trả về URL mới, cập nhật [_currentUser.avatarUrl].
  Future<bool> uploadAvatar(File imageFile) async {
    _setLoading(true);
    try {
      _currentUser = await _repository.uploadAvatar(imageFile);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_parseError(e));
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  /// Đăng xuất: hủy token trên server, xóa token cục bộ, reset state.
  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Xóa thông báo lỗi hiện tại (UI gọi sau khi đã hiển thị SnackBar).
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

  /// Phân tích exception từ Dio để trả về thông báo lỗi thân thiện.
  String _parseError(Object e) {
    if (e is DioException) {
      // Lỗi kết nối mạng (timeout, socket, no internet)
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối đến server. Vui lòng kiểm tra mạng.';
      }

      // Lỗi cancel do RefreshInterceptor ném AuthExpiredException
      if (e.type == DioExceptionType.cancel && e.error is AuthExpiredException) {
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      }

      // Lỗi HTTP – kiểm tra status code
      final statusCode = e.response?.statusCode;
      switch (statusCode) {
        case 400:
          return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
        case 401:
          final msg = e.response?.data?['message'];
          if (msg is String && msg.isNotEmpty) return msg;
          return 'Email hoặc mật khẩu không đúng.';
        case 403:
          return 'Bạn không có quyền thực hiện hành động này.';
        case 404:
          return 'Không tìm thấy tài nguyên.';
        case 409:
          return 'Email này đã được đăng ký.';
        case 500:
          return 'Lỗi server. Vui lòng thử lại sau.';
        default:
          // Lấy message từ response body nếu có
          final msg = e.response?.data?['message'];
          if (msg is String && msg.isNotEmpty) return msg;
          if (statusCode != null) {
            return 'Đã xảy ra lỗi ($statusCode). Vui lòng thử lại.';
          }
          return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
      }
    }

    if (e is SocketException) {
      return 'Không có kết nối internet. Vui lòng kiểm tra mạng.';
    }

    return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
  }
}
