import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý việc lưu trữ và truy xuất Access Token / Refresh Token
/// sử dụng SharedPreferences (persistent, không cần flutter_secure_storage).
class TokenService {
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';

  // ── Singleton ────────────────────────────────────────────────────────────────
  TokenService._();
  static final TokenService _instance = TokenService._();
  factory TokenService() => _instance;

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Lưu cặp token mới vào bộ nhớ thiết bị.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  /// Trả về Access Token đang lưu, hoặc `null` nếu chưa đăng nhập.
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  /// Trả về Refresh Token đang lưu, hoặc `null` nếu chưa đăng nhập.
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  /// Xóa toàn bộ token (gọi khi đăng xuất hoặc refresh thất bại).
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
  }
}
