import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/order_model.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/order_viewmodel.dart';

class StaffOrderFulfillmentScreen extends StatefulWidget {
  const StaffOrderFulfillmentScreen({super.key});

  @override
  State<StaffOrderFulfillmentScreen> createState() => _StaffOrderFulfillmentScreenState();
}

class _StaffOrderFulfillmentScreenState extends State<StaffOrderFulfillmentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _scrollController = ScrollController();

  final List<OrderStatus> _statuses = [
    OrderStatus.pending,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _fetchOrders();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final orderVM = context.read<OrderViewModel>();
      if (orderVM.adminHasMore && !orderVM.isAdminLoadingMore) {
        orderVM.fetchAdminOrders(
          page: orderVM.adminCurrentPage + 1,
          status: _statuses[_tabController.index],
          isLoadMore: true,
        );
      }
    }
  }

  void _fetchOrders() {
    context.read<OrderViewModel>().fetchAdminOrders(
          status: _statuses[_tabController.index],
        );
  }

  void _cancelOrder(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận hủy đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn hàng #${order.id.substring(order.id.length - 8).toUpperCase()}? Thao tác này sẽ tự động hoàn trả số lượng sản phẩm vào kho hàng và không thể hoàn tác.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              context
                  .read<OrderViewModel>()
                  .updateOrderStatus(order.id, OrderStatus.cancelled)
                  .then((success) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Đã hủy đơn hàng thành công và hoàn kho')),
                  );
                  final targetIndex = _statuses.indexOf(OrderStatus.cancelled);
                  if (targetIndex != -1) {
                    if (_tabController.index == targetIndex) {
                      _fetchOrders();
                    } else {
                      _tabController.animateTo(targetIndex);
                    }
                  }
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Lỗi khi hủy đơn hàng')),
                  );
                }
              });
            },
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
  }

  void _updateStatus(
    BuildContext context,
    OrderModel order,
    OrderStatus nextStatus,
    String actionName,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    context
        .read<OrderViewModel>()
        .updateOrderStatus(order.id, nextStatus)
        .then((success) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(content: Text('Chuyển trạng thái sang "$actionName" thành công')),
        );
        final targetIndex = _statuses.indexOf(nextStatus);
        if (targetIndex != -1) {
          if (_tabController.index == targetIndex) {
            _fetchOrders();
          } else {
            _tabController.animateTo(targetIndex);
          }
        }
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Lỗi khi chuyển trạng thái sang "$actionName"')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.divider,
        surfaceTintColor: Colors.white,
        title: const Text(
          'LUXEBAG STAFF',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đang xử lý'),
            Tab(text: 'Đang giao'),
            Tab(text: 'Hoàn thành'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: Consumer<OrderViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (vm.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 56, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text(
                      vm.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    TextButton(onPressed: _fetchOrders, child: const Text('Thử lại')),
                  ],
                ),
              ),
            );
          }
          if (vm.adminOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 56, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text(
                    'Không có đơn hàng nào.',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              _fetchOrders();
            },
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
            itemCount: vm.adminOrders.length + 1,
            itemBuilder: (context, index) {
              if (index == vm.adminOrders.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: vm.isAdminLoadingMore
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : vm.adminHasMore
                          ? const SizedBox.shrink()
                          : const Center(
                              child: Text(
                                "Đã hiển thị tất cả đơn hàng",
                                style: TextStyle(fontSize: 12, color: AppColors.textHint),
                              ),
                            ),
                );
              }

              final order = vm.adminOrders[index];
              return _OrderCard(
                order: order,
                onCancel: () => _cancelOrder(context, order),
                onUpdateStatus: (nextStatus, actionName) =>
                    _updateStatus(context, order, nextStatus, actionName),
              );
            },
          ),
        );
      },
    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onCancel;
  final Function(OrderStatus, String) onUpdateStatus;

  const _OrderCard({
    required this.order,
    required this.onCancel,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (order.status) {
      case OrderStatus.pending:
        statusBgColor = Colors.orange.withOpacity(0.1);
        statusTextColor = Colors.orange;
        statusLabel = 'Chờ duyệt';
        break;
      case OrderStatus.processing:
        statusBgColor = AppColors.googleBlue.withOpacity(0.1);
        statusTextColor = AppColors.googleBlue;
        statusLabel = 'Đang xử lý';
        break;
      case OrderStatus.shipped:
        statusBgColor = Colors.purple.withOpacity(0.1);
        statusTextColor = Colors.purple;
        statusLabel = 'Đang giao';
        break;
      case OrderStatus.completed:
        statusBgColor = AppColors.success.withOpacity(0.1);
        statusTextColor = AppColors.success;
        statusLabel = 'Hoàn thành';
        break;
      case OrderStatus.cancelled:
        statusBgColor = AppColors.error.withOpacity(0.1);
        statusTextColor = AppColors.error;
        statusLabel = 'Đã hủy';
        break;
    }

    String dateStr = '';
    try {
      final localCreated = order.createdAt.toLocal();
      dateStr =
          '${localCreated.hour.toString().padLeft(2, '0')}:${localCreated.minute.toString().padLeft(2, '0')}  ${localCreated.day.toString().padLeft(2, '0')}/${localCreated.month.toString().padLeft(2, '0')}/${localCreated.year}';
    } catch (_) {
      dateStr = order.createdAt.toLocal().toString();
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider, width: 0.8),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn hàng #${order.id.substring(order.id.length - 8).toUpperCase()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ngày đặt: $dateStr',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Địa chỉ: ${order.shippingAddress}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.surface,
                          image: item.image != null && item.image!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(item.image!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: item.image == null || item.image!.isEmpty
                            ? const Icon(Icons.image_not_supported_outlined,
                                size: 20, color: AppColors.textSecondary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SKU: ${item.sku} | Số lượng: ${item.quantity}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const Text('Thanh toán: ',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.divider, width: 0.5),
                        ),
                        child: Text(
                          order.paymentMethod,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      if (order.paymentStatus != null && order.paymentStatus!.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final isPaid = order.paymentStatus!.toLowerCase() == 'paid';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isPaid
                                      ? AppColors.success.withOpacity(0.3)
                                      : AppColors.error.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isPaid
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tổng cộng: \$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
              ],
            ),
            if (order.status == OrderStatus.pending ||
                order.status == OrderStatus.processing ||
                order.status == OrderStatus.shipped) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order.status == OrderStatus.pending ||
                      order.status == OrderStatus.processing) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: onCancel,
                      child: const Text('Hủy đơn',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (order.status == OrderStatus.pending)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () => onUpdateStatus(OrderStatus.processing, 'Đang xử lý'),
                      child: const Text('Duyệt & Xử lý',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  if (order.status == OrderStatus.processing)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () => onUpdateStatus(OrderStatus.shipped, 'Đang giao'),
                      child: const Text('Giao hàng',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  if (order.status == OrderStatus.shipped)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () => onUpdateStatus(OrderStatus.completed, 'Hoàn thành'),
                      child: const Text('Hoàn thành',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
