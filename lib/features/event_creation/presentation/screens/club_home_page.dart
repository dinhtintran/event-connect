import 'package:flutter/material.dart';
import 'package:event_connect/app_routes.dart';
import 'package:event_connect/features/event_creation/presentation/widgets/club_event_card_summary.dart';
import 'package:event_connect/features/event_creation/presentation/widgets/club_notification_tile.dart';

class ClubHomePage extends StatefulWidget {
  const ClubHomePage({super.key});

  @override
  State<ClubHomePage> createState() => _ClubHomePageState();
}

class _ClubHomePageState extends State<ClubHomePage> {
  int _selectedIndex = 0; // 0 = Trang chủ

  // Note: navigation to ClubEventsPage now uses named routes

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    // Navigation based on index:
    // 0 -> Trang Chủ (stay here)
    // 1 -> Sự kiện
    // 2 -> Thư (not implemented)
    // 3 -> Thống Kê (not implemented)
    // 4 -> Hồ Sơ

    if (index == 1) {
      // Navigate to Events page
      debugPrint('ClubHomePage: tapping Sự kiện tab -> navigate to ClubEventsPage (named)');
      try {
        Navigator.pushNamed(context, AppRoutes.clubEvents);
      } catch (e, st) {
        debugPrint('Failed to navigate to ClubEventsPage (named): $e\n$st');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi chuyển trang: ${e.toString()}')));
        }
      }
    } else if (index == 4) {
      // Navigate to Profile
      debugPrint('ClubHomePage: tapping Hồ Sơ tab -> navigate to Profile');
      try {
        Navigator.pushNamed(context, AppRoutes.profile);
      } catch (e, st) {
        debugPrint('Failed to navigate to Profile: $e\n$st');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi chuyển trang: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Tổng quan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/beongnho2.jpg',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Icon(Icons.person, size: 18, color: Colors.grey.shade600),
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner card
              GestureDetector(
                onTap: () {},
                child: SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/background.jpg',
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            width: double.infinity,
                            height: 140,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withAlpha((0.45 * 255).round()),
                              Colors.transparent
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        alignment: Alignment.bottomLeft,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chào mừng bạn trở lại, Đội ngũ EventConnect!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tổng quan sự kiện của bạn trong nháy mắt.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Section header: Sự kiện gần đây
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sự kiện gần đây',
                    style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  GestureDetector(
                    // 👉 Khi bấm "Xem tất cả" -> chuyển sang trang ClubEventsPage (có hiệu ứng trượt)
                    onTap: () {
                      debugPrint('ClubHomePage: tapped Xem tất cả -> navigate to ClubEventsPage (named)');
                      try {
                        Navigator.pushNamed(context, AppRoutes.clubEvents);
                      } catch (e, st) {
                        debugPrint('Failed to navigate to ClubEventsPage (named): $e\n$st');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi chuyển trang: ${e.toString()}')));
                        }
                      }
                    },
                    child: Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Event cards
              ClubEventCardSummary(
                title: 'Hội nghị Công nghệ 2024',
                status: 'Live',
                registered: 1250,
                capacity: 1500,
                isLive: true,
                onManage: () {},
                onRegister: () {},
                onEdit: () {},
              ),

              const SizedBox(height: 12),

              ClubEventCardSummary(
                title: 'Workshop Phát triển Game',
                status: 'Scheduled',
                registered: 80,
                capacity: 100,
                isLive: false,
                onManage: () {},
                onRegister: () {},
                onEdit: () {},
              ),

              const SizedBox(height: 22),

              const Text(
                'Thông báo quan trọng',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),

              const SizedBox(height: 12),

              ClubNotificationTile(
                title: 'Phê duyệt sự kiện đang chờ',
                subtitle: 'Hội nghị Khoa học Trẻ cần xem xét.',
                icon: Icons.warning_amber_rounded,
                accent: Colors.orange,
                onTap: () {},
              ),

              const SizedBox(height: 10),

              ClubNotificationTile(
                title: 'Hạn chót sắp tới',
                subtitle:
                "Đăng ký cho 'Đêm Gala' kết thúc sau 3 ngày.",
                icon: Icons.error_outline,
                accent: Colors.red,
                onTap: () {},
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF5568FF),
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event), label: 'Sự Kiện'),
          BottomNavigationBarItem(
              icon: Icon(Icons.mail_outline), label: 'Thư'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Thống Kê'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Hồ Sơ'),
        ],
      ),
    );
  }
}

