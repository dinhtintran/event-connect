import 'package:flutter/material.dart';

import 'package:event_connect/core/widgets/app_nav_bar.dart';
import 'package:event_connect/features/admin_dashboard/presentation/screens/admin_event_management_screen.dart';
import 'package:event_connect/features/admin_dashboard/presentation/screens/admin_home_screen.dart';
import 'package:event_connect/features/admin_dashboard/presentation/screens/admin_reports_screen.dart';
import 'package:event_connect/features/admin_dashboard/presentation/screens/admin_user_management_screen.dart';
import 'package:event_connect/features/profile/presentation/screens/profile_screen.dart';

/// Shell widget that keeps the system admin bottom navigation persistent
/// while caching each tab's state.
class SystemAdminShell extends StatefulWidget {
  const SystemAdminShell({super.key});

  @override
  State<SystemAdminShell> createState() => _SystemAdminShellState();
}

class _SystemAdminShellState extends State<SystemAdminShell> {
  final PageStorageBucket _bucket = PageStorageBucket();
  late final List<Widget> _tabs;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = [
      AdminHomeScreen(
        key: const PageStorageKey('system-admin-home'),
        showBottomNav: false,
        onTabSelected: _handleExternalTabRequest,
      ),
      const AdminUserManagementScreen(key: PageStorageKey('system-admin-users')),
      const AdminEventManagementScreen(key: PageStorageKey('system-admin-events')),
      const AdminReportsScreen(key: PageStorageKey('system-admin-reports')),
      const ProfileScreen(key: PageStorageKey('system-admin-profile')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: _currentIndex,
        roleOverride: 'system_admin',
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  void _handleExternalTabRequest(int index) {
    if (index == _currentIndex) {
      return;
    }
    setState(() => _currentIndex = index);
  }
}
