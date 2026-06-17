import 'package:go_router/go_router.dart';
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
import '../views/screens/chat/chat_screen.dart';
import '../views/screens/notification/notifications_screen.dart';
import '../views/screens/map/store_map_screen.dart';
import '../views/screens/cart/cart_screen.dart';

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
        final order = state.extra as OrderModel;
        return OrderDetailScreen(order: order);
      },
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const ChatScreen(),
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
  ],
);
