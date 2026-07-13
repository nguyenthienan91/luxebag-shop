import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/chat_viewmodel.dart';

class StaffChatListScreen extends StatefulWidget {
  const StaffChatListScreen({super.key});

  @override
  State<StaffChatListScreen> createState() => _StaffChatListScreenState();
}

class _StaffChatListScreenState extends State<StaffChatListScreen>
    with WidgetsBindingObserver, RouteAware {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().loadConversations();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh conversations when app returns to foreground
      context.read<ChatViewModel>().loadConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Customer Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: Consumer<ChatViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: vm.loadConversations,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Customer queries will appear here.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vm.loadConversations,
            color: AppColors.primary,
            child: ListView.separated(
              itemCount: vm.conversations.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final conv = vm.conversations[index];
                final otherUser = conv['otherUser'] != null
                    ? Map<String, dynamic>.from(conv['otherUser'] as Map)
                    : <String, dynamic>{};
                final displayName = otherUser['displayName'] as String? ?? 'Customer';
                final avatar = otherUser['avatar'] as String?;
                final lastMsg = conv['lastMessageText'] as String? ?? '';
                final lastTimeRaw = conv['lastMessageTime'] as String?;
                final unreadCount = conv['unreadCount'] as int? ?? 0;

                final lastTime = lastTimeRaw != null
                    ? DateTime.parse(lastTimeRaw).toLocal()
                    : DateTime.now();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onTap: () async {
                    // Immediately mark as read locally for instant UI feedback
                    vm.markConversationRead(index);
                    await context.push('/chat?userId=${otherUser['id']}');
                    // Refresh from server when returning
                    vm.loadConversations();
                  },
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.inputBorder, width: 0.5),
                      image: avatar != null
                          ? DecorationImage(
                              image: NetworkImage(avatar),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatar == null
                        ? const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.textSecondary,
                            size: 24,
                          )
                        : null,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(lastTime),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: unreadCount > 0
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: unreadCount > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return '${time.day}/${time.month}';
  }
}
