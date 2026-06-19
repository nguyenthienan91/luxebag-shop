import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/order_viewmodel.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/register_screen.dart';
import '../views/screens/auth/forgot_password_screen.dart';
import '../views/screens/main/main_screen.dart';
import '../views/screens/admin/admin_main_screen.dart';
import '../views/screens/product/product_detail_screen.dart';
import '../views/screens/checkout/checkout_screen.dart';
import '../views/screens/order/order_history_screen.dart';
import '../views/screens/order/order_detail_screen.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../views/screens/chat/chat_screen.dart';
import '../views/screens/notification/notifications_screen.dart';
import '../views/screens/map/store_map_screen.dart';
import '../views/screens/cart/cart_screen.dart';
import '../views/screens/profile/revenue_stats_screen.dart';
import '../views/screens/admin/product_form_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/home',
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => MainScreen(key: mainScreenKey),
    ),
    GoRoute(
      path: '/admin-home',
      name: 'admin-home',
      builder: (context, state) => AdminMainScreen(key: adminMainScreenKey),
    ),
    GoRoute(
      path: '/product/:id',
      name: 'product-detail',
      builder: (context, state) =>
          ProductDetailScreen(productId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/checkout',
      name: 'checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/orders',
      name: 'orders',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
    GoRoute(
      path: '/orders/:id',
      name: 'order-detail',
      builder: (context, state) {
        if (state.extra is OrderModel) {
          return OrderDetailScreen(order: state.extra as OrderModel);
        }
        final orderId = state.pathParameters['id']!;
        return OrderDetailLoaderScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'];
        final targetUserId = state.uri.queryParameters['userId'];
        return ChatScreen(orderId: orderId, targetUserId: targetUserId);
      },
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/store-map',
      name: 'store-map',
      builder: (context, state) => const StoreMapScreen(),
    ),
    GoRoute(
      path: '/cart',
      name: 'cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/admin/revenue-stats',
      name: 'revenue-stats',
      builder: (context, state) => const RevenueStatsScreen(),
    ),
    GoRoute(
      path: '/admin/product/new',
      name: 'admin-product-new',
      builder: (context, state) => const ProductFormScreen(),
    ),
    GoRoute(
      path: '/admin/product/edit',
      name: 'admin-product-edit',
      builder: (context, state) {
        final product = state.extra as ProductModel;
        return ProductFormScreen(product: product);
      },
    ),
  ],
);

class OrderDetailLoaderScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailLoaderScreen({super.key, required this.orderId});

  @override
  State<OrderDetailLoaderScreen> createState() => _OrderDetailLoaderScreenState();
}

class _OrderDetailLoaderScreenState extends State<OrderDetailLoaderScreen> {
  OrderModel? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final vm = context.read<OrderViewModel>();
      final order = await vm.fetchOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _loading = false;
          if (order == null) {
            _error = vm.errorMessage ?? 'Failed to load order detail';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Order not found',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadOrder();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return OrderDetailScreen(order: _order!);
  }
}
