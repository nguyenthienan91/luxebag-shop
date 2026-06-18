import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/inventory_model.dart';
import '../../../models/product_model.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/inventory_viewmodel.dart';
import '../../../viewmodels/product_viewmodel.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _showScrollToTop = false;
  late final ProductViewModel _productViewModel;

  @override
  void initState() {
    super.initState();
    _productViewModel = context.read<ProductViewModel>();
    _productViewModel.addListener(_onProductsChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _productViewModel.removeListener(_onProductsChanged);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >= 400 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset < 400 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductViewModel>().loadMore();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadData() async {
    await _productViewModel.loadInitial();
    if (mounted) {
      final products = _productViewModel.products;
      context.read<InventoryViewModel>().fetchInventoryForProducts(products);
    }
  }

  void _onProductsChanged() {
    if (mounted) {
      final products = _productViewModel.products;
      context.read<InventoryViewModel>().fetchInventoryForProducts(products);
    }
  }

  void _runBulkInit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Khởi tạo tồn kho hàng loạt',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: const Text(
          'Hệ thống sẽ tự động quét và khởi tạo bản ghi tồn kho (mặc định bằng 0) cho tất cả sản phẩm chưa có dữ liệu tồn kho. Bạn có muốn tiếp tục?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Đang khởi tạo tồn kho...')),
              );
              context.read<InventoryViewModel>().bulkInit().then((count) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Đã khởi tạo thành công cho $count sản phẩm mới')),
                  );
                  _loadData();
                }
              }).catchError((e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Lỗi khởi tạo tồn kho: $e')),
                  );
                }
              });
            },
            child: const Text('Khởi tạo'),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context, ProductModel product, InventoryModel? inventory) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => _StockAdjustDialog(
        product: product,
        inventory: inventory,
      ),
    ).then((updated) {
      if (updated == true && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã cập nhật tồn kho thành công')),
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
          'LUXEBAG ADMIN',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check_rounded, color: AppColors.textPrimary),
            tooltip: 'Khởi tạo tồn kho hàng loạt',
            onPressed: _runBulkInit,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(115),
          child: Column(
            children: [
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _SearchBar(controller: _searchController),
              ),
              _CategoryTabs(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              heroTag: 'scrollToTopInventoryBtn',
              onPressed: _scrollToTop,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.divider, width: 3),
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 36,
              ),
            )
          : null,
      body: Consumer2<ProductViewModel, InventoryViewModel>(
        builder: (context, prodVM, invVM, _) {
          if (prodVM.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (prodVM.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(prodVM.errorMessage!, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _loadData, child: const Text('Thử lại')),
                ],
              ),
            );
          }
          if (prodVM.products.isEmpty) {
            return const Center(child: Text('Không tìm thấy sản phẩm nào.'));
          }

          return ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: prodVM.products.length + 1,
            itemBuilder: (context, index) {
              if (index == prodVM.products.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: prodVM.isLoadingMore
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
                      : prodVM.hasMore
                          ? const SizedBox.shrink()
                          : const Center(
                              child: Text(
                                "Đã hiển thị tất cả sản phẩm",
                                style: TextStyle(fontSize: 12, color: AppColors.textHint),
                              ),
                            ),
                );
              }

              final product = prodVM.products[index];
              final inventory = invVM.getInventoryForProduct(product.id);

              return _InventoryItemTile(
                product: product,
                inventory: inventory,
                onTap: () => _showAdjustStockDialog(context, product, inventory),
              );
            },
          );
        },
      ),
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
        hintText: 'Tìm kiếm sản phẩm, thương hiệu...',
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
              final isSelected = cat.id == 'all'
                  ? vm.selectedCategoryId == null
                  : vm.selectedCategoryId == cat.id;
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

// ── Inventory Item Tile ─────────────────────────────────────────────────────

class _InventoryItemTile extends StatelessWidget {
  final ProductModel product;
  final InventoryModel? inventory;
  final VoidCallback onTap;

