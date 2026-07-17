import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/order_model.dart';
import '../../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/order_viewmodel.dart';
import '../checkout/vnpay_webview_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _order;
  bool _isCancelling = false;
  bool _isOpeningPayment = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startCountdown() {}

  Future<void> _reloadOrder() async {
    final vm = context.read<OrderViewModel>();
    final updated = await vm.fetchOrderById(_order.id);
    if (updated != null && mounted) {
      setState(() {
        _order = updated;
      });
    }
  }

  /// Luôn tạo link thanh toán mới rồi mở WebView
  Future<void> _openPayment() async {
    setState(() => _isOpeningPayment = true);
    final vm = context.read<OrderViewModel>();
    final updated = await vm.recreatePaymentUrl(_order.id);
    if (!mounted) return;
    setState(() => _isOpeningPayment = false);

    if (updated == null || updated.paymentUrl == null || updated.paymentUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Không thể tạo liên kết thanh toán'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _order = updated);

    final webViewResult = await Navigator.push<Map<String, String?>?>(
      context,
      MaterialPageRoute(
        builder: (context) => VNPayWebViewScreen(paymentUrl: updated.paymentUrl!),
      ),
    );

    if (!mounted) return;

    if (webViewResult != null && webViewResult['vnp_ResponseCode'] == '00') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán thành công!'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán bị hủy hoặc thất bại.'), backgroundColor: AppColors.error),
      );
    }
    _reloadOrder();
  }

  void _cancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận hủy đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đơn hàng này? Thao tác này không thể hoàn tác.',
          style: TextStyle(color: AppColors.textSecondary),
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
              _performCancel();
            },
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancel() async {
    setState(() => _isCancelling = true);
    final vm = context.read<OrderViewModel>();
    final success = await vm.cancelMyOrder(_order.id);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn hàng đã được hủy thành công')),
      );
      setState(() {
        _order = OrderModel(
          id: _order.id,
          userId: _order.userId,
          items: _order.items,
          totalAmount: _order.totalAmount,
          status: OrderStatus.cancelled,
          paymentMethod: _order.paymentMethod,
          paymentStatus: _order.paymentStatus,
          shippingAddress: _order.shippingAddress,
          province: _order.province,
          shippingFee: _order.shippingFee,
          createdAt: _order.createdAt,
          updatedAt: DateTime.now(),
          paymentUrl: null,
          paymentUrlCreatedAt: null,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Hủy đơn hàng thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home?tab=3');
            }
          },
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Order Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order ID',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _order.id.substring(_order.id.length - 8).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              _StatusBadge(status: _order.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                _formatDate(_order.createdAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 28),

          // Items List
          const Text(
            'Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.image ?? '',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 70,
                          height: 70,
                          color: AppColors.surface,
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 70,
                          height: 70,
                          color: AppColors.surface,
                          child: const Icon(Icons.image_not_supported_outlined,
                              color: AppColors.textHint),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'SKU: ${item.sku}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${item.priceAtPurchase.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'x${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 28),

          // Shipping Info
          const Text(
            'Shipping Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _order.shippingAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    if (_order.province.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _order.province,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 28),

          // Payment Summary
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Payment Method',
            value: _order.paymentMethod,
          ),
          if (_order.paymentStatus != null && _order.paymentStatus!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Payment Status',
              value: _order.paymentStatus!.toLowerCase() == 'paid' ? 'Paid' : 'Unpaid',
              valueColor: _order.paymentStatus!.toLowerCase() == 'paid'
                  ? AppColors.success
                  : AppColors.error,
            ),
          ],
          _SummaryRow(
            label: 'Total Items',
            value: '${_order.items.fold<int>(0, (sum, i) => sum + i.quantity)}',
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Shipping Fee',
            value: _order.shippingFee == 0
                ? 'FREE'
                : '\$${_order.shippingFee.toStringAsFixed(2)}',
            valueColor: _order.shippingFee == 0
                ? AppColors.success
                : AppColors.textPrimary,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Total Amount',
            value: '\$${_order.totalAmount.toStringAsFixed(2)}',
            isBold: true,
            valueColor: AppColors.primary,
          ),

          // VNPay Payment Button
          if (_order.paymentMethod == 'VNPAY' &&
              (_order.paymentStatus == null || _order.paymentStatus!.toLowerCase() != 'paid') &&
              _order.status == OrderStatus.pending) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isOpeningPayment ? null : _openPayment,
                icon: _isOpeningPayment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payment, size: 18),
                label: Text(_isOpeningPayment ? 'Đang tạo liên kết...' : 'Thanh toán VNPay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
          ],

          if (context.read<AuthViewModel>().currentUser?.role != 'admin') ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => context.push('/chat?orderId=${_order.id}'),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Trao đổi về đơn hàng này'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (_order.status == OrderStatus.pending) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isCancelling ? null : () => _cancelOrder(context),
                icon: _isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(Icons.cancel_outlined, color: AppColors.error),
                label: Text(
                  _isCancelling ? 'Đang hủy...' : 'Hủy đơn hàng',
                  style: const TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final localDt = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    
    final hour = localDt.hour == 0 ? 12 : (localDt.hour > 12 ? localDt.hour - 12 : localDt.hour);
    final amPm = localDt.hour >= 12 ? 'PM' : 'AM';
    final minute = localDt.minute.toString().padLeft(2, '0');
    
    return '${months[localDt.month - 1]} ${localDt.day}, ${localDt.year} - $hour:$minute $amPm';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  (Color bg, Color fg) _colors(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return (const Color(0xFFFFF3CD), const Color(0xFF856404));
      case OrderStatus.processing:
        return (const Color(0xFFCCE5FF), const Color(0xFF004085));
      case OrderStatus.shipped:
        return (const Color(0xFFD1ECF1), const Color(0xFF0C5460));
      case OrderStatus.completed:
        return (const Color(0xFFD4EDDA), AppColors.success);
      case OrderStatus.cancelled:
        return (const Color(0xFFF8D7DA), AppColors.error);
    }
  }
}
