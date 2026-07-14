import '../models/user_model.dart';
import '../services/api_service.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// GET /users
  /// Lấy danh sách người dùng với search và filter.
  Future<List<UserModel>> fetchUsers({
    String? search,
    String? role,
    bool? isActive,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (role != null && role.isNotEmpty) {
      queryParams['role'] = role;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final response = await _apiService.dio.get<dynamic>(
      '/users',
      queryParameters: queryParams,
    );

    final rawData = response.data;
    List<dynamic> list;
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData['data'] is List) {
      list = rawData['data'] as List<dynamic>;
    } else if (rawData is Map && rawData['list'] is List) {
      list = rawData['list'] as List<dynamic>;
    } else {
      list = [];
    }

    return list.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// POST /users
  /// Tạo người dùng mới.
  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final response = await _apiService.dio.post<dynamic>(
      '/users',
      data: data,
    );
    final rawData = response.data!;
    final userData = rawData is Map && rawData.containsKey('data')
        ? rawData['data'] as Map<String, dynamic>
        : rawData as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  /// PATCH /users/:id
  /// Cập nhật thông tin người dùng.
  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    final response = await _apiService.dio.patch<dynamic>(
      '/users/$userId',
      data: data,
    );
    final rawData = response.data!;
    final userData = rawData is Map && rawData.containsKey('data')
        ? rawData['data'] as Map<String, dynamic>
        : rawData as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  /// DELETE /users/:id
  /// Xóa người dùng.
  Future<void> deleteUser(String userId) async {
    await _apiService.dio.delete<void>('/users/$userId');
  }
}
