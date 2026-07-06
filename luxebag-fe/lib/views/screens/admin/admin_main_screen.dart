import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/chat_viewmodel.dart';
import 'product_management_screen.dart';
import 'inventory_management_screen.dart';
import 'order_fulfillment_screen.dart';
import '../profile/profile_screen.dart';
import 'admin_chat_list_screen.dart';

final GlobalKey<_AdminMainScreenState> adminMainScreenKey = GlobalKey<_AdminMainScreenState>();

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().loadConversations();
    });
  }

  void switchTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ProductManagementScreen(),
          InventoryManagementScreen(),
          OrderFulfillmentScreen(),
          AdminChatListScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Consumer<ChatViewModel>(
              builder: (context, chatVM, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AdminNavItem(
                      icon: Icons.inventory_2_outlined,
                      activeIcon: Icons.inventory_2_rounded,
                      label: 'Products',
                      index: 0,
                      currentIndex: _currentIndex,
                      onTap: switchTab,
                    ),
                    _AdminNavItem(
                      icon: Icons.warehouse_outlined,
                      activeIcon: Icons.warehouse_rounded,
                      label: 'Inventory',
                      index: 1,
                      currentIndex: _currentIndex,
                      onTap: switchTab,
                    ),
                    _AdminNavItem(
                      icon: Icons.local_shipping_outlined,
                      activeIcon: Icons.local_shipping_rounded,
                      label: 'Orders',
                      index: 2,
                      currentIndex: _currentIndex,
                      onTap: switchTab,
                    ),
                    _AdminNavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Messages',
                      index: 3,
                      currentIndex: _currentIndex,
                      onTap: switchTab,
                      badgeCount: chatVM.totalUnreadMessages,
                    ),
                    _AdminNavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      index: 4,
                      currentIndex: _currentIndex,
                      onTap: switchTab,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;
  final int badgeCount;

  const _AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(fontSize: 9),
              ),
              backgroundColor: Colors.red,
              textColor: Colors.white,
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.white : Colors.white54,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
