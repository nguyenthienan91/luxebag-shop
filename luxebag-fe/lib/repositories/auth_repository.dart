import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

/// Tầng Repository chịu trách nhiệm giao tiếp với backend cho mọi
/// nghiệp vụ xác thực và quản lý tài khoản người dùng.
///
/// - Không chứa state UI (không kế thừa ChangeNotifier).
/// - Chỉ gọi API, phân tích JSON, và trả kết quả về ViewModel.
class AuthRepository {
  final ApiService _apiService;
  final TokenService _tokenService;

  AuthRepository({
    ApiService? apiService,
    TokenService? tokenService,
  })  : _apiService = apiService ?? ApiService(),
        _tokenService = tokenService ?? TokenService();

  Dio get _dio => _apiService.dio;

  // ── Sign In ──────────────────────────────────────────────────────────────────

  /// Đăng nhập và lưu token. Trả về [UserModel] sau khi gọi thêm [getProfile].
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/sign-in',
      data: {'email': email, 'password': password},
    );

    final body = response.data!;
    final accessToken = body['accessToken'] as String;
    final refreshToken = body['refreshToken'] as String;

    // Backend chỉ trả token, lưu lại rồi gọi /users/me
    await _tokenService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return getProfile();
  }

  // ── Google Sign In ──────────────────────────────────────────────────────────
  
  /// Đăng nhập bằng Google token và lưu token trả về từ backend.
  Future<UserModel> googleSignIn(String idToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/google-login',
      data: {'idToken': idToken},
    );

    final body = response.data!;
    final accessToken = body['accessToken'] as String;
    final refreshToken = body['refreshToken'] as String;

    await _tokenService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return getProfile();
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────────

  /// Đăng ký tài khoản mới. Trả về `true` nếu thành công.
  Future<bool> signUp(Map<String, dynamic> registerData) async {
    await _dio.post<dynamic>(
      '/auth/sign-up',
      data: registerData,
    );
    return true;
  }

  // ── Forgot Password ───────────────────────────────────────────────────────────

  /// Gửi yêu cầu đặt lại mật khẩu qua email.
  Future<void> forgotPassword(String email) async {
    await _dio.post<dynamic>(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  // ── Get Profile ──────────────────────────────────────────────────────────────

  /// Lấy thông tin người dùng hiện tại từ token đã lưu.
  Future<UserModel> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/users/me');
    return UserModel.fromJson(response.data!);
  }

  // ── Update Profile ────────────────────────────────────────────────────────────

  /// Cập nhật tên và số điện thoại của người dùng.
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/users/me',
      data: {'displayName': name, 'phoneNumber': phone},
    );
    return UserModel.fromJson(response.data!);
  }

  // ── Upload Avatar ─────────────────────────────────────────────────────────────

  /// Upload ảnh đại diện mới qua multipart/form-data.
  /// Backend NestJS + Multer thường nhận field name là "file".
  Future<UserModel> uploadAvatar(File imageFile) async {
    final fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });

    // Không set contentType thủ công – Dio tự thêm boundary vào multipart/form-data
    final response = await _dio.patch<Map<String, dynamic>>(
      '/users/profile/avatar',
      data: formData,
    );
    // Backend trả { message: 'OKE', data: { ...user } } → phải lấy 'data' bên trong
    final body = response.data!;
    final userData = (body['data'] as Map<String, dynamic>?) ?? body;
    return UserModel.fromJson(userData);
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  /// Gọi API logout (để backend hủy token trên server-side) rồi xóa token cục bộ.
  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } catch (_) {
      // Bỏ qua lỗi mạng khi logout – ưu tiên xóa token cục bộ
    } finally {
      await _tokenService.clearTokens();
    }
  }

  // ── Refresh Token ─────────────────────────────────────────────────────────────

  /// Làm mới Access Token. Hàm này thường được gọi tự động bởi ApiService Interceptor.
  Future<void> refreshToken(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh-token',
      data: {'refreshToken': refreshToken},
    );
    final body = response.data!;
    await _tokenService.saveTokens(
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
    );
  }
}
