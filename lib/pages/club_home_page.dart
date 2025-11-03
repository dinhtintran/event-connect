import 'package:flutter/material.dart';
import 'club_events_page.dart';

class ClubHomePage extends StatefulWidget {
  const ClubHomePage({super.key});

  @override
  State<ClubHomePage> createState() => _ClubHomePageState();
}

class _ClubHomePageState extends State<ClubHomePage> {
  int _selectedIndex = 0; // 0 = Trang chủ

  // Hiệu ứng trượt ngang khi chuyển sang trang khác
  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // từ bên phải sang
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    // 👉 Nếu bấm tab "Sự kiện" trong bottom nav -> chuyển sang trang ClubEventsPage
    if (index == 1) {
      Navigator.push(context, _createSlideRoute(const ClubEventsPage()));
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
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/beongnho2.jpg'),
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
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/images/background.jpg'),
                    ),
                  ),
                  child: Container(
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
                      Navigator.push(
                        context,
                        _createSlideRoute(const ClubEventsPage()),
                      );
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
              _EventCard(
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

              _EventCard(
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

              _NotificationTile(
                title: 'Phê duyệt sự kiện đang chờ',
                subtitle: 'Hội nghị Khoa học Trẻ cần xem xét.',
                icon: Icons.warning_amber_rounded,
                accent: Colors.orange,
                onTap: () {},
              ),

              const SizedBox(height: 10),

              _NotificationTile(
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

// =============================
// Widgets phụ trợ
// =============================

class _EventCard extends StatelessWidget {
  final String title;
  final String status;
  final int registered;
  final int capacity;
  final bool isLive;
  final VoidCallback onManage;
  final VoidCallback onRegister;
  final VoidCallback onEdit;

  const _EventCard({
    super.key,
    required this.title,
    required this.status,
    required this.registered,
    required this.capacity,
    required this.isLive,
    required this.onManage,
    required this.onRegister,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLive ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isLive ? Colors.green : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text('Đăng ký', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            '$registered/$capacity',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              OutlinedButton(
                onPressed: onManage,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Quản lý'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onRegister,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Đăng ký'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.black54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _NotificationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withAlpha((0.12 * 255).round()),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
