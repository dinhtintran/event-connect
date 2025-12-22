import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:event_connect/features/notifications/data/api/notification_api.dart';
import 'package:event_connect/features/notifications/data/models/notification_model.dart';
import 'package:event_connect/app_routes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationApi = NotificationApi();
  final _storage = const FlutterSecureStorage();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await _storage.read(key: 'auth_access');

      if (accessToken == null) {
        setState(() {
          _errorMessage = 'Bạn cần đăng nhập để xem thông báo';
          _isLoading = false;
        });
        return;
      }

      final result = await _notificationApi.getNotifications(
        accessToken: accessToken,
      );

      if (result['status'] == 200) {
        final data = result['body'];

        setState(() {
          if (data['results'] != null) {
            _notifications = (data['results'] as List)
                .map((json) => NotificationModel.fromJson(json))
                .toList();
          }
          _unreadCount = data['unread_count'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không thể tải thông báo';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final accessToken = await _storage.read(key: 'auth_access');
      if (accessToken == null) return;

      final result = await _notificationApi.markAsRead(
        accessToken: accessToken,
        notificationId: notification.id,
      );

      if (result['status'] == 200) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = NotificationModel.fromJson({
              ...notification.toJson(),
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
            });
          }
          if (_unreadCount > 0) _unreadCount--;
        });
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final accessToken = await _storage.read(key: 'auth_access');
      if (accessToken == null) return;

      final result = await _notificationApi.markAllAsRead(
        accessToken: accessToken,
      );

      if (result['status'] == 200) {
        setState(() {
          _notifications = _notifications.map((n) {
            return NotificationModel.fromJson({
              ...n.toJson(),
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
            });
          }).toList();
          _unreadCount = 0;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông báo',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount chưa đọc',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Đọc tất cả'),
            ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadNotifications,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không có thông báo nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return NotificationTile(
                            notification: notification,
                            onTap: () => _markAsRead(notification),
                          );
                        },
                      ),
                    ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getIconByType() {
    switch (notification.type.toLowerCase()) {
      case 'event':
        return Icons.event;
      case 'registration':
        return Icons.confirmation_number;
      case 'reminder':
        return Icons.access_time;
      case 'cancellation':
        return Icons.cancel;
      case 'update':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorByType() {
    switch (notification.type.toLowerCase()) {
      case 'event':
        return const Color(0xFF5669FF);
      case 'registration':
        return Colors.green;
      case 'reminder':
        return Colors.orange;
      case 'cancellation':
        return Colors.red;
      case 'update':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getColorByType().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconByType(),
                color: _getColorByType(),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: const Color(0xFF120D26),
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5669FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.getTimeAgo(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

