import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

// Mock categories — replace with API call later
final _mockCategories = [
  const CategoryModel(id: 'all', name: 'All'),
  const CategoryModel(id: '1', name: 'Wallets'),
  const CategoryModel(id: '2', name: 'Tote Bags'),
  const CategoryModel(id: '3', name: 'Shoulder Bags'),
  const CategoryModel(id: '4', name: 'Clutches'),
  const CategoryModel(id: '5', name: 'Backpacks'),
  const CategoryModel(id: '6', name: 'Cross-body'),
];

// Mock products — replace with API call later
final _mockProducts = List.generate(12, (i) {
  final brands = [
    'Montblanc',
    'Gucci',
    'Louis Vuitton',
    'Prada',
    'Chanel',
    'Dior',
  ];
  final categories = ['1', '2', '3', '4', '5', '6'];
  return ProductModel(
    id: 'p$i',
    title: '${brands[i % brands.length]} Luxury Bag ${i + 1}',
    modelNumber: '${220400 + i}',
    sku: 'SKU${1000 + i}',
    description:
        'A premium luxury bag crafted from the finest materials. '
        'Perfect for both casual and formal occasions. '
        'Features multiple compartments and a timeless design.',
    images: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800',
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800',
      'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800',
    ],
    retailPrice: 500.0 + i * 50,
    currentPrice: 299.0 + i * 30,
    discountPercentage: (i % 3 == 0)
        ? 40
        : (i % 2 == 0)
        ? 25
        : 0,
    saleEventName: i % 3 == 0 ? 'Summer Sale' : null,
    brand: brands[i % brands.length],
    material: 'Leather',
    sizeInfo: '30 cm x 10 cm x 20 cm',
    sizeCategory: ['Mini', 'Small', 'Medium', 'Large'][i % 4],
    department: 'Bags',
    categoryId: categories[i % categories.length],
    ownerId: 'owner1',
    shippingOptions: ShippingOptions(
      freeShipping: i % 2 == 0,
      nextDayShipping: i % 4 == 0,
    ),
    isWishlisted: i % 5 == 0,
  );
});

class ProductViewModel extends ChangeNotifier {
  // ── Data ──────────────────────────────────────────────────────────────────
  List<ProductModel> _allProducts = [];
  List<ProductModel> _displayedProducts = [];
  List<CategoryModel> _categories = [];

  // ── Filter / Search state ─────────────────────────────────────────────────
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int _pageSize = 6;
  int _currentPage = 1;
  bool _hasMore = true;

  // ── Loading ───────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<ProductModel> get products => _displayedProducts;
  List<CategoryModel> get categories => _categories;
  String get searchQuery => _searchQuery;
  String get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  List<ProductModel> get wishlistedProducts =>
      _allProducts.where((p) => p.isWishlisted).toList();

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> loadInitial() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: Replace with actual API calls
    _categories = _mockCategories;
    _allProducts = _mockProducts;
    _currentPage = 1;
    _hasMore = true;
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  // ── Search ────────────────────────────────────────────────────────────────
  void onSearchChanged(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _hasMore = true;
    _applyFilters();
    notifyListeners();
  }

  // ── Category filter ───────────────────────────────────────────────────────
  void selectCategory(String categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _currentPage = 1;
    _hasMore = true;
    _applyFilters();
    notifyListeners();
  }

  // ── Load more (infinite scroll) ───────────────────────────────────────────
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _currentPage++;
    _applyFilters(append: true);

    _isLoadingMore = false;
    notifyListeners();
  }

  // ── Wishlist toggle ───────────────────────────────────────────────────────
  void toggleWishlist(String productId) {
    final index = _allProducts.indexWhere((p) => p.id == productId);
    if (index == -1) return;
    _allProducts[index].isWishlisted = !_allProducts[index].isWishlisted;

    final displayIndex = _displayedProducts.indexWhere(
      (p) => p.id == productId,
    );
    if (displayIndex != -1) {
      _displayedProducts[displayIndex].isWishlisted =
          _allProducts[index].isWishlisted;
    }
    // TODO: Call API toggle wishlist
    notifyListeners();
  }

  // ── Internal ──────────────────────────────────────────────────────────────
  void _applyFilters({bool append = false}) {
    var filtered = _allProducts.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.brand.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategoryId == 'all' || p.categoryId == _selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();

    final end = (_currentPage * _pageSize).clamp(0, filtered.length);
    _hasMore = end < filtered.length;

    if (append) {
      final start = ((_currentPage - 1) * _pageSize).clamp(0, filtered.length);
      _displayedProducts.addAll(filtered.sublist(start, end));
    } else {
      _displayedProducts = filtered.sublist(0, end);
    }
  }
}
