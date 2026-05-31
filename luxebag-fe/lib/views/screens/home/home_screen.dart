import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/product_viewmodel.dart';
import '../../../viewmodels/notification_viewmodel.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/product/product_skeleton.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductViewModel>().loadMore();
    }
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
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 32,
            color: AppColors.textPrimary,
          ),
        ),
        title: const Text(
          'LUXEBAG',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<NotificationViewModel>(
            builder: (context, notifVM, _) => Badge(
              isLabelVisible: notifVM.unreadCount > 0,
              label: Text(
                notifVM.unreadCount > 9 ? '9+' : '${notifVM.unreadCount}',
                style: const TextStyle(fontSize: 9),
              ),
              backgroundColor: Colors.red,
              textColor: Colors.white,
              offset: const Offset(-4, 4),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 32,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.push('/notifications'),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(57),
          child: Column(
            children: [
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 4),
              _CategoryTabs(),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Consumer<ProductViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) return _SkeletonGrid();
        if (vm.errorMessage != null) {
          return _ErrorView(message: vm.errorMessage!, onRetry: vm.loadInitial);
        }
        if (vm.products.isEmpty) return const _EmptyView();
        return _ProductGrid(vm: vm, scrollController: _scrollController);
      },
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (v) => context.read<ProductViewModel>().onSearchChanged(v),
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search bags, brands...',
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.textSecondary,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) => value.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    controller.clear();
                    context.read<ProductViewModel>().onSearchChanged('');
                  },
                )
              : const SizedBox.shrink(),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputFocused, width: 1),
        ),
      ),
    );
  }
}

// ── Category Tabs ──────────────────────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProductViewModel>(
      builder: (context, vm, _) {
        if (vm.categories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: vm.categories.length,
            itemBuilder: (context, index) {
              final cat = vm.categories[index];
              final isSelected = vm.selectedCategoryId == cat.id;
              return GestureDetector(
                onTap: () => vm.selectCategory(cat.id),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Product Grid ───────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  final ProductViewModel vm;
  final ScrollController scrollController;

  const _ProductGrid({required this.vm, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: vm.products[index]),
              childCount: vm.products.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: vm.isLoadingMore
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
                : vm.hasMore
                ? const SizedBox.shrink()
                : const Center(
                    child: Text(
                      "You've seen all products",
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Skeleton Grid ──────────────────────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}

// ── Empty & Error ──────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different keyword or category',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
