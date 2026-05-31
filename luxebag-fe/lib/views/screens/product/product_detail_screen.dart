import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/product_model.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/product_viewmodel.dart';
import '../../../viewmodels/cart_viewmodel.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductModel? _product;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _product = context
        .read<ProductViewModel>()
        .products
        .where((p) => p.id == widget.productId)
        .firstOrNull;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Consumer<ProductViewModel>(
      builder: (context, vm, _) {
        final product = vm.products.firstWhere(
          (p) => p.id == widget.productId,
          orElse: () => _product!,
        );

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // ── Scrollable content ──────────────────────────────────
              CustomScrollView(
                slivers: [
                  // Image carousel header
                  SliverToBoxAdapter(
                    child: _ImageCarousel(
                      images: product.images,
                      currentIndex: _currentImageIndex,
                      pageController: _pageController,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      onBack: () => context.pop(),
                      isWishlisted: product.isWishlisted,
                      onWishlistTap: () => vm.toggleWishlist(product.id),
                    ),
                  ),

                  // Product info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand
                          Text(
                            product.brand.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 2,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Title
                          Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // SKU
                          Text(
                            'SKU: ${product.sku}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Price row
                          _PriceRow(product: product),
                          const SizedBox(height: 20),

                          // Badges row
                          _BadgesRow(product: product),
                          const SizedBox(height: 24),

                          const Divider(color: AppColors.divider),
                          const SizedBox(height: 20),

                          // Details section
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Material',
                            value: product.material,
                          ),
                          _DetailRow(
                            label: 'Size',
                            value: product.sizeInfo ?? '-',
                          ),
                          _DetailRow(
                            label: 'Size Category',
                            value: product.sizeCategory,
                          ),
                          _DetailRow(label: 'Gender', value: product.gender),
                          _DetailRow(
                            label: 'Condition',
                            value: product.condition,
                          ),
                          _DetailRow(
                            label: 'Department',
                            value: product.department,
                          ),
                          if (product.saleEventName != null)
                            _DetailRow(
                              label: 'Sale Event',
                              value: product.saleEventName!,
                            ),
                          const SizedBox(height: 20),

                          const Divider(color: AppColors.divider),
                          const SizedBox(height: 20),

                          // Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            product.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Bottom Action Bar ───────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomBar(product: product),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Image Carousel ─────────────────────────────────────────────────────────

class _ImageCarousel extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final bool isWishlisted;
  final VoidCallback onWishlistTap;

  const _ImageCarousel({
    required this.images,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.onBack,
    required this.isWishlisted,
    required this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
      child: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: pageController,
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              if (images.isEmpty) {
                return Container(
                  color: AppColors.surface,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                );
              }
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surface,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                ),
              );
            },
          ),

          // Top nav overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavCircleButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: onBack,
                    ),
                    _NavCircleButton(
                      icon: isWishlisted
                          ? Icons.favorite
                          : Icons.favorite_border,
                      iconColor: isWishlisted
                          ? Colors.red
                          : AppColors.textPrimary,
                      onTap: onWishlistTap,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Dot indicators
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == currentIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

          // Thumbnail strip
          if (images.length > 1)
            Positioned(
              right: 12,
              top: 60,
              child: Column(
                children: List.generate(
                  images.length,
                  (i) => GestureDetector(
                    onTap: () => pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: i == currentIndex
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _NavCircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor ?? AppColors.textPrimary),
      ),
    );
  }
}

// ── Price Row ──────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final ProductModel product;

  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${product.currentPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (product.isOnSale) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${product.retailPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-${product.discountPercentage.toInt()}% OFF',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Badges Row ─────────────────────────────────────────────────────────────

class _BadgesRow extends StatelessWidget {
  final ProductModel product;

  const _BadgesRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Badge(
          label: product.stockStatus,
          color: product.inStock ? AppColors.success : AppColors.error,
          bgColor: product.inStock
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFEBEE),
        ),
        if (product.shippingOptions.freeShipping)
          const _Badge(
            label: 'Free Shipping',
            icon: Icons.local_shipping_outlined,
            color: AppColors.success,
            bgColor: Color(0xFFE8F5E9),
          ),
        if (product.shippingOptions.nextDayShipping)
          const _Badge(
            label: 'Next Day',
            icon: Icons.flash_on_rounded,
            color: Color(0xFFF57F17),
            bgColor: Color(0xFFFFFDE7),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.label,
    this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Row ─────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Action Bar ──────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final ProductModel product;

  const _BottomBar({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Chat button
          OutlinedButton(
            onPressed: () => context.push('/chat'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.inputBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),

          // Add to cart button
          Expanded(
            child: ElevatedButton(
              onPressed: product.inStock
                  ? () {
                      context.read<CartViewModel>().addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Added to bag!'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'View Bag',
                            textColor: Colors.white,
                            onPressed: () => context.push('/cart'),
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textHint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                product.inStock ? 'Add to Cart' : 'Out of Stock',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
