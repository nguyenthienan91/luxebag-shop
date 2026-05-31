import 'package:flutter/foundation.dart';
import '../models/message_model.dart';

class ChatViewModel extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isConnected = false;
  String? _errorMessage;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;

  /// Load chat history then simulate socket connection
  Future<void> loadHistory() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: replace with GET /chat/history API call
      await Future.delayed(const Duration(milliseconds: 800));
      _messages.addAll(_mockHistory());
      _isConnected = true;
      // TODO: connect Socket.io and listen for 'receive_message' event
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isSending) return;

    _isSending = true;
    notifyListeners();

    final optimistic = MessageModel(
      id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      content: content.trim(),
      sender: MessageSender.user,
      sentAt: DateTime.now(),
    );
    _messages.add(optimistic);
    notifyListeners();

    try {
      // TODO: emit Socket.io 'send_message' event with content
      await Future.delayed(const Duration(milliseconds: 400));

      // Simulate shop auto-reply after 1.5s (demo only)
      Future.delayed(const Duration(milliseconds: 1500), () {
        _receiveMessage(
          MessageModel(
            id: 'shop_${DateTime.now().millisecondsSinceEpoch}',
            content: _autoReply(content),
            sender: MessageSender.shop,
            sentAt: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      _errorMessage = 'Failed to send message';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Called when Socket emits 'receive_message'
  void _receiveMessage(MessageModel msg) {
    _messages.add(msg);
    notifyListeners();
  }

  void disconnect() {
    _isConnected = false;
    // TODO: disconnect Socket.io
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Mock Data ──────────────────────────────────────────────────────────────
  List<MessageModel> _mockHistory() {
    final now = DateTime.now();
    return [
      MessageModel(
        id: 'm1',
        content: 'Hello! Welcome to LuxeBag. How can I help you today?',
        sender: MessageSender.shop,
        sentAt: now.subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      MessageModel(
        id: 'm2',
        content:
            'Hi, I wanted to ask about the Classic Tote Bag. Is it still available?',
        sender: MessageSender.user,
        sentAt: now.subtract(const Duration(hours: 1, minutes: 55)),
        isRead: true,
      ),
      MessageModel(
        id: 'm3',
        content:
            'Yes, it\'s available! We have it in black, beige, and caramel. Would you like more details?',
        sender: MessageSender.shop,
        sentAt: now.subtract(const Duration(hours: 1, minutes: 50)),
        isRead: true,
      ),
    ];
  }

  String _autoReply(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('price') ||
        lower.contains('cost') ||
        lower.contains('bao nhiêu')) {
      return 'Our prices are listed on the product page. Feel free to check! 😊';
    }
    if (lower.contains('ship') || lower.contains('deliver')) {
      return 'We offer free shipping on orders over \$500. Standard delivery takes 3-5 business days.';
    }
    if (lower.contains('return') || lower.contains('refund')) {
      return 'We have a 30-day return policy for unused items. Please contact us with your order number.';
    }
    return 'Thank you for your message! Our team will get back to you shortly. 🛍️';
  }
}
