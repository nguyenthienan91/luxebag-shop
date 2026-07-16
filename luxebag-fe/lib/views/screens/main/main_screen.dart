import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../home/home_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../cart/cart_screen.dart';
import '../order/order_history_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int? initialTab;
  const MainScreen({super.key, this.initialTab});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartViewModel>().fetchCart();
    });
  }

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTab = widget.initialTab ?? 0;
    final oldTab = oldWidget.initialTab ?? 0;
    if (newTab != oldTab) {
      setState(() {
        _currentIndex = newTab;
      });
    }
  }

  void switchTab(int index) {
    if (index == _currentIndex) return;
    if (mounted) {
      context.goNamed('home', queryParameters: {'tab': '$index'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          WishlistScreen(),
          CartScreen(),
          OrderHistoryScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Consumer<CartViewModel>(
        builder: (context, cart, _) {
          final isSelected = _currentIndex == 2;
          return Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => switchTab(2),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    if (cart.totalCartItems > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            cart.totalCartItems > 9 ? '9+' : '${cart.totalCartItems}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.zero,
        child: Container(
          // 68px cho nav items + padding bằng chiều cao system nav bar
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                // Left: Home + Wishlist
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Home',
                        index: 0,
                        currentIndex: _currentIndex,
                        onTap: (i) => switchTab(i),
                      ),
                      _NavItem(
                        icon: Icons.favorite_border_rounded,
                        activeIcon: Icons.favorite_rounded,
                        label: 'Wishlist',
                        index: 1,
                        currentIndex: _currentIndex,
                        onTap: (i) => switchTab(i),
                      ),
                    ],
                  ),
                ),
                // Center gap for FAB
                const SizedBox(width: 72),
                // Right: Orders + Profile
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        label: 'Orders',
                        index: 3,
                        currentIndex: _currentIndex,
                        onTap: (i) => switchTab(i),
                      ),
                      _NavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profile',
                        index: 4,
                        currentIndex: _currentIndex,
                        onTap: (i) => switchTab(i),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 26,
                color: isActive ? Colors.white : Colors.white54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
