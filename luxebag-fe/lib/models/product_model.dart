class ShippingOptions {
  final bool freeShipping;
  final bool nextDayShipping;

  const ShippingOptions({
    this.freeShipping = true,
    this.nextDayShipping = false,
  });

  factory ShippingOptions.fromJson(Map<String, dynamic> json) {
    return ShippingOptions(
      freeShipping: json['freeShipping'] as bool? ?? true,
      nextDayShipping: json['nextDayShipping'] as bool? ?? false,
    );
  }
}

class ProductModel {
  final String id;
  final String title;
  final String modelNumber;
  final String? upcCode;
  final String sku;
  final String description;
  final List<String> images;

  // Pricing
  final double retailPrice;
  final double currentPrice;
  final double discountPercentage;
  final String? saleEventName;

  // Attributes
  final String brand;
  final String gender;
  final String material;
  final String? sizeInfo;
  final String sizeCategory;

  // Classification
  final String department;
  final String categoryId;
  final String ownerId;

  // Status & Logistics
  final String stockStatus;
  final String condition;
  final ShippingOptions shippingOptions;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Local state
  bool isWishlisted;

  ProductModel({
    required this.id,
    required this.title,
    required this.modelNumber,
    this.upcCode,
    required this.sku,
    required this.description,
    required this.images,
    required this.retailPrice,
    required this.currentPrice,
    this.discountPercentage = 0,
    this.saleEventName,
    required this.brand,
    this.gender = 'Unisex',
    required this.material,
    this.sizeInfo,
    this.sizeCategory = 'Medium',
    required this.department,
    required this.categoryId,
    required this.ownerId,
    this.stockStatus = 'IN STOCK',
    this.condition = 'New',
    this.shippingOptions = const ShippingOptions(),
    this.createdAt,
    this.updatedAt,
    this.isWishlisted = false,
  });

  String get thumbnailUrl => images.isNotEmpty ? images.first : '';

  bool get isOnSale => discountPercentage > 0;

  bool get inStock => stockStatus == 'IN STOCK';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] as String,
      title: json['title'] as String,
      modelNumber: json['modelNumber'] as String,
      upcCode: json['upcCode'] as String?,
      sku: json['sku'] as String,
      description: json['description'] as String,
      images: List<String>.from(json['images'] as List),
      retailPrice: (json['retailPrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      saleEventName: json['saleEventName'] as String?,
      brand: json['brand'] as String,
      gender: json['gender'] as String? ?? 'Unisex',
      material: json['material'] as String,
      sizeInfo: json['sizeInfo'] as String?,
      sizeCategory: json['sizeCategory'] as String? ?? 'Medium',
      department: json['department'] as String,
      categoryId: json['categoryId'] is Map
          ? json['categoryId']['_id'] as String
          : json['categoryId'] as String,
      ownerId: json['ownerId'] is Map
          ? json['ownerId']['_id'] as String
          : json['ownerId'] as String,
      stockStatus: json['stockStatus'] as String? ?? 'IN STOCK',
      condition: json['condition'] as String? ?? 'New',
      shippingOptions: json['shippingOptions'] != null
          ? ShippingOptions.fromJson(
              json['shippingOptions'] as Map<String, dynamic>)
          : const ShippingOptions(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
