class InventoryLogModel {
  final int change;
  final String reason;
  final DateTime createdAt;

  InventoryLogModel({
    required this.change,
    required this.reason,
    required this.createdAt,
  });

  factory InventoryLogModel.fromJson(Map<String, dynamic> json) {
    return InventoryLogModel(
      change: json['change'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class InventoryModel {
  final String productId;
  final int stock;
  final List<InventoryLogModel> logs;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InventoryModel({
    required this.productId,
    required this.stock,
    required this.logs,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      productId: json['productId'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      logs: json['logs'] != null
          ? (json['logs'] as List<dynamic>)
              .map((e) => InventoryLogModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
