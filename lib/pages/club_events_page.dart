import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'club_home_page.dart';

class ClubEventsPage extends StatefulWidget {
  const ClubEventsPage({super.key});

  @override
  State<ClubEventsPage> createState() => _ClubEventsPageState();
}

class _ClubEventsPageState extends State<ClubEventsPage> {
  int _selectedIndex = 1; // Tab "Sự kiện"

  // Hiệu ứng trượt ngược (từ trái sang phải khi quay về)
  Route _createSlideBackRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0); // trượt từ trái sang
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      // Khi bấm Trang chủ, trượt ngược từ phải qua trái
      Navigator.push(context, _createSlideBackRoute(const ClubHomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Sự kiện',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.black),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/beongnho2.jpg'),
            ),
          ),
        ],
      ),

      // Nội dung trang
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Ô tìm kiếm
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm sự kiện...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 🔘 Bộ lọc trạng thái
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  buildFilterChip('Tất cả', true),
                  buildFilterChip('Bản nháp', false),
                  buildFilterChip('Chờ duyệt', false),
                  buildFilterChip('Đã duyệt', false),
                  buildFilterChip('Đang diễn ra', false),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bộ lọc & kiểu xem
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.filter_list,
                      color: Colors.black, size: 18),
                  label: const Text(
                    'Bộ lọc',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.grid_view_rounded,
                          color: Colors.indigo, size: 22),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.view_list_rounded,
                          color: Colors.grey, size: 22),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🟦 Danh sách sự kiện
            const EventCard(
              status: 'Đang diễn ra',
              statusColor: Colors.indigo,
              title: 'Hội thảo Công nghệ Blockchain và Ứng dụng',
              date: '10 Tháng 12, 2024 - 14:00',
              location: 'Phòng hội nghị A2, Đại học Quốc gia',
              organizer: 'Câu lạc bộ Tin học',
              image: 'assets/images/blockchain.png',
            ),
            const SizedBox(height: 16),
            const EventCard(
              status: 'Đã kết thúc',
              statusColor: Colors.grey,
              title: 'Lễ bế mạc Giải bóng đá sinh viên',
              date: '20 Tháng 10, 2024 - 17:00',
              location: 'Sân bóng đá KTX',
              organizer: 'Khoa Giáo dục Thể chất',
              image: 'assets/images/football.jpg',
            ),
            const SizedBox(height: 28),

            // ➕ Nút tạo sự kiện
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Tạo sự kiện mới',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Sự Kiện'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'Thư'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Thống Kê'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Hồ Sơ'),
        ],
      ),
    );
  }

  // Widget filter chip
  Widget buildFilterChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? Colors.transparent : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: selected ? Colors.indigo[100] : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.indigo : Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// 🎟️ Event Card
class EventCard extends StatelessWidget {
  final String status;
  final Color statusColor;
  final String title;
  final String date;
  final String location;
  final String organizer;
  final String image;

  const EventCard({
    super.key,
    required this.status,
    required this.statusColor,
    required this.title,
    required this.date,
    required this.location,
    required this.organizer,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.06 * 255).round()),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh sự kiện
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  image,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),

          // Nội dung card
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(date, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(location,
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.users,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(organizer,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Chi tiết'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Quản lý',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
