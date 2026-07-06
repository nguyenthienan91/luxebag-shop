import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

/// Repository xử lý toàn bộ HTTP call liên quan đến sản phẩm và danh mục.
/// Không chứa state UI.
class ProductRepository {
  final ApiService _apiService;

  ProductRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ── Fetch Products ────────────────────────────────────────────────────────

  /// Lấy danh sách sản phẩm từ backend.
  /// Backend trả về: { "data": { "list": [...], "totalPages": N, "totalItems": N } }
  Future<({List<ProductModel> products, int totalPages, int totalItems})>
  fetchProducts({
    String? search,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['categoryId'] = categoryId;
    }
    if (minPrice != null) queryParams['minPrice'] = minPrice;
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
    queryParams['page'] = page;
    queryParams['limit'] = limit;

    final response = await _apiService.dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: queryParams,
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final list = (data['list'] as List<dynamic>)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return (
      products: list,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      totalItems: (data['totalItems'] as num?)?.toInt() ?? list.length,
    );
  }

  // ── Fetch Categories ──────────────────────────────────────────────────────

  /// Lấy danh sách danh mục từ backend.
  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _apiService.dio.get<Map<String, dynamic>>(
      '/categories',
    );

    // Hỗ trợ cả 2 dạng response: { data: [...] } hoặc [...] trực tiếp
    final raw = response.data!;
    final list = raw['data'] is List
        ? raw['data'] as List<dynamic>
        : raw['list'] is List
        ? raw['list'] as List<dynamic>
        : raw as List<dynamic>;

    return (list as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Wishlist ──────────────────────────────────────────────────────────────

  /// Lấy danh sách wishlist của user hiện tại
  Future<List<ProductModel>> getWishlist() async {
    final response = await _apiService.dio.get<Map<String, dynamic>>('/wishlist');
    final rawData = response.data!['data'];
    final list = rawData is List ? rawData : (rawData['list'] ?? rawData['wishlist'] ?? []);
    
    return (list as List).map((e) {
      if (e is Map<String, dynamic>) {
        if (e.containsKey('productId') && e['productId'] is Map) {
          return ProductModel.fromJson(e['productId'] as Map<String, dynamic>);
        } else if (e.containsKey('product') && e['product'] is Map) {
          return ProductModel.fromJson(e['product'] as Map<String, dynamic>);
        }
      }
      return ProductModel.fromJson(e as Map<String, dynamic>);
    }).toList();
  }

  /// Thêm sản phẩm vào wishlist
  Future<void> addToWishlist(String productId) async {
    await _apiService.dio.post('/wishlist', data: {'productId': productId});
  }

  /// Xóa sản phẩm khỏi wishlist
  Future<void> removeFromWishlist(String productId) async {
    await _apiService.dio.delete('/wishlist/$productId');
  }

  // ── Admin: CRUD Products ──────────────────────────────────────────────────

  /// Tạo sản phẩm mới
  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final response = await _apiService.dio.post<Map<String, dynamic>>(
      '/products',
      data: data,
    );
    final responseData = response.data!['data'];
    return ProductModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// Cập nhật sản phẩm
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await _apiService.dio.patch<Map<String, dynamic>>(
      '/products/$id',
      data: data,
    );
    final responseData = response.data!['data'];
    return ProductModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// Xóa sản phẩm (Soft delete)
  Future<void> deleteProduct(String id) async {
    await _apiService.dio.delete('/products/$id');
  }

  /// Upload ảnh cho sản phẩm
  Future<void> uploadProductImages(String productId, List<XFile> images) async {
    final formData = FormData();
    for (var image in images) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(image.path, filename: image.name),
      ));
    }

    await _apiService.dio.post(
      '/products/$productId/upload-images',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }
}
