import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/message_model.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/chat_viewmodel.dart';

class ChatScreen extends StatefulWidget {
  final String? orderId;
  final String? targetUserId;

  const ChatScreen({super.key, this.orderId, this.targetUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;
  late final ChatViewModel _chatVM;

  @override
  void initState() {
    super.initState();
    _chatVM = context.read<ChatViewModel>();
    _inputController.addListener(() {
      final has = _inputController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent - _scrollController.position.pixels <= 50) {
        if (_chatVM.hasMore && !_chatVM.isLoadingMore && !_chatVM.isLoading) {
          _chatVM.loadHistory(isLoadMore: true);
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _chatVM.setTargetUser(widget.targetUserId);
      if (widget.orderId != null) {
        _chatVM.selectOrder(widget.orderId);
      }
      await _chatVM.loadHistory();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    // Only disconnect the socket, don't fully reset state
    // Full reset is handled by ChangeNotifierProxyProvider on logout
    _chatVM.disconnect();
    super.dispose();
  }

  void _scrollToBottom({bool animated = false}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(0.0);
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    setState(() => _hasText = false);
    await context.read<ChatViewModel>().sendMessage(text);
    _scrollToBottom(animated: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Consumer<ChatViewModel>(
          builder: (context, vm, _) {
            final authVM = context.read<AuthViewModel>();
            final isAdmin = authVM.currentUser?.role == 'admin';

            final isOnline = vm.isShopOnline;
            
            final String displayName;
            final String subtitle;
            final String? avatarUrl;
            final bool showOnlineDot;

            if (isAdmin) {
              displayName = vm.targetUser?.name ?? 'Customer';
              subtitle = 'Customer';
              avatarUrl = vm.targetUser?.avatarUrl;
              showOnlineDot = false;
            } else {
              final activeAdmin = vm.targetUser ?? vm.shopInfo;
              displayName = activeAdmin?.name ?? 'LuxeBag Shop';
              subtitle = isOnline ? 'Online' : 'Offline';
              avatarUrl = activeAdmin?.avatarUrl;
              showOnlineDot = isOnline;
            }

            final hasAvatar = avatarUrl != null;

            return Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        image: hasAvatar
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: hasAvatar
                          ? null
                          : Icon(
                              isAdmin
                                  ? Icons.person_outline_rounded
                                  : Icons.storefront_outlined,
                              size: 20,
                              color: Colors.white,
                            ),
                    ),
                    if (showOnlineDot)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: showOnlineDot
                              ? Colors.green
                              : AppColors.textSecondary,
                          fontWeight: showOnlineDot
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer<ChatViewModel>(
            builder: (context, vm, _) {
              final authVM = context.read<AuthViewModel>();
              final isAdmin = authVM.currentUser?.role == 'admin';
              
              if (isAdmin || vm.shopAdmins.length <= 1) {
                return const SizedBox.shrink();
              }
              
              return IconButton(
                icon: const Icon(
                  Icons.switch_account_outlined,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                tooltip: 'Select support agent',
                onPressed: () => _showAgentSelectionSheet(context, vm),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: Consumer<ChatViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // ── Connection status banner ───────────────────────────────
              if (!vm.isConnected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: AppColors.error.withOpacity(0.1),
                  child: const Text(
                    'Connecting to chat...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                ),

              // ── Load more indicator ────────────────────────────────────
              if (vm.isLoadingMore)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),

              // ── Message list ───────────────────────────────────────────
              Expanded(
                child: vm.messages.isEmpty
                    ? const _EmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: vm.messages.length,
                        itemBuilder: (context, i) {
                          final msg = vm.messages[vm.messages.length - 1 - i];
                          final prevMsg = i < vm.messages.length - 1
                              ? vm.messages[vm.messages.length - 2 - i]
                              : null;
                          final showDateHeader =
                              prevMsg == null ||
                              !_isSameDay(prevMsg.sentAt, msg.sentAt);
                          return Column(
                            children: [
                              if (showDateHeader) _DateHeader(date: msg.sentAt),
                              _MessageBubble(
                                msg: msg,
                                currentUserName:
                                    context
                                        .read<AuthViewModel>()
                                        .currentUser
                                        ?.name ??
                                    'You',
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // ── Attachment Banner ──────────────────────────────────────
              if (vm.selectedOrderId != null)
                _AttachmentBanner(
                  orderId: vm.selectedOrderId!,
                  onCancel: () => vm.selectOrder(null),
                ),

              // ── Input bar ──────────────────────────────────────────────
              _InputBar(
                controller: _inputController,
                hasText: _hasText,
                isSending: vm.isSending,
                onSend: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  void _showAgentSelectionSheet(BuildContext context, ChatViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final activeAdminId = vm.targetUserId ?? (vm.shopAdmins.isNotEmpty ? vm.shopAdmins.first.id : '');
        
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text(
                  'Chọn Hỗ Trợ Viên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: vm.shopAdmins.length,
                  itemBuilder: (context, index) {
                    final admin = vm.shopAdmins[index];
                    final isCurrent = admin.id == activeAdminId;
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        backgroundImage: admin.avatarUrl != null
                            ? NetworkImage(admin.avatarUrl!)
                            : null,
                        child: admin.avatarUrl == null
                            ? const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      title: Text(
                        admin.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        admin.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: isCurrent
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 22,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (!isCurrent) {
                          vm.switchTargetUser(admin.id);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ── Message Bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final String currentUserName;

  const _MessageBubble({required this.msg, required this.currentUserName});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (msg.orderId != null && msg.orderId!.isNotEmpty) ...[
                  _OrderCardBubble(
                    msg: msg,
                    isUser: isUser,
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(msg.sentAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 4),
                      Text(
                        msg.isRead ? '• Đã xem' : '• Đã gửi',
                        style: TextStyle(
                          fontSize: 10,
                          color: msg.isRead ? AppColors.success : AppColors.textHint,
                          fontWeight: msg.isRead ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    final h = localDt.hour.toString().padLeft(2, '0');
    final m = localDt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Date Header ───────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(date),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }

  String _label(DateTime dt) {
    final localDt = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(localDt.year, localDt.month, localDt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[localDt.month - 1]} ${localDt.day}, ${localDt.year}';
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.hasText,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            child: isSending
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : Material(
                    color: hasText ? AppColors.primary : AppColors.inputBorder,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: hasText ? onSend : null,
                      customBorder: const CircleBorder(),
                      child: const Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Chat ────────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 14),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Send a message to start chatting\nwith the shop.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Attachment Banner ─────────────────────────────────────────────────────────

class _AttachmentBanner extends StatelessWidget {
  final String orderId;
  final VoidCallback onCancel;

  const _AttachmentBanner({
    required this.orderId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final displayId = orderId.length > 8
        ? orderId.substring(orderId.length - 8).toUpperCase()
        : orderId.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
        gradient: LinearGradient(
          colors: [
            Color(0xFFFAF6EE),
            Color(0xFFF5EFEB),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ĐANG ĐÍNH KÈM ĐƠN HÀNG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#$displayId',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.cancel_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Order Card Bubble ──────────────────────────────────────────────────────────

class _OrderCardBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isUser;

  const _OrderCardBubble({required this.msg, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final orderId = msg.orderId ?? '';
    final displayId = msg.orderCodeSnapshot ?? 
        (orderId.length > 8
            ? orderId.substring(orderId.length - 8).toUpperCase()
            : orderId.toUpperCase());

    final cardBg = isUser ? const Color(0xFFF9F6F0) : Colors.white;
    final cardBorder = isUser ? const Color(0xFFEADBCE) : AppColors.divider;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIÊN KẾT ĐƠN HÀNG',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '#$displayId',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/orders/$orderId'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Xem đơn hàng',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 9,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
