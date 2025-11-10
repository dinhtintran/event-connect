import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/admin_dashboard/domain/models/activity.dart';
import 'package:event_connect/features/admin_dashboard/domain/models/admin_stats.dart';
import 'package:event_connect/features/admin_dashboard/domain/services/admin_service.dart';
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
  bool _isLoadingPendingEvents = true;
  bool _isLoadingActivities = true;
  List<Event> _pendingEvents = [];
  List<Activity> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final adminService = Provider.of<AdminService>(context, listen: false);
    
    // Fetch statistics
    await adminService.fetchStats();
    
    // Fetch pending events
    _loadPendingEvents();
    
    // Fetch recent activities
    _loadActivities();
  }

  Future<void> _loadPendingEvents() async {
    setState(() => _isLoadingPendingEvents = true);
    
    final adminService = Provider.of<AdminService>(context, listen: false);
    final response = await adminService.fetchPendingApprovals();
    
    if (response['status'] == 200) {
      final results = response['body']['results'] as List<dynamic>;
      setState(() {
        _pendingEvents = results.map((json) => Event.fromJson(json['event'])).toList();
        _isLoadingPendingEvents = false;
      });
    } else {
      setState(() => _isLoadingPendingEvents = false);
    }
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoadingActivities = true);
    
    final adminService = Provider.of<AdminService>(context, listen: false);
    final response = await adminService.fetchActivities(limit: 10);
    
    if (response['status'] == 200) {
      final results = response['body']['results'] as List<dynamic>;
      setState(() {
        _recentActivities = results.map((json) {
          return Activity(
            id: json['id'].toString(),
            icon: _getIconForAction(json['action']),
            title: json['description'] ?? '',
            subtitle: json['user']?['username'] ?? '',
            timestamp: _formatTimestamp(json['created_at']),
          );
        }).toList();
        _isLoadingActivities = false;
      });
    } else {
      setState(() => _isLoadingActivities = false);
    }
  }

  String _getIconForAction(String? action) {
    switch (action) {
      case 'event_approved':
        return 'check_circle';
      case 'event_rejected':
        return 'cancel';
      case 'event_created':
        return 'event';
      case 'user_registered':
        return 'person_add';
      default:
        return 'info';
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays == 1) {
        return 'Hôm qua';
      } else {
        return '${difference.inDays} ngày trước';
      }
    } catch (e) {
      return '';
    }
  }

  void _handleApproveEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phê duyệt sự kiện'),
        content: Text('Bạn có chắc chắn muốn phê duyệt sự kiện "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final adminService = Provider.of<AdminService>(context, listen: false);
              final success = await adminService.approveEvent(event.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã phê duyệt sự kiện "${event.title}"'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Reload pending events
                _loadPendingEvents();
                _loadData();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể phê duyệt sự kiện. Vui lòng thử lại.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối sự kiện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn từ chối sự kiện "${event.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
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
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do từ chối'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              
              final adminService = Provider.of<AdminService>(context, listen: false);
              final success = await adminService.rejectEvent(event.id, reason: reason);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã từ chối sự kiện "${event.title}"'),
                    backgroundColor: Colors.red,
                  ),
                );
                // Reload pending events
                _loadPendingEvents();
                _loadData();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể từ chối sự kiện. Vui lòng thử lại.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
    // Index mapping (as defined in AppNavBar for school/admin):
    // 0 -> Dashboard (stay on admin home)
    // 1 -> Approvals
    // 2 -> Reports (not implemented)
    // 3 -> Profile (not implemented)
    if (index == 1) {
      // Open the approval screen (replacement so back button doesn't stack multiple admin roots)
      Navigator.of(context).pushReplacementNamed(AppRoutes.approval);
      return;
    }
    if (index == 0) {
      // already on admin dashboard
      return;
    }
    // Other tabs: show a temporary placeholder/snackbar until implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng chưa được triển khai')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminService>(
      builder: (context, adminService, _) {
        final stats = adminService.stats;
        final isLoading = adminService.isLoading;
        
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
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: _loadData,
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                onPressed: () {
                  // TODO: Navigate to notifications
                },
              ),
            ],
          ),
          body: isLoading && stats == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                              value: stats?.overview.totalEvents.toString() ?? '0',
                              backgroundColor: Colors.blue,
                              iconColor: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              icon: Icons.people_outline,
                              label: 'Tổng số người dùng',
                              value: stats?.overview.totalUsers.toString() ?? '0',
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
                      if (_isLoadingPendingEvents)
                        const Center(child: CircularProgressIndicator())
                      else if (_pendingEvents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Không có sự kiện nào đang chờ phê duyệt',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
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
                      if (_isLoadingActivities)
                        const Center(child: CircularProgressIndicator())
                      else if (_recentActivities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Chưa có hoạt động nào',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
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
                              Navigator.of(context).pushReplacementNamed(AppRoutes.approval);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 80), // Space for bottom navigation
                    ],
                  ),
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

