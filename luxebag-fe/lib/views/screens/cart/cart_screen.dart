import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/cart_item_model.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../../../viewmodels/inventory_viewmodel.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartVM = context.read<CartViewModel>();
      if (cartVM.items.isNotEmpty) {
        final products = cartVM.items.map((i) => i.product).toList();
        context.read<InventoryViewModel>().fetchInventoryForProducts(products);
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
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          TextButton(
            onPressed: () => _confirmClearAll(context, context.read<CartViewModel>()),
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: Consumer<CartViewModel>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return const _EmptyCart();
          return Column(
            children: [
              CheckboxListTile(
                value: cart.isAllSelected,
                onChanged: (val) {
                  if (val == true) {
                    cart.selectAll();
                  } else {
                    cart.deselectAll();
                  }
                },
                title: const Text('Select All', style: TextStyle(fontWeight: FontWeight.w600)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await context.read<CartViewModel>().fetchCart();
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, i) =>
                        _CartItemTile(item: cart.items[i]),
                  ),
                ),
              ),
              _OrderSummary(cart: cart),
              _CheckoutBar(cart: cart),
            ],
          );
        },
      ),
    );
  }

  void _confirmClearAll(BuildContext context, CartViewModel cart) {
    if (cart.isEmpty) return;
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Clear Cart',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to remove all items from your bag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cart.clearAllCart();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Looks like you haven\'t added\nanything yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.goNamed('home', queryParameters: {'tab': '0'});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Start Shopping',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart Item Tile ─────────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  final CartItemModel item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartViewModel>();

    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cart.removeItem(item.productId),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.red.shade400,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: cart.selectedItems.contains(item.productId),
                onChanged: (_) => cart.toggleItemSelection(item.productId),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.thumbnailUrl,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 88, height: 88, color: AppColors.surface),
              errorWidget: (_, __, ___) => Container(
                width: 88,
                height: 88,
                color: AppColors.surface,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info + Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand
                Text(
                  item.brand.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),

                // Title
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Price row
                Row(
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.originalPrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '\$${item.originalPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Quantity + Delete row
                Row(
                  children: [
                    // [-] qty [+]
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QtyButton(
                            icon: Icons.remove,
                            onTap: () => cart.updateQuantity(
                              item.productId,
                              item.quantity - 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _QtyButton(
                            icon: Icons.add,
                            onTap: () {
                              final invVM = context.read<InventoryViewModel>();
                              final stock = invVM.getInventoryForProduct(item.productId)?.stock ?? 0;
                              if (item.quantity + 1 > stock) {
                                _showErrorToast(context, 'Not enough stock available (only $stock left).');
                                return;
                              }
                              cart.updateQuantity(
                                item.productId,
                                item.quantity + 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 88,
            alignment: Alignment.center,
            child: const Icon(
              Icons.chevron_left,
              color: AppColors.textHint,
              size: 20,
            ),
          ),
        ],
      ),
    ));
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Order Summary ─────────────────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  final CartViewModel cart;

  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal (${cart.selectedItems.length} items)',
            value: '\$${cart.subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Shipping',
            value: 'Calculated at checkout',
            valueColor: AppColors.textHint,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _SummaryRow(
            label: 'Total',
            value: '\$${cart.total.toStringAsFixed(2)}',
            isBold: true,
          ),
        ],
      ),
    );
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
    final style = TextStyle(
      fontSize: isBold ? 16 : 14,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
      color: valueColor ?? AppColors.textPrimary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        Text(value, style: style),
      ],
    );
  }
}

// ── Checkout Bar ──────────────────────────────────────────────────────────────

class _CheckoutBar extends StatelessWidget {
  final CartViewModel cart;

  const _CheckoutBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    // Nếu đang ở trong Bottom Nav (không thể pop), cần thêm padding dưới để không bị che bởi FAB
    final double bottomPadding = context.canPop() ? 28 : 72;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (cart.isEmpty) return;
            if (cart.selectedItems.isEmpty) {
              _showErrorToast(context, 'Bạn vẫn chưa chọn sản phẩm nào để mua.');
              return;
            }
            context.push('/checkout');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: cart.selectedItems.isEmpty ? AppColors.textHint : AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.textHint,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Proceed to Checkout  •  \$${cart.total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

void _showErrorToast(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 180,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
