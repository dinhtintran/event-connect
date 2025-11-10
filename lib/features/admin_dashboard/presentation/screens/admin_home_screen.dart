import 'package:flutter/material.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/admin_dashboard/domain/models/activity.dart';
import 'package:event_connect/features/admin_dashboard/presentation/widgets/stat_card.dart';
import 'package:event_connect/features/admin_dashboard/presentation/widgets/pending_event_card.dart';
import 'package:event_connect/features/admin_dashboard/presentation/widgets/activity_item.dart';
import 'package:event_connect/features/admin_dashboard/presentation/widgets/quick_action_button.dart';
import 'package:event_connect/core/widgets/app_nav_bar.dart';
import 'package:event_connect/app_routes.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // Sample data - should be fetched from API
  final List<Event> _pendingEvents = [
    Event(
      id: '1',
      title: 'Lễ hội âm nhạc mùa hè',
      clubId: '1',
      description: 'Summer music festival',
      location: 'Main Hall',
      startAt: DateTime(2024, 7, 15, 18, 0),
      endAt: DateTime(2024, 7, 15, 22, 0),
      posterUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
      capacity: 500,
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: '1',
    ),
    Event(
      id: '2',
      title: 'Hội nghị đổi mới công nghệ',
      clubId: '2',
      description: 'Technology innovation conference',
      location: 'Conference Center',
      startAt: DateTime(2024, 8, 22, 9, 0),
      endAt: DateTime(2024, 8, 22, 17, 0),
      posterUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
      capacity: 300,
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: '2',
    ),
  ];

  final List<Activity> _recentActivities = [
    Activity(
      id: '1',
      icon: 'check_circle',
      title: 'Sự kiện \'Hội chợ việc làm trực tuyến\' đã được phê duyệt.',
      subtitle: '',
      timestamp: '2 phút trước',
    ),
    Activity(
      id: '2',
      icon: 'attach_money',
      title: 'Khoản thanh toán mới được nhận từ \'CLB Lập trình\'.',
      subtitle: '',
      timestamp: '1 giờ trước',
    ),
    Activity(
      id: '3',
      icon: 'person_add',
      title: 'Người dùng \'Nguyễn Văn A\' đã đăng ký sự kiện mới.',
      subtitle: '',
      timestamp: '3 giờ trước',
    ),
    Activity(
      id: '4',
      icon: 'warning',
      title: 'Cảnh báo: Sự kiện \'Giải đấu thể thao điện tử\' bị hủy.',
      subtitle: '',
      timestamp: 'Hôm qua',
    ),
  ];

  void _handleApproveEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Phê duyệt sự kiện'),
            content: Text(
                'Bạn có chắc chắn muốn phê duyệt sự kiện "${event.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Call API to approve event
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã phê duyệt sự kiện "${event.title}"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Phê duyệt'),
              ),
            ],
          ),
    );
  }

  void _handleRejectEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Từ chối sự kiện'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bạn có chắc chắn muốn từ chối sự kiện "${event.title}"?'),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Lý do từ chối',
                    border: OutlineInputBorder(),
                    hintText: 'Nhập lý do từ chối...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Call API to reject event
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã từ chối sự kiện "${event.title}"'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Từ chối'),
              ),
            ],
          ),
    );
  }

  void _onNavigationTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigate to the appropriate screen for admin tabs.
    // Index mapping (as defined in AppNavBar for system_admin):
    // 0 -> Dashboard (stay on admin home)
    // 1 -> Approvals
    // 2 -> Reports (not implemented)
    // 3 -> Profile
    if (index == 1) {
      // Open the approval screen
      Navigator.of(context).pushReplacementNamed(AppRoutes.approval);
      return;
    }
    if (index == 3) {
      // Open profile screen
      Navigator.of(context).pushNamed(AppRoutes.profile);
      return;
    }
    if (index == 0) {
      // already on admin dashboard
      return;
    }
    // For reports or other tabs, do nothing for now
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'EventConnect Admin',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Section
            const Text(
              'Tổng quan thống kê',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.event_outlined,
                    label: 'Tổng số sự kiện',
                    value: '1,250',
                    backgroundColor: Colors.blue,
                    iconColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    icon: Icons.people_outline,
                    label: 'Tổng số người dùng',
                    value: '8,765',
                    backgroundColor: Colors.orange,
                    iconColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Pending Approvals Section
            const Text(
              'Phê duyệt đang chờ xử lý',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._pendingEvents.map((event) => PendingEventCard(
                  event: event,
                  onApprove: () => _handleApproveEvent(event),
                  onReject: () => _handleRejectEvent(event),
                )),
            const SizedBox(height: 32),

            // Recent Activities Section
            const Text(
              'Hoạt động gần đây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._recentActivities.map((activity) => ActivityItem(
                  activity: activity,
                )),
            const SizedBox(height: 32),

            // Quick Actions Section
            const Text(
              'Hành động nhanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                QuickActionButton(
                  icon: Icons.people_outline,
                  label: 'Quản lý người dùng',
                  onTap: () {
                    // TODO: Navigate to user management
                  },
                ),
                QuickActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'Xem báo cáo',
                  onTap: () {
                    // TODO: Navigate to reports
                  },
                ),
                QuickActionButton(
                  icon: Icons.settings_outlined,
                  label: 'Cài đặt ứng dụng',
                  onTap: () {
                    // TODO: Navigate to settings
                  },
                ),
                QuickActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Phê duyệt sự kiện',
                  onTap: () {
                    // TODO: Navigate to approvals
                  },
                ),
              ],
            ),
            const SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigationTapped,
        roleOverride: 'system_admin',
      ),
    );
  }
}
