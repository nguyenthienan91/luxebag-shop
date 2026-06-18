import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../repositories/product_repository.dart';

/// ViewModel quản lý danh sách sản phẩm, tìm kiếm, lọc và phân trang.
///
/// Tuân thủ MVVM:
/// - Mọi filter đều gửi qua query params lên backend (không dùng .where() client-side).
/// - UI chỉ gọi các setter; ViewModel tự động gọi lại API.
/// - Debounce 500ms cho ô tìm kiếm để tránh spam request.
class ProductViewModel extends ChangeNotifier {
  final ProductRepository _repository;

  ProductViewModel({ProductRepository? repository})
      : _repository = repository ?? ProductRepository();

  // ── Data ──────────────────────────────────────────────────────────────────
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  
  // ── Wishlist State ────────────────────────────────────────────────────────
  List<ProductModel> _wishlistProducts = [];
  Set<String> _favoritedProductIds = {};

  // ── Filter States ─────────────────────────────────────────────────────────
  String _searchQuery = '';
  String? _selectedCategoryId; // null = "All"
  double? _minPrice;
  double? _maxPrice;

  // ── Pagination ────────────────────────────────────────────────────────────
  int _totalPages = 1;
  int _totalItems = 0;
  static const int _pageSize = 20;

  // ── Loading / Error ───────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // ── Debounce timer ────────────────────────────────────────────────────────
  Timer? _debounceTimer;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _products.length < _totalItems;
  String? get errorMessage => _errorMessage;

  // Wishlist getters
  List<ProductModel> get wishlistedProducts => _wishlistProducts;
  bool isFavorited(String productId) => _favoritedProductIds.contains(productId);

  // ── Public API – Filter Setters ───────────────────────────────────────────

  /// Cập nhật từ khóa tìm kiếm với Debounce 500ms.
  /// Gọi API ngay nếu query trống (người dùng xóa hết text).
  void setSearchQuery(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      fetchProducts();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), fetchProducts);
  }

  /// Tương thích ngược với code cũ dùng onSearchChanged.
  void onSearchChanged(String query) => setSearchQuery(query);

  /// Chọn danh mục (null = All, không lọc).
  void setCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    fetchProducts();
  }

  /// Tương thích ngược với code cũ dùng selectCategory.
  void selectCategory(String categoryId) {
    // 'all' là sentinel value cũ → chuyển về null
    setCategory(categoryId == 'all' ? null : categoryId);
  }

  /// Cập nhật khoảng giá (null = không lọc).
  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    fetchProducts();
  }

  /// Reset toàn bộ bộ lọc về mặc định.
  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _minPrice = null;
    _maxPrice = null;
    _debounceTimer?.cancel();
    fetchProducts();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Tải danh mục và sản phẩm lần đầu. Gọi từ initState của màn hình.
  Future<void> loadInitial() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Tải song song: categories + products + wishlist
      await Future.wait([
        _loadCategories(),
        fetchProducts(silent: true),
        fetchWishlist(silent: true),
      ]);
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch Products ────────────────────────────────────────────────────────

  /// Gọi API GET /products với toàn bộ filter hiện tại.
  /// [silent] = true để tránh set _isLoading (dùng khi loadInitial đã set rồi).
  Future<void> fetchProducts({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await _repository.fetchProducts(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        categoryId: _selectedCategoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        limit: _pageSize,
      );

      _products = result.products;
      _totalPages = result.totalPages;
      _totalItems = result.totalItems;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // ── Load More (Infinite Scroll) ───────────────────────────────────────────

  /// Tải thêm trang tiếp theo và append vào danh sách hiện tại.
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final currentPage = (_products.length / _pageSize).ceil() + 1;
      final result = await _repository.fetchProducts(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        categoryId: _selectedCategoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        page: currentPage,
        limit: _pageSize,
      );

      _products = [..._products, ...result.products];
      _totalPages = result.totalPages;
      _totalItems = result.totalItems;
    } catch (_) {
      // Load more thất bại → giữ nguyên danh sách cũ, không hiển thị lỗi
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Wishlist Toggle ───────────────────────────────────────────────────────

  Future<void> fetchWishlist({bool silent = false}) async {
    try {
      final list = await _repository.getWishlist();
      _wishlistProducts = list;
      _favoritedProductIds = list.map((p) => p.id).toSet();
      if (!silent) notifyListeners();
    } catch (_) {
      // Không crash nếu lỗi lấy wishlist
    }
  }

  Future<void> toggleWishlist(String productId) async {
    final isCurrentlyFavorited = _favoritedProductIds.contains(productId);

    // Optimistic Update
    if (isCurrentlyFavorited) {
      _favoritedProductIds.remove(productId);
      _wishlistProducts.removeWhere((p) => p.id == productId);
    } else {
      _favoritedProductIds.add(productId);
      // Cố gắng tìm product trong danh sách hiện tại để hiển thị nếu có thể
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _wishlistProducts.add(_products[index]);
      }
    }
    notifyListeners();

    try {
      if (isCurrentlyFavorited) {
        await _repository.removeFromWishlist(productId);
      } else {
        await _repository.addToWishlist(productId);
      }
    } catch (e) {
      // Rollback nếu gọi API thất bại
      if (isCurrentlyFavorited) {
        _favoritedProductIds.add(productId);
      } else {
        _favoritedProductIds.remove(productId);
        _wishlistProducts.removeWhere((p) => p.id == productId);
      }
      notifyListeners();
    }
  }

  // ── Admin Actions ─────────────────────────────────────────────────────────

  Future<void> createProduct(Map<String, dynamic> data, List<XFile>? images) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newProduct = await _repository.createProduct(data);
      if (images != null && images.isNotEmpty) {
        await _repository.uploadProductImages(newProduct.id, images);
      }
      await fetchProducts(silent: true);
    } catch (e) {
      _errorMessage = _parseError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data, List<XFile>? newImages) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateProduct(id, data);
      if (newImages != null && newImages.isNotEmpty) {
        await _repository.uploadProductImages(id, newImages);
      }
      await fetchProducts(silent: true);
    } catch (e) {
      _errorMessage = _parseError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteProduct(id);
      await fetchProducts(silent: true);
    } catch (e) {
      _errorMessage = _parseError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _loadCategories() async {
    try {
      final cats = await _repository.fetchCategories();
      // Thêm mục "All" ở đầu
      _categories = [
        const CategoryModel(id: 'all', name: 'All'),
        ...cats,
      ];
    } catch (_) {
      // Không load được categories → giữ nguyên, không crash
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('connectionTimeout') ||
        msg.contains('connectionError') ||
        msg.contains('SocketException')) {
      return 'Không thể kết nối đến server.';
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void clearWishlist() {
    _wishlistProducts.clear();
    _favoritedProductIds.clear();
    notifyListeners();
  }
}
