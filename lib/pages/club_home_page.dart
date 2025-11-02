import 'package:flutter/material.dart';

class ClubHomePage extends StatefulWidget {
  const ClubHomePage({Key? key}) : super(key: key);

  @override
  State<ClubHomePage> createState() => _ClubHomePageState();
}

class _ClubHomePageState extends State<ClubHomePage> {
  int _selectedIndex = 1; // 1 = Sự kiện (đang được chọn)

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: điều hướng sang trang khác (nếu có)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
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
                          Colors.black.withOpacity(0.45),
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
                    onTap: () {},
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

              // Create event button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Thêm hành động khi bấm button ở đây
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white, // màu icon
                  ),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Tạo sự kiện mới',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5568FF), // màu nền
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Event cards list
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

              // Notifications header
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
    Key? key,
    required this.title,
    required this.status,
    required this.registered,
    required this.capacity,
    required this.isLive,
    required this.onManage,
    required this.onRegister,
    required this.onEdit,
  }) : super(key: key);

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

          // Buttons
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
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  }) : super(key: key);

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
              backgroundColor: accent.withOpacity(0.12),
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
