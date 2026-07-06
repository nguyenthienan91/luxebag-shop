import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../../viewmodels/product_viewmodel.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product; // Nếu null => Thêm mới, nếu có => Cập nhật

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _modelNumberController;
  late TextEditingController _skuController;
  late TextEditingController _descriptionController;
  late TextEditingController _retailPriceController;
  late TextEditingController _currentPriceController;
  late TextEditingController _materialController;
  late TextEditingController _departmentController;

  String? _selectedCategoryId;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleController = TextEditingController(text: p?.title ?? '');
    _modelNumberController = TextEditingController(text: p?.modelNumber ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _retailPriceController = TextEditingController(text: p?.retailPrice.toString() ?? '');
    _currentPriceController = TextEditingController(text: p?.currentPrice.toString() ?? '');
    _materialController = TextEditingController(text: p?.material ?? '');
    _departmentController = TextEditingController(text: p?.department ?? '');
    
    if (p != null) {
      _selectedCategoryId = p.categoryId;
    } else {
      // Khi load form thêm mới, thử chọn category đầu tiên (nếu không phải "All")
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = Provider.of<ProductViewModel>(context, listen: false);
        if (vm.categories.isNotEmpty) {
          final validCat = vm.categories.firstWhere((c) => c.id != 'all', orElse: () => const CategoryModel(id: '', name: ''));
          if (validCat.id.isNotEmpty) {
            setState(() {
              _selectedCategoryId = validCat.id;
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _modelNumberController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _retailPriceController.dispose();
    _currentPriceController.dispose();
    _materialController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId == 'all') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn Category hợp lệ')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final data = {
      'title': _titleController.text.trim(),
      'modelNumber': _modelNumberController.text.trim(),
      'sku': _skuController.text.trim(),
      'description': _descriptionController.text.trim(),
      'retailPrice': double.tryParse(_retailPriceController.text.trim()) ?? 0,
      'currentPrice': double.tryParse(_currentPriceController.text.trim()) ?? 0,
      'material': _materialController.text.trim(),
      'department': _departmentController.text.trim(),
      'categoryId': _selectedCategoryId,
    };

    final vm = Provider.of<ProductViewModel>(context, listen: false);

    try {
      if (widget.product == null) {
        // Create
        await vm.createProduct(data, _selectedImages);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo sản phẩm thành công')));
          context.pop();
        }
      } else {
        // Update
        await vm.updateProduct(widget.product!.id, data, _selectedImages.isNotEmpty ? _selectedImages : null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật sản phẩm thành công')));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Có lỗi xảy ra')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final vm = Provider.of<ProductViewModel>(context);
    final categories = vm.categories.where((c) => c.id != 'all').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa Sản phẩm' : 'Thêm Sản phẩm mới'),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_titleController, 'Tên sản phẩm (*)', true),
                    _buildTextField(_modelNumberController, 'Model Number (*)', true),
                    _buildTextField(_skuController, 'SKU (*)', true),
                    _buildTextField(_descriptionController, 'Mô tả (*)', true, maxLines: 3),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_retailPriceController, 'Giá gốc (*)', true, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_currentPriceController, 'Giá bán (*)', true, isNumber: true)),
                      ],
                    ),
                    _buildTextField(_materialController, 'Chất liệu (*)', true),
                    _buildTextField(_departmentController, 'Phòng ban / Danh mục lớn (*)', true),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Danh mục (*)', border: OutlineInputBorder()),
                      value: categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
                      items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                      validator: (value) => value == null ? 'Vui lòng chọn danh mục' : null,
                    ),
                    const SizedBox(height: 24),
                    Text('Ảnh sản phẩm', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._selectedImages.asMap().entries.map((e) => Stack(
                          children: [
                            Image.file(File(e.value.path), width: 100, height: 100, fit: BoxFit.cover),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _removeImage(e.key),
                              ),
                            )
                          ],
                        )),
                        InkWell(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    if (isEditing && widget.product!.images.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Ảnh hiện tại (Sẽ bị thay thế nếu bạn chọn ảnh mới)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: widget.product!.images.map((url) => Image.network(url, width: 80, height: 80, fit: BoxFit.cover)).toList(),
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _submitForm,
                      child: Text(isEditing ? 'Cập nhật' : 'Thêm mới', style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isRequired, {int maxLines = 1, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'Vui lòng nhập thông tin này';
          }
          if (isNumber && double.tryParse(value ?? '') == null) {
            return 'Vui lòng nhập số hợp lệ';
          }
          return null;
        },
      ),
    );
  }
}
