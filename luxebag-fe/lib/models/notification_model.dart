enum NotificationType { order, promotion, system }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceType;
  final String? referenceId; // orderId, productId, etc.

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceType,
    this.referenceId,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    title: title,
    body: body,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    referenceType: referenceType,
    referenceId: referenceId,
  );

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      type: _typeFromString(json['type'] as String? ?? 'system'),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
    );
  }

  static NotificationType _typeFromString(String v) {
    switch (v) {
      case 'order':
        return NotificationType.order;
      case 'promotion':
        return NotificationType.promotion;
      default:
        return NotificationType.system;
    }
  }
}
