class CategoryModel {
  final String id;
  final String name;
  final String? icon;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }
}
