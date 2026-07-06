enum MessageSender { user, shop }

class MessageModel {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime sentAt;
  final bool isRead;
  final String? orderId;
  final String? orderCodeSnapshot;

  const MessageModel({
    required this.id,
    required this.content,
    required this.sender,
    required this.sentAt,
    this.isRead = false,
    this.orderId,
    this.orderCodeSnapshot,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      content: (json['content'] ?? json['messageText'] ?? '') as String,
      sender: (json['sender'] as String? ?? '') == 'shop' ||
              (json['senderId'] as String? ?? '') != (json['receiverId'] as String? ?? '') && 
              json['sender'] == 'shop'
          ? MessageSender.shop
          : MessageSender.user,
      sentAt: DateTime.parse(json['sentAt'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] as bool? ?? false,
      orderId: json['orderId'] as String?,
      orderCodeSnapshot: json['orderCodeSnapshot'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content,
    'sender': sender == MessageSender.shop ? 'shop' : 'user',
    if (orderId != null) 'orderId': orderId,
    if (orderCodeSnapshot != null) 'orderCodeSnapshot': orderCodeSnapshot,
  };

  MessageModel copyWith({
    String? id,
    String? content,
    MessageSender? sender,
    DateTime? sentAt,
    bool? isRead,
    String? orderId,
    String? orderCodeSnapshot,
  }) {
    return MessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
      orderCodeSnapshot: orderCodeSnapshot ?? this.orderCodeSnapshot,
    );
  }
}
