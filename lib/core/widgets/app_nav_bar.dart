import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:event_connect/features/authentication/domain/services/auth_service.dart';

/// Reusable app navigation bar. The items shown depend on the current user's role.
/// Usage: place inside Scaffold.bottomNavigationBar and provide currentIndex + onTap.
class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? roleOverride;

  const AppNavBar({super.key, required this.currentIndex, required this.onTap, this.roleOverride});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final role = roleOverride ?? auth.user?.profile.role ?? 'student';

    List<BottomNavigationBarItem> items;
    Color selectedColor = const Color(0xFF5669FF);

    if (role == 'school' || role == 'system_admin' || role == 'admin') {
      // School / system admin navigation
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang Chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Phê duyệt'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Báo cáo'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Hồ Sơ'),
      ];
      selectedColor = const Color(0xFF6366F1);
    } else if (role == 'club_admin') {
      // Club navigation
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Sự Kiện'),
        BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'Thư'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Thống Kê'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Hồ Sơ'),
      ];
      selectedColor = const Color(0xFF5568FF);
    } else {
      // Student / default navigation
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Khám phá'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Sự kiện của tôi'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Hồ sơ'),
      ];
      selectedColor = const Color(0xFF5669FF);
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, items.length - 1),
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: selectedColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: items,
      ),
    );
  }
}

