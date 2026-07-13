import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'viewmodels/order_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'viewmodels/inventory_viewmodel.dart';

void main() async {
  // Bắt buộc gọi trước khi sử dụng SharedPreferences / bất kỳ plugin nào.
  WidgetsFlutterBinding.ensureInitialized();

  // Cho phép app vẽ full màn hình (edge-to-edge), system nav bar trong suốt
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const LuxeBagApp());
}

class LuxeBagApp extends StatelessWidget {
  const LuxeBagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProductViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => OrderViewModel()),
        ChangeNotifierProxyProvider<AuthViewModel, ChatViewModel>(
          create: (context) => ChatViewModel(
            authViewModel: context.read<AuthViewModel>(),
          ),
          update: (context, authVM, chatVM) {
            final vm = chatVM ?? ChatViewModel(authViewModel: authVM);
            if (!authVM.isLoggedIn) {
              vm.disconnect(notify: false);
            }
            return vm;
          },
        ),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => InventoryViewModel()),
      ],
      child: const _AppBootstrap(),
    );
  }
}

/// Widget trung gian để gọi tryAutoLogin() một lần duy nhất
/// sau khi Provider đã được khởi tạo xong.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  @override
  void initState() {
    super.initState();
    // Dùng addPostFrameCallback để đảm bảo context đã sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authVM = context.read<AuthViewModel>();
      await authVM.tryAutoLogin();
      if (authVM.isLoggedIn) {
        if (authVM.currentUser?.role == 'admin') {
          appRouter.go('/admin-home');
        } else if (authVM.currentUser?.role == 'staff') {
          appRouter.go('/staff-home');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LuxeBag',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
