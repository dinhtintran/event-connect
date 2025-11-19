import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/services/admin_service.dart';
import '../../domain/models/admin_user.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminService>();
      admin.loadUsers();
      admin.loadEvents(status: 'pending');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsersTab(),
          _EventsTab(),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();

    if (admin.isLoading && admin.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => admin.loadUsers(),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(child: Text(user.fullName.isNotEmpty ? user.fullName[0] : '?')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user.email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('Role: ${user.role}'),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!user.isActive)
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await admin.activateUser(user.id);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể kích hoạt')));
                      }
                    },
                    child: const Text('Activate'),
                  )
                else
                  OutlinedButton(
                    onPressed: () async {
                      final ok = await admin.deactivateUser(user.id);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể vô hiệu hóa')));
                      }
                    },
                    child: const Text('Deactivate'),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final ok = await admin.deleteUser(user.id);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa người dùng')));
                    }
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();

    if (admin.isLoading && admin.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => admin.loadEvents(status: 'pending'),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: admin.events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final event = admin.events[idx];
          return _AdminEventCard(event: event);
        },
      ),
    );
  }
}

class _AdminEventCard extends StatelessWidget {
  final Event event;
  const _AdminEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminService>();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(event.location, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final ok = await admin.approveEvent(event.id);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể duyệt')));
                    }
                  },
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    // prompt for reason
                    final reason = await showDialog<String?>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reject reason'),
                        content: TextField(
                          decoration: const InputDecoration(hintText: 'Nhập lý do từ chối'),
                          autofocus: true,
                          onSubmitted: (val) => Navigator.of(ctx).pop(val),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(ctx).pop('Rejected'), child: const Text('Submit')),
                        ],
                      ),
                    );
                    if (reason != null) {
                      final ok = await admin.rejectEvent(event.id, reason: reason);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể từ chối')));
                      }
                    }
                  },
                  child: const Text('Reject'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final ok = await admin.deleteEvent(event.id);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa sự kiện')));
                    }
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
