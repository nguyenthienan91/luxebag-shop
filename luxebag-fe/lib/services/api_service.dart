import 'package:dio/dio.dart';
import 'token_service.dart';

/// Cấu hình Dio với BaseURL và 2 interceptors:
///   1. [AuthInterceptor] – tự động gắn Access Token vào mỗi request.
///   2. [RefreshInterceptor] – tự động làm mới token khi nhận lỗi 401.
class ApiService {
  // static const String _baseUrl = 'http://10.0.2.2:8888/api';
  static const String _baseUrl = 'https://luxebag-backend.onrender.com/api';
  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  // ── Singleton ────────────────────────────────────────────────────────────────
  ApiService._();
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  late final Dio _dio = _buildDio();
  final TokenService _tokenService = TokenService();

  // Expose Dio instance to repositories
  Dio get dio => _dio;

  // ── Builder ──────────────────────────────────────────────────────────────────
  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(_tokenService),
      _RefreshInterceptor(dio, _tokenService),
    ]);

    return dio;
  }
}

// ── Auth Interceptor ──────────────────────────────────────────────────────────

/// Đọc Access Token từ bộ nhớ và đính kèm vào header Authorization.
class _AuthInterceptor extends Interceptor {
  final TokenService _tokenService;

  _AuthInterceptor(this._tokenService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipPaths = [
      '/auth/sign-in',
      '/auth/sign-up',
      '/auth/refresh-token',
      '/auth/google-login',
    ];
    final shouldSkip = skipPaths.any((p) => options.path.contains(p));

    if (!shouldSkip) {
      final accessToken = await _tokenService.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    return handler.next(options);
  }
}

// ── Refresh Interceptor ───────────────────────────────────────────────────────

/// Tự động xử lý lỗi 401:
///   1. Gọi /auth/refresh-token để lấy token mới.
///   2. Lưu token mới vào bộ nhớ.
///   3. Retry lại request cũ.
///   4. Nếu refresh thất bại → xóa token, ném AuthExpiredException.
class _RefreshInterceptor extends Interceptor {
  final Dio _dio;
  final TokenService _tokenService;
  bool _isRefreshing = false;

  _RefreshInterceptor(this._dio, this._tokenService);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;

    // Các endpoint auth: 401 = sai credentials, KHÔNG phải token hết hạn → bỏ qua
    final skipPaths = ['/auth/sign-in', '/auth/sign-up', '/auth/forgot-password'];
    final isAuthEndpoint = skipPaths.any((p) => requestPath.contains(p));

    // Chỉ xử lý 401 cho các endpoint cần token (không phải auth endpoints)
    if (statusCode == 401 && !requestPath.contains('/auth/refresh-token') && !isAuthEndpoint) {
      if (_isRefreshing) {
        // Đang trong quá trình refresh, trả lỗi gốc
        return handler.next(err);
      }

      _isRefreshing = true;

      try {
        final refreshToken = await _tokenService.getRefreshToken();

        if (refreshToken == null || refreshToken.isEmpty) {
          // Không có refresh token → pass through lỗi gốc (401)
          // ViewModel sẽ xử lý thành "Email hoặc mật khẩu không đúng"
          _isRefreshing = false;
          return handler.next(err);
        }

        // Gọi refresh-token với một Dio instance mới (không qua interceptors)
        final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
        final refreshResponse = await refreshDio.post(
          '/auth/refresh-token',
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken =
            refreshResponse.data['accessToken'] as String? ?? '';
        final newRefreshToken =
            refreshResponse.data['refreshToken'] as String? ?? '';

        if (newAccessToken.isEmpty) {
          throw Exception('Empty access token from refresh response');
        }

        // Lưu token mới
        await _tokenService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        _isRefreshing = false;

        // Retry request cũ với token mới
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await _dio.request<dynamic>(
          retryOptions.path,
          data: retryOptions.data,
          queryParameters: retryOptions.queryParameters,
          options: Options(
            method: retryOptions.method,
            headers: retryOptions.headers,
          ),
        );

        return handler.resolve(retryResponse);
      } catch (_) {
        _isRefreshing = false;
        await _tokenService.clearTokens();
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            type: DioExceptionType.cancel,
            error: AuthExpiredException(),
          ),
        );
      }
    }

    return handler.next(err);
  }
}

// ── Custom Exception ──────────────────────────────────────────────────────────

/// Ném ra khi Access Token hết hạn và Refresh Token cũng không còn hợp lệ.
/// ViewModel bắt exception này để điều hướng người dùng về màn hình Login.
class AuthExpiredException implements Exception {
  @override
  String toString() => 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
}