  const _InventoryItemTile({
    required this.product,
    required this.inventory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stock = inventory?.stock ?? 0;
    final inStock = stock > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
                image: product.thumbnailUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.thumbnailUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.thumbnailUrl.isEmpty
                  ? const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Model: ${product.modelNumber} | SKU: ${product.sku}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Stock badge & button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: inStock
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Stock: $stock',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: inStock ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cập nhật',
                      style: TextStyle(fontSize: 11, color: AppColors.googleBlue, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.edit_outlined, size: 12, color: AppColors.googleBlue),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stock Adjust Dialog ─────────────────────────────────────────────────────

class _StockAdjustDialog extends StatefulWidget {
  final ProductModel product;
  final InventoryModel? inventory;

  const _StockAdjustDialog({
    required this.product,
    required this.inventory,
  });

  @override
  State<_StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<_StockAdjustDialog> {
  String _selectedAction = 'IMPORT'; // 'IMPORT', 'DEDUCT', 'MANUAL_SET'
  final _amountController = TextEditingController();
  bool _submitting = false;
  String? _dialogError;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() => _dialogError = 'Vui lòng nhập số lượng');
      return;
    }

    final val = int.tryParse(text);
    if (val == null || val < 0) {
      setState(() => _dialogError = 'Vui lòng nhập số nguyên hợp lệ >= 0');
      return;
    }

    if (_selectedAction != 'MANUAL_SET' && val == 0) {
      setState(() => _dialogError = 'Số lượng thay đổi phải lớn hơn 0');
      return;
    }

    setState(() {
      _submitting = true;
      _dialogError = null;
    });

    try {
      final invVM = context.read<InventoryViewModel>();
      if (_selectedAction == 'MANUAL_SET') {
        await invVM.setStock(widget.product.id, val);
      } else {
        await invVM.adjustStock(widget.product.id, _selectedAction, val);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _dialogError = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStock = widget.inventory?.stock ?? 0;
    final logs = widget.inventory?.logs ?? [];

    return DefaultTabController(
      length: 2,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tab bar
              const TabBar(
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Cập nhật kho'),
                  Tab(text: 'Lịch sử biến động'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Adjustment Form
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('Số lượng hiện tại: $currentStock', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 16),
                            const Text('Chọn hành động:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            // Action options
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedAction,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'IMPORT',
                                  child: Text(
                                    'Nhập thêm kho (IMPORT)',
                                    style: TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'DEDUCT',
                                  child: Text(
                                    'Xuất/Khấu trừ (DEDUCT)',
                                    style: TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'MANUAL_SET',
                                  child: Text(
                                    'Đặt lại tồn kho (MANUAL SET)',
                                    style: TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedAction = v);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedAction == 'MANUAL_SET' ? 'Số lượng tồn kho mới:' : 'Số lượng thay đổi:',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: _selectedAction == 'MANUAL_SET' ? 'Ví dụ: 15' : 'Ví dụ: 5',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            if (_dialogError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _dialogError!,
                                style: const TextStyle(color: AppColors.error, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                                  child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  onPressed: _submitting ? null : _submit,
                                  child: _submitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Xác nhận'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tab 2: Logs list
                    logs.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có lịch sử biến động nào.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              // Show logs in reverse order (newest first)
                              final log = logs[logs.length - 1 - index];
                              final isPositive = log.change > 0;
                              final changeText = isPositive ? '+${log.change}' : '${log.change}';
                              final changeColor = log.reason == 'MANUAL_SET'
                                  ? AppColors.googleBlue
                                  : (isPositive ? AppColors.success : AppColors.error);

                              // Format reason for display
                              String displayReason = log.reason;
                              if (log.reason == 'MANUAL_SET') displayReason = 'Đặt thủ công';
                              if (log.reason == 'IMPORT') displayReason = 'Nhập hàng thêm';
                              if (log.reason == 'DEDUCT') displayReason = 'Xuất kho';
                              if (log.reason == 'ORDER') displayReason = 'Đơn hàng';

                              // format date slightly
                              String dateStr = '';
                              try {
                                dateStr = '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}  ${log.createdAt.day.toString().padLeft(2, '0')}/${log.createdAt.month.toString().padLeft(2, '0')}/${log.createdAt.year}';
                              } catch (_) {
                                dateStr = log.createdAt.toString();
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayReason,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                      ],
                                    ),
                                    Text(
                                      changeText,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: changeColor),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
