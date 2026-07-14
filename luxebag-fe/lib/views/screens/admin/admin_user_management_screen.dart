import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_colors.dart';
import '../../../viewmodels/user_viewmodel.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = ''; // All
  bool? _selectedStatus; // All

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    context.read<UserViewModel>().loadUsers(
          search: _searchController.text.trim(),
          role: _selectedRole.isEmpty ? null : _selectedRole,
          isActive: _selectedStatus,
        );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red.shade700;
      case 'staff':
        return AppColors.googleBlue;
      default:
        return AppColors.success;
    }
  }

  Color _getRoleBgColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red.shade50;
      case 'staff':
        return AppColors.googleBlue.withOpacity(0.1);
      default:
        return AppColors.success.withOpacity(0.1);
    }
  }

  void _showAddEditUserDialog(BuildContext context, {UserModel? user}) {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final phoneController = TextEditingController(text: user?.phone);
    final addressController = TextEditingController(text: user?.address);
    final passwordController = TextEditingController();
    String roleValue = user?.role ?? 'customer';
    bool isActiveValue = user?.isActive ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? 'Cập nhật thông tin' : 'Thêm người dùng mới',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                          hintText: 'Nhập tên hiển thị',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 12),
                      // Email
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'example@gmail.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
                          return null;
                        },
                        enabled: !isEdit, // Email cannot be edited
                      ),
                      const SizedBox(height: 12),
                      // Phone
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          hintText: 'Nhập số điện thoại',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Address
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ',
                          hintText: 'Nhập địa chỉ của người dùng',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Password
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: isEdit ? 'Mật khẩu mới (Bỏ trống nếu giữ nguyên)' : 'Mật khẩu',
                          hintText: isEdit ? 'Đổi mật khẩu' : 'Nhập mật khẩu (tối thiểu 6 ký tự)',
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          if (isEdit) return null; // Optional on edit
                          if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                          if (v.length < 6) return 'Mật khẩu phải từ 6 ký tự trở lên';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Role Selection
                      Row(
                        children: [
                          const Icon(Icons.security, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 8),
                          const Text('Vai trò: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: roleValue,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => roleValue = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 12),
                        // Active switch on edit
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Trạng thái hoạt động', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(isActiveValue ? 'Đang hoạt động' : 'Bị vô hiệu hóa'),
                          value: isActiveValue,
                          activeColor: AppColors.success,
                          onChanged: (val) {
                            setDialogState(() => isActiveValue = val);
                          },
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(ctx).pop();

                    final Map<String, dynamic> payload = {
                      'displayName': nameController.text.trim(),
                      'role': roleValue,
                      if (phoneController.text.isNotEmpty) 'phoneNumber': phoneController.text.trim(),
                      if (addressController.text.isNotEmpty) 'address': addressController.text.trim(),
                      if (passwordController.text.isNotEmpty) 'password': passwordController.text,
                    };

                    final vm = context.read<UserViewModel>();
                    final messenger = ScaffoldMessenger.of(context);

                    if (isEdit) {
                      payload['isActive'] = isActiveValue;
                      vm.updateUser(user.id, payload).then((success) {
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Cập nhật tài khoản thành công')),
                          );
                        } else {
                          messenger.showSnackBar(
                            SnackBar(content: Text(vm.errorMessage ?? 'Cập nhật tài khoản thất bại')),
                          );
                        }
                      });
                    } else {
                      payload['email'] = emailController.text.trim();
                      vm.createUser(payload).then((success) {
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Tạo tài khoản mới thành công')),
                          );
                        } else {
                          messenger.showSnackBar(
                            SnackBar(content: Text(vm.errorMessage ?? 'Tạo tài khoản thất bại')),
                          );
                        }
                      });
                    }
                  },
                  child: Text(isEdit ? 'Lưu thay đổi' : 'Thêm tài khoản'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUserDetailsDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getRoleBgColor(user.role),
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _getRoleColor(user.role)),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                _DetailRow(label: 'ID người dùng', value: user.id),
                _DetailRow(label: 'Email', value: user.email),
                _DetailRow(label: 'Số điện thoại', value: user.phone ?? 'Chưa cập nhật'),
                _DetailRow(label: 'Địa chỉ', value: user.address ?? 'Chưa cập nhật'),
                _DetailRow(
                  label: 'Vai trò',
                  value: user.role.toUpperCase(),
                  valueColor: _getRoleColor(user.role),
                  isBold: true,
                ),
                _DetailRow(
                  label: 'Trạng thái',
                  value: user.isActive ? 'ĐANG HOẠT ĐỘNG' : 'BỊ VÔ HIỆU HÓA',
                  valueColor: user.isActive ? AppColors.success : AppColors.error,
                  isBold: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _showAddEditUserDialog(context, user: user);
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Chỉnh sửa'),
            ),
          ],
        );
      },
    );
  }

  void _deleteUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa vĩnh viễn tài khoản của "${user.name}" (${user.email})? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
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
              final vm = context.read<UserViewModel>();
              final messenger = ScaffoldMessenger.of(context);
              vm.deleteUser(user.id).then((success) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Xóa tài khoản thành công')),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text(vm.errorMessage ?? 'Xóa tài khoản thất bại')),
                  );
                }
              });
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
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
          'QUẢN LÝ NGƯỜI DÙNG',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditUserDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── Search & Filter Bars ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên, email, sđt...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadUsers();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (_) {
                _loadUsers();
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Role filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Vai trò',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      DropdownMenuItem(value: 'customer', child: Text('Customer')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedRole = val);
                        _loadUsers();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Status Filter
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Trạng thái',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tất cả')),
                      DropdownMenuItem(value: true, child: Text('Hoạt động')),
                      DropdownMenuItem(value: false, child: Text('Vô hiệu hóa')),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedStatus = val);
                      _loadUsers();
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ── Users list ─────────────────────────────────────────────
          Expanded(
            child: Consumer<UserViewModel>(
              builder: (context, vm, _) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (vm.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            vm.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadUsers,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (vm.users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 56, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text(
                          'Không tìm thấy người dùng nào.',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadUsers(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.users.length,
                    itemBuilder: (context, index) {
                      final user = vm.users[index];
                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.divider, width: 0.8),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showUserDetailsDialog(context, user),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: _getRoleBgColor(user.role),
                                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                                  child: user.avatarUrl == null
                                      ? Text(
                                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: _getRoleColor(user.role),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                // Name & Email
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Role Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getRoleBgColor(user.role),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              user.role.toUpperCase(),
                                              style: TextStyle(
                                                color: _getRoleColor(user.role),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'SĐT: ${user.phone}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Status toggle
                                Switch(
                                  value: user.isActive,
                                  activeColor: AppColors.success,
                                  inactiveThumbColor: AppColors.error,
                                  inactiveTrackColor: AppColors.error.withOpacity(0.2),
                                  onChanged: (val) {
                                    vm.toggleUserStatus(user.id, val).then((success) {
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(val ? 'Đã kích hoạt tài khoản' : 'Đã vô hiệu hóa tài khoản'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(vm.errorMessage ?? 'Thay đổi trạng thái thất bại')),
                                        );
                                      }
                                    });
                                  },
                                ),
                                // More Actions Popup
                                PopupMenuButton<String>(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showAddEditUserDialog(context, user: user);
                                    } else if (val == 'delete') {
                                      _deleteUser(context, user);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Chỉnh sửa'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                          const SizedBox(width: 8),
                                          const Text('Xóa tài khoản', style: TextStyle(color: AppColors.error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}
