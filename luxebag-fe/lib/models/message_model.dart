enum MessageSender { user, shop }

class MessageModel {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime sentAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.content,
    required this.sender,
    required this.sentAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      sender: (json['sender'] as String) == 'shop'
          ? MessageSender.shop
          : MessageSender.user,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content,
    'sender': sender == MessageSender.shop ? 'shop' : 'user',
  };
}
