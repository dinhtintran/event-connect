import 'package:flutter/material.dart';
import 'package:event_connect/app_routes.dart';

class NotificationBellStudent extends StatefulWidget {
  final Color iconColor;
  final double size;
  const NotificationBellStudent({super.key, this.iconColor = Colors.black, this.size = 24});

  @override
  State<NotificationBellStudent> createState() => _NotificationBellStudentState();
}

class _NotificationBellStudentState extends State<NotificationBellStudent> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    // TODO: Replace with real API call for student unread notifications
    // For now, simulate with a fixed value
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _unreadCount = 2; // Replace with real value
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: widget.iconColor, size: widget.size),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
