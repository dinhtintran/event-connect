import 'package:flutter/material.dart';
import 'package:event_connect/core/widgets/app_nav_bar.dart';
import 'package:event_connect/features/event_creation/presentation/screens/club_home_page.dart';
import 'package:event_connect/features/event_creation/presentation/screens/club_events_page.dart';
import 'package:event_connect/features/event_creation/presentation/screens/club_statistics_screen.dart';
import 'package:event_connect/features/event_creation/presentation/screens/club_statistics_detail_screen.dart';
import 'package:event_connect/features/profile/presentation/screens/profile_screen.dart';

/// Shell screen that keeps the club admin bottom navigation persistent.
///
/// Each tab hosts the existing club admin screens but hides their internal
/// navigation bars so we can manage the tab state from this widget.
class ClubAdminShell extends StatefulWidget {
  const ClubAdminShell({super.key});

  @override
  State<ClubAdminShell> createState() => _ClubAdminShellState();
}

class _ClubAdminShellState extends State<ClubAdminShell> {
  final PageStorageBucket _bucket = PageStorageBucket();
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    const ClubHomePage(showBottomNav: false, key: PageStorageKey('club-home-tab')),
    const ClubEventsPage(showBottomNav: false, key: PageStorageKey('club-events-tab')),
    const ClubStatisticsScreen(showBottomNav: false, key: PageStorageKey('club-stats-tab')),
    const ClubStatisticsDetailScreen(showBottomNav: false, key: PageStorageKey('club-stats-detail-tab')),
    const ProfileScreen(key: PageStorageKey('club-profile-tab')),
  ];

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
        roleOverride: 'club_admin',
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
