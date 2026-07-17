import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../../../viewmodels/order_viewmodel.dart';
import '../../../viewmodels/notification_viewmodel.dart';
import 'vnpay_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shipping fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedProvince;
  double _shippingFee = 0.0;

  final List<String> _provinces = [
    'Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng', 'Bình Dương', 'Đồng Nai', 'Cần Thơ', 'Khác (Liên Miền)'
  ];

  final List<String> _southernProvinces = [
    'Bình Phước', 'Bình Dương', 'Đồng Nai', 'Tây Ninh', 'Bà Rịa - Vũng Tàu',
    'Long An', 'Đồng Tháp', 'Tiền Giang', 'An Giang', 'Bến Tre', 'Vĩnh Long',
    'Trà Vinh', 'Hậu Giang', 'Kiên Giang', 'Sóc Trăng', 'Bạc Liêu', 'Cà Mau', 'Cần Thơ'
  ];

  void _calculateShippingFee() {
    if (!mounted) return;
    final cart = context.read<CartViewModel>();
    
    if (_selectedProvince == null) {
      setState(() => _shippingFee = 0.0);
      return;
    }

    double totalWeight = 0;
    for (var item in cart.items) {
      if (cart.selectedItems.contains(item.productId)) {
        double weight = 0.5;
        switch (item.product.sizeCategory) {
          case 'Mini': weight = 0.4; break;
          case 'Small': weight = 0.6; break;
          case 'Medium': weight = 1.0; break;
          case 'Large': weight = 1.5; break;
        }
        totalWeight += weight * item.quantity;
      }
    }

    if (totalWeight <= 0) {
      setState(() => _shippingFee = 0.0);
      return;
    }

    double feeVnd = 0;
    if (_selectedProvince == 'Hồ Chí Minh') {
      feeVnd = 30000;
      if (totalWeight > 3) feeVnd += ((totalWeight - 3) / 0.5).ceil() * 2500;
    } else if (['Hà Nội', 'Đà Nẵng'].contains(_selectedProvince)) {
      feeVnd = 40000;
      if (totalWeight > 0.5) feeVnd += ((totalWeight - 0.5) / 0.5).ceil() * 5000;
    } else if (_southernProvinces.contains(_selectedProvince)) {
      feeVnd = 35000;
      if (totalWeight > 0.5) feeVnd += ((totalWeight - 0.5) / 0.5).ceil() * 2500;
    } else {
      feeVnd = 40000;
      if (totalWeight > 0.5) feeVnd += ((totalWeight - 0.5) / 0.5).ceil() * 5000;
    }

    setState(() {
      _shippingFee = double.parse((feeVnd / 26267.54).toStringAsFixed(2));
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateShippingFee();
    });
  }

  // Payment method
  String _paymentMethod = 'cod';

  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPlacingOrder = true);

    final cartVM = context.read<CartViewModel>();
    final orderVM = context.read<OrderViewModel>();

    // Mapping từ Radio value sang giá trị Backend Enum (nếu là CARD hoặc BANK thì chuyển thành VNPAY)
    String backendPaymentMethod =
        (_paymentMethod == 'card' || _paymentMethod == 'bank')
        ? 'VNPAY'
        : 'COD';

    final result = await orderVM.checkout(
      _selectedProvince ?? '',
      _addressController.text.trim(),
      backendPaymentMethod,
      cartVM,
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    if (result != null) {
      final paymentUrl = result['paymentUrl'] as String?;
      final orderId = (result['_id'] ?? result['id'] ?? '') as String;

      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        // Mở WebView thanh toán VNPay
        final webViewResult = await Navigator.push<Map<String, String?>?>(
          context,
          MaterialPageRoute(
            builder: (context) => VNPayWebViewScreen(paymentUrl: paymentUrl),
          ),
        );

        if (!mounted) return;

        if (webViewResult != null) {
          final responseCode = webViewResult['vnp_ResponseCode'];
          final txnRef = webViewResult['vnp_TxnRef'] ?? orderId;

          if (responseCode == '00') {
            // Thanh toán thành công -> Điều hướng qua màn hình PaymentSuccess
            context.read<NotificationViewModel>().loadNotifications(refresh: true);
            context.go('/payment-success?orderId=$txnRef');
          } else {
            // Thanh toán thất bại -> Điều hướng qua màn hình PaymentFailed
            context.go('/payment-failed?orderId=$txnRef');
          }
        } else {
          // Người dùng chủ động đóng WebView mà không hoàn tất thanh toán thành công
          context.go('/payment-failed?orderId=$orderId');
        }
      } else {
        // Đối với COD, hiển thị dialog thành công như bình thường
        context.read<NotificationViewModel>().loadNotifications(refresh: true);
        _showSuccessDialog();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (orderVM.errorMessage?.isNotEmpty ?? false)
                ? orderVM.errorMessage!
                : 'Checkout failed.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Placed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order has been placed successfully.\nWe\'ll notify you once it\'s shipped.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // pop success dialog
                  context.goNamed('home', queryParameters: {'tab': '3'});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View My Orders',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // pop success dialog
                context.goNamed('home', queryParameters: {'tab': '0'});
              },
              child: const Text(
                'Continue Shopping',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();

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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Checkout',
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Shipping Address ────────────────────────────────────────
            _SectionTitle(title: 'Shipping Address'),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'John Doe',
              icon: Icons.person_outline,
              isRequired: true,
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Please enter your full name'
                  : null,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '+84 xxx xxx xxx',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isRequired: true,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your phone number'
                  : null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Province/City',
                hintText: 'Select your province',
                prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.textHint, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              value: _selectedProvince,
              items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (value) {
                setState(() => _selectedProvince = value);
                _calculateShippingFee();
              },
              validator: (v) => v == null ? 'Please select your province' : null,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _addressController,
              label: 'Street Address',
              hint: '123 Example Street, District 1',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              isRequired: true,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your address'
                  : null,
            ),
            const SizedBox(height: 28),

            // ── Payment Method ──────────────────────────────────────────
            _SectionTitle(title: 'Payment Method'),
            const SizedBox(height: 10),

            _PaymentOption(
              value: 'cod',
              groupValue: _paymentMethod,
              icon: Icons.payments_outlined,
              label: 'COD',
              description: 'Pay when your order arrives',
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const SizedBox(height: 8),
            _PaymentOption(
              value: 'bank',
              groupValue: _paymentMethod,
              icon: Icons.account_balance_outlined,
              label: 'VNPAY',
              description: 'Transfer to our bank account',
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const SizedBox(height: 8),

            const SizedBox(height: 28),

            // ── Order Summary ───────────────────────────────────────────
            _SectionTitle(title: 'Order Summary'),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Item list (compact)
                  ...cart.items
                      .where((item) => cart.selectedItems.contains(item.productId))
                      .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.title} × ${item.quantity}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '\$${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 16, color: AppColors.divider),

                  // Subtotal
                  _SummaryLine(
                    label: 'Subtotal',
                    value: '\$${cart.subtotal.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 6),

                  // Shipping
                  _SummaryLine(
                    label: 'Shipping',
                    value: _selectedProvince == null
                        ? 'Select Province'
                        : _shippingFee == 0
                            ? 'FREE'
                            : '\$${_shippingFee.toStringAsFixed(2)}',
                    valueColor: _selectedProvince == null
                        ? AppColors.textHint
                        : _shippingFee == 0
                            ? AppColors.success
                            : AppColors.textPrimary,
                  ),
                  const Divider(height: 16, color: AppColors.divider),

                  // Total
                  _SummaryLine(
                    label: 'Total',
                    value: '\$${(cart.subtotal + _shippingFee).toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Confirm Button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.textHint,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Confirm Order',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        label: Text.rich(
          TextSpan(
            text: label,
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.inputFocused,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Payment Option ─────────────────────────────────────────────────────────────

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String label;
  final String description;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.label,
    required this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.inputBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Line ──────────────────────────────────────────────────────────────

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryLine({
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
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
