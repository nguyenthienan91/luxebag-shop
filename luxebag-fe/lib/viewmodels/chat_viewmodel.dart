import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../repositories/chat_repository.dart';
import '../services/token_service.dart';
import 'auth_viewmodel.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;
  final TokenService _tokenService;
  final AuthViewModel _authViewModel;

  IO.Socket? _socket;
  final List<UserModel> _shopAdmins = [];
  final List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSending = false;
  bool _isConnected = false;
  bool _isShopOnline = false;
  String? _errorMessage;
  String? _selectedOrderId;
  String? _targetUserId;
  UserModel? _targetUser;
  List<Map<String, dynamic>> _conversations = [];

  int _currentPage = 1;
  bool _hasMore = true;
  static const int _limit = 20;

  ChatViewModel({
    ChatRepository? repository,
    TokenService? tokenService,
    required AuthViewModel authViewModel,
  })  : _repository = repository ?? ChatRepository(),
        _tokenService = tokenService ?? TokenService(),
        _authViewModel = authViewModel;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSending => _isSending;
  bool get isConnected => _isConnected;
  bool get isShopOnline => _isShopOnline;
  String? get errorMessage => _errorMessage;
  UserModel? get shopInfo => _shopAdmins.isNotEmpty ? _shopAdmins.first : null;
  List<UserModel> get shopAdmins => List.unmodifiable(_shopAdmins);
  bool get hasMore => _hasMore;
  String? get selectedOrderId => _selectedOrderId;
  String? get targetUserId => _targetUserId;
  UserModel? get targetUser => _targetUser;
  List<Map<String, dynamic>> get conversations => _conversations;
  int get totalUnreadMessages => _conversations.fold<int>(
        0,
        (sum, conv) => sum + (conv['unreadCount'] as int? ?? 0),
      );

  void selectOrder(String? orderId) {
    _selectedOrderId = orderId;
    notifyListeners();
  }

  Future<void> setTargetUser(String? userId) async {
    _targetUserId = userId;
    if (userId == null) {
      _targetUser = null;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // 1. If shop admins list is empty, fetch it first to populate
      final isCurrentUserAdmin = _authViewModel.currentUser?.role == 'admin';
      if (!isCurrentUserAdmin && _shopAdmins.isEmpty) {
        final admins = await _repository.fetchShopAdmins();
        _shopAdmins.addAll(admins);
      }

      // 2. Try to find the user in _shopAdmins
      UserModel? foundUser;
      for (final admin in _shopAdmins) {
        if (admin.id == userId) {
          foundUser = admin;
          break;
        }
      }

      if (foundUser != null) {
        _targetUser = foundUser;
      } else {
        // Fallback: fetch details (works for Admin loading Customer profile)
        _targetUser = await _repository.fetchUserById(userId);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchTargetUser(String userId) async {
    print('[ChatVM] switchTargetUser($userId)');
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _messages.clear();
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    await setTargetUser(userId);
    await loadHistory();
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _conversations = await _repository.fetchConversations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Immediately mark a conversation as read in local state (for instant UI feedback).
  void markConversationRead(int index) {
    if (index >= 0 && index < _conversations.length) {
      _conversations[index] = Map<String, dynamic>.from(_conversations[index])
        ..['unreadCount'] = 0;
      notifyListeners();
    }
  }

  /// Load chat history and connect Socket.
  /// Set isLoadMore = true to fetch older history.
  Future<void> loadHistory({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
      notifyListeners();
    } else {
      if (_isLoading) return;
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
      notifyListeners();
    }

    try {
      final currentUserId = _authViewModel.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User is not logged in');
      }

      // 1. Resolve active target ID (Customer ID for Admin, or Admin ID for Customer)
      String activeTargetId = '';
      if (_targetUserId != null) {
        activeTargetId = _targetUserId!;
      } else {
        if (_shopAdmins.isEmpty) {
          final admins = await _repository.fetchShopAdmins();
          _shopAdmins.addAll(admins);
        }
        if (_shopAdmins.isEmpty) {
          throw Exception('No shop administrators available.');
        }
        activeTargetId = _shopAdmins.first.id;
      }

      // 2. Fetch history
      final pageToLoad = isLoadMore ? _currentPage + 1 : 1;
      final history = await _repository.fetchMessages(
        activeTargetId,
        currentUserId,
        page: pageToLoad,
        limit: _limit,
      );

      if (isLoadMore) {
        _messages.insertAll(0, history);
        _currentPage = pageToLoad;
      } else {
        _messages.clear();
        _messages.addAll(history);
      }

      if (history.length < _limit) {
        _hasMore = false;
      }

      // 3. Mark messages as read via REST API (ensures read state is persisted)
      if (!isLoadMore) {
        try {
          await _repository.markAsRead(activeTargetId);
        } catch (_) {
          // Non-critical: socket chat:join will also mark as read
        }
        _connectSocket(currentUserId, activeTargetId);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (isLoadMore) {
        _isLoadingMore = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void _connectSocket(String currentUserId, String shopId) async {
    // ALWAYS destroy old socket to avoid reusing stale auth tokens
    if (_socket != null) {
      print('[ChatVM] Destroying old socket before creating new one');
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    final token = await _tokenService.getAccessToken();
    if (token == null || token.isEmpty) {
      print('[ChatVM] No token available, cannot connect socket');
      return;
    }

    print('[ChatVM] Connecting socket. User=$currentUserId, Target=$shopId, Token=${token.substring(0, 10)}...');

    // Connect to Socket.IO backend with JWT Authentication handshake
    _socket = IO.io('https://luxebag-backend.onrender.com', IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': 'Bearer $token'})
      .disableAutoConnect()
      .enableForceNew()
      .build());

    _socket!.onConnect((_) {
      _isConnected = true;
      notifyListeners();

      // Join room
      _socket!.emit('chat:join', {'targetId': shopId});
      print('[ChatVM] Socket connected. Joined room with target: $shopId');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
      print('[ChatVM] Socket disconnected');
    });

    _socket!.onConnectError((data) {
      print('[ChatVM] Socket connect error: $data');
    });

    // Namespace event for receiving message
    _socket!.on('chat:receive', (data) {
      if (data is Map<String, dynamic> || data is Map) {
        final json = Map<String, dynamic>.from(data);
        final senderId = json['senderId'] as String;
        final isUser = (senderId == currentUserId);

        final newMsg = MessageModel(
          id: (json['id'] ?? json['_id'] ?? '') as String,
          content: (json['content'] ?? json['messageText'] ?? '') as String,
          sender: isUser ? MessageSender.user : MessageSender.shop,
          sentAt: DateTime.parse(json['sentAt'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
          isRead: json['isRead'] as bool? ?? false,
          orderId: json['orderId'] as String?,
          orderCodeSnapshot: json['orderCodeSnapshot'] as String?,
        );

        final idx = _messages.indexWhere((m) => m.id == newMsg.id || (m.id.startsWith('tmp_') && m.content == newMsg.content));
        if (idx != -1) {
          _messages[idx] = newMsg;
        } else {
          _messages.add(newMsg);
        }
        notifyListeners();
      }
    });

    // Handle read receipt events
    _socket!.on('chat:read', (data) {
      if (data is Map<String, dynamic> || data is Map) {
        final json = Map<String, dynamic>.from(data);
        final readerId = json['readerId'] as String;
        if (readerId != currentUserId) {
          // Mark all user-sent messages as read
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].sender == MessageSender.user && !_messages[i].isRead) {
              _messages[i] = _messages[i].copyWith(isRead: true);
            }
          }
          notifyListeners();
        }
      }
    });

    // Listen to online status updates
    _socket!.on('chat:user_online', (data) {
      if (data != null && data['userId'] == shopId) {
        _isShopOnline = true;
        notifyListeners();
      }
    });

    _socket!.on('chat:user_offline', (data) {
      if (data != null && data['userId'] == shopId) {
        _isShopOnline = false;
        notifyListeners();
      }
    });

    _socket!.connect();
  }

  /// Send message
  Future<void> sendMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final currentUserId = _authViewModel.currentUser?.id;
    if (currentUserId == null || (shopInfo == null && _targetUserId == null)) return;

    _isSending = true;
    notifyListeners();

    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = MessageModel(
      id: tempId,
      content: text,
      sender: MessageSender.user,
      sentAt: DateTime.now(),
      orderId: _selectedOrderId,
    );
    _messages.add(optimisticMsg);

    final orderIdToSend = _selectedOrderId;
    _selectedOrderId = null;
    notifyListeners();

    final receiverId = _targetUserId ?? shopInfo!.id;

    try {
      if (_socket != null && _socket!.connected) {
        final payload = {
          'receiverId': receiverId,
          'messageText': text,
          if (orderIdToSend != null) 'orderId': orderIdToSend,
        };
        _socket!.emit('chat:send', payload);
      } else {
        throw Exception('Socket is not connected');
      }
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
      _messages.removeWhere((m) => m.id == tempId);
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void disconnect({bool notify = true}) {
    print('[ChatVM] disconnect() called. notify=$notify');
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _isShopOnline = false;
    _messages.clear();
    _shopAdmins.clear();
    _conversations.clear();
    _selectedOrderId = null;
    _targetUserId = null;
    _targetUser = null;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    if (notify) notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
