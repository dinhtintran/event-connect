import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/admin/domain/services/admin_service.dart';
import 'package:event_connect/features/admin/domain/models/admin_user.dart';
import 'package:event_connect/features/admin_dashboard/presentation/widgets/notification_bell_admin.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  String? _selectedRole;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().loadUsers(role: _selectedRole);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    context.read<AdminService>().loadUsers(
      search: query.isNotEmpty ? query : null,
      role: _selectedRole,
    );
  }

  void _handleRoleFilter(String? role) {
    setState(() => _selectedRole = role);
    // Backend expects null for "all", not empty string
    context.read<AdminService>().loadUsers(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      role: role,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        actions: [
          const NotificationBellAdmin(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminService>().loadUsers(
              search: _searchController.text.isNotEmpty ? _searchController.text : null,
              role: _selectedRole,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên, email, MSSV...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _handleSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _handleSearch,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _selectedRole == null,
                        onSelected: (_) => _handleRoleFilter(null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Sinh viên'),
                        selected: _selectedRole == 'student',
                        onSelected: (_) => _handleRoleFilter('student'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Club Admin'),
                        selected: _selectedRole == 'club_admin',
                        onSelected: (_) => _handleRoleFilter('club_admin'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('System Admin'),
                        selected: _selectedRole == 'system_admin',
                        onSelected: (_) => _handleRoleFilter('system_admin'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // User List
          Expanded(
            child: Consumer<AdminService>(
              builder: (context, admin, _) {
                if (admin.isLoading && admin.users.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (admin.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Lỗi: ${admin.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => admin.loadUsers(
                            search: _searchController.text.isNotEmpty ? _searchController.text : null,
                            role: _selectedRole,
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (admin.users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không tìm thấy người dùng nào'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => admin.loadUsers(
                    search: _searchController.text.isNotEmpty ? _searchController.text : null,
                    role: _selectedRole,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: admin.users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final user = admin.users[idx];
                      return _UserCard(user: user);
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

class _UserCard extends StatelessWidget {
  final AdminUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminService>();
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: user.isActive ? Colors.blue.shade100 : Colors.grey.shade300,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: user.isActive ? Colors.blue.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'Hoạt động' : 'Vô hiệu',
                    style: TextStyle(
                      color: user.isActive ? Colors.green.shade700 : Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(icon: Icons.badge, label: 'Role: ${_getRoleLabel(user.role)}'),
                const SizedBox(width: 8),
                if (user.studentId != null && user.studentId!.isNotEmpty)
                  _InfoChip(icon: Icons.school, label: 'MSSV: ${user.studentId}'),
                if (user.faculty != null && user.faculty!.isNotEmpty)
                  _InfoChip(icon: Icons.business, label: user.faculty!),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!user.isActive)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        'Kích hoạt người dùng',
                        'Bạn có chắc chắn muốn kích hoạt "${user.fullName}"?',
                      );
                      if (confirmed == true) {
                        final success = await admin.activateUser(user.id);
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã kích hoạt người dùng'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không thể kích hoạt người dùng'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Kích hoạt'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        'Vô hiệu hóa người dùng',
                        'Bạn có chắc chắn muốn vô hiệu hóa "${user.fullName}"?\n\nNgười dùng sẽ không thể đăng nhập sau khi bị vô hiệu hóa.',
                      );
                      if (confirmed == true) {
                        final success = await admin.deactivateUser(user.id);
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã vô hiệu hóa người dùng'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không thể vô hiệu hóa người dùng (có thể bạn đang cố vô hiệu hóa chính mình)'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.block),
                    label: const Text('Vô hiệu hóa'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await _showConfirmDialog(
                      context,
                      'Xóa người dùng',
                      'Bạn có chắc chắn muốn xóa "${user.fullName}"?\n\nHành động này không thể hoàn tác.',
                    );
                    if (confirmed == true) {
                      final success = await admin.deleteUser(user.id);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xóa người dùng'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không thể xóa người dùng (có thể bạn đang cố xóa chính mình)'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'student':
        return 'Sinh viên';
      case 'club_admin':
        return 'Club Admin';
      case 'system_admin':
        return 'System Admin';
      default:
        return role;
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
