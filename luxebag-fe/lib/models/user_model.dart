class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final String? address;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.role = 'customer',
    this.isActive = true,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id']) as String,
      name: (json['displayName'] ?? json['name'] ?? '') as String,
      email: json['email'] as String,
      phone: json['phoneNumber'] as String?,
      avatarUrl: json['avatar'] as String?,
      role: json['role'] as String? ?? 'customer',
      isActive: json['isActive'] as bool? ?? true,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    if (phone != null) 'phone': phone,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'role': role,
    'isActive': isActive,
    if (address != null) 'address': address,
  };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? role,
    bool? isActive,
    String? address,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
    );
  }
}
