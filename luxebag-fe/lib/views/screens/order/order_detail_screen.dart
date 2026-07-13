import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/order_model.dart';
import '../../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

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
                    order.id.substring(order.id.length - 8).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                _formatDate(order.createdAt),
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
          ...order.items.map((item) => Padding(
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
                child: Text(
                  order.shippingAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
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
            value: order.paymentMethod,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Total Items',
            value: '${order.items.fold<int>(0, (sum, i) => sum + i.quantity)}',
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Total Amount',
            value: '\$${order.totalAmount.toStringAsFixed(2)}',
            isBold: true,
            valueColor: AppColors.primary,
          ),
          if (context.read<AuthViewModel>().currentUser?.role != 'admin') ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => context.push('/chat?orderId=${order.id}'),
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
