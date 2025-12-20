import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/app_routes.dart';
import 'package:event_connect/features/authentication/authentication.dart';
import 'package:event_connect/features/event_creation/data/repositories/club_admin_repository.dart';
import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:intl/intl.dart';

class ClubStatisticsScreen extends StatefulWidget {
  const ClubStatisticsScreen({super.key});

  @override
  State<ClubStatisticsScreen> createState() => _ClubStatisticsScreenState();
}

class _ClubStatisticsScreenState extends State<ClubStatisticsScreen> {
  int _selectedIndex = 3; // Tab "Thống kê"
  
  // Statistics data (mock)
  int _totalParticipants = 1200;
  double _attendanceRate = 85.0;
  int _completedEvents = 15;
  double _satisfactionLevel = 4.7;
  
  // Changes
  double _participantsChange = 12.0;
  double _attendanceChange = -3.0;
  int _eventsChange = 1;
  double _satisfactionChange = 0.2;
  
  // Monthly attendance data (last 6 months)
  final List<int> _monthlyAttendance = [250, 450, 300, 500, 620, 380];
  
  // Academic year distribution
  final Map<String, int> _academicYearDistribution = {
    'Năm 1': 35,
    'Năm 2': 28,
    'Năm 3': 22,
    'Năm 4': 15,
  };
  
  // Recent feedbacks
  final List<Map<String, dynamic>> _recentFeedbacks = [
    {
      'name': 'Nguyễn Văn An',
      'rating': 5,
      'comment': 'Sự kiện được tổ chức rất chuyên nghiệp và bổ ích! Rất mong chờ các sự kiện tiếp theo.',
      'avatar': 'assets/images/beongnho2.jpg',
    },
    {
      'name': 'Trần Thị Bình',
      'rating': 4,
      'comment': 'Nội dung rất hay, nhưng khu vực check-in hơi đông. Cần cải thiện thêm.',
      'avatar': 'assets/images/beongnho2.jpg',
    },
  ];
  
  // Event highlights images
  final List<String> _eventHighlights = [
    'assets/images/background.jpg',
    'assets/images/background.jpg',
    'assets/images/background.jpg',
    'assets/images/background.jpg',
  ];
  
  bool _isLoading = false;
  String? _clubId;
  late final ClubAdminRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = ClubAdminRepository(api: ClubAdminApi());
    _loadClubId();
    _loadStatistics();
  }

  Future<void> _loadClubId() async {
    final authService = context.read<AuthService>();
    final user = authService.user;
    
    if (user == null) return;
    
    String? clubId;
    if (user.profile.clubName != null && user.profile.clubName!.isNotEmpty) {
      try {
        final clubApi = ClubAdminApi();
        final clubsResult = await clubApi.clubApi.getAllClubs();
        if (clubsResult['status'] == 200) {
          final clubs = clubsResult['body'];
          if (clubs is Map && clubs.containsKey('results')) {
            final results = clubs['results'] as List;
            try {
              final matchingClub = results.firstWhere(
                (c) => c['name'] == user.profile.clubName,
              );
              clubId = matchingClub['id']?.toString();
            } catch (e) {
              debugPrint('Club not found by name');
            }
          } else if (clubs is List) {
            try {
              final matchingClub = clubs.firstWhere(
                (c) => c['name'] == user.profile.clubName,
              );
              clubId = matchingClub['id']?.toString();
            } catch (e) {
              debugPrint('Club not found by name');
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching clubs: $e');
      }
    }
    
    setState(() {
      _clubId = clubId ?? '1';
    });
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });
    
    // TODO: Load real statistics from API
    // For now, using mock data
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushNamed(context, AppRoutes.clubHome);
    } else if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.clubEvents);
    } else if (index == 2) {
      // Thư -> ở lại trang Báo cáo sự kiện (tổng quan)
      // Stay on this page
    } else if (index == 3) {
      // Thống Kê -> trang chi tiết thống kê
      Navigator.pushNamed(context, AppRoutes.clubStatisticsDetail);
    } else if (index == 4) {
      Navigator.pushNamed(context, AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E102B),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5C6BF0), Color(0xFF8456EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Báo cáo sự kiện',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tổng quan hiệu suất & mức độ hài lòng',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: () {},
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/beongnho2.jpg',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => const Icon(Icons.person, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSummary(),
                    const SizedBox(height: 18),

                    // Statistics Overview Cards
                    _buildStatisticsOverview(),
                    const SizedBox(height: 20),
                    
                    // Monthly Attendance Trend
                    _buildMonthlyAttendanceChart(),
                    const SizedBox(height: 20),
                    
                    // Academic Year Distribution
                    _buildAcademicYearChart(),
                    const SizedBox(height: 20),
                    
                    // Recent Feedback
                    _buildRecentFeedback(),
                    const SizedBox(height: 20),
                    
                    // Event Highlights
                    _buildEventHighlights(),
                    const SizedBox(height: 20),
                    
                    // Export Report
                    _buildExportReport(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF5C6BF0),
        unselectedItemColor: Colors.grey.shade500,
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang Chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Sự Kiện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Thống Kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Hồ Sơ',
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tổng quan thống kê',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.clubStatisticsDetail),
              child: const Text(
                'Xem chi tiết',
                style: TextStyle(color: Color(0xFF7E8BFF), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.clubStatisticsDetail),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.25,
            children: [
              _buildStatCard(
                icon: Icons.people,
                change: _participantsChange,
                value: _totalParticipants.toString(),
                label: 'Tổng số người tham dự',
                isPositive: _participantsChange > 0,
                sparkline: _monthlyAttendance.map((e) => e.toDouble()).toList(),
              ),
              _buildStatCard(
                icon: Icons.check_circle,
                change: _attendanceChange,
                value: '${_attendanceRate.toStringAsFixed(0)}%',
                label: 'Tỷ lệ tham dự',
                isPositive: _attendanceChange > 0,
                sparkline: [80, 82, 79, 85, 87, 85],
              ),
              _buildStatCard(
                icon: Icons.calendar_today,
                change: _eventsChange.toDouble(),
                value: _completedEvents.toString(),
                label: 'Sự kiện đã hoàn thành',
                isPositive: _eventsChange > 0,
                sparkline: [2, 3, 2, 4, 1, 3],
              ),
              _buildStatCard(
                icon: Icons.favorite,
                change: _satisfactionChange,
                value: '${_satisfactionLevel.toStringAsFixed(1)}/5',
                label: 'Mức độ hài lòng',
                isPositive: _satisfactionChange > 0,
                sparkline: [4.5, 4.6, 4.4, 4.8, 4.7, 4.7],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C6BF0), Color(0xFF7E5AF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hiệu suất tổng quan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildHeroChip(Icons.trending_up, '+12% tham dự'),
                    const SizedBox(width: 8),
                    _buildHeroChip(Icons.emoji_events_outlined, '4.7/5 hài lòng'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '15 sự kiện hoàn thành · 85% tỷ lệ tham dự',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required double change,
    required String value,
    required String label,
    required bool isPositive,
    List<double>? sparkline,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF5568FF), size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(change % 1 == 0 ? 0 : 1)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (sparkline != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: CustomPaint(
                    painter: _MiniSparklinePainter(sparkline),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyAttendanceChart() {
    final maxValue = _monthlyAttendance.reduce((a, b) => a > b ? a : b);
    final chartHeight = 200.0;
    final monthLabels = ['Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Xu hướng tham dự theo tháng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.access_time, size: 14, color: Color(0xFF5568FF)),
                    SizedBox(width: 6),
                    Text(
                      '6 tháng gần đây',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5568FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hiển thị số lượng người tham dự trong 6 tháng qua.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_monthlyAttendance.length, (index) {
                final value = _monthlyAttendance[index];
                final height = (value / maxValue) * (chartHeight - 40);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5568FF), Color(0xFF7E5AF0)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          monthLabels[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicYearChart() {
    final total = _academicYearDistribution.values.reduce((a, b) => a + b);
    final colors = [
      const Color(0xFF5568FF),
      const Color(0xFF00C49A),
      const Color(0xFFFF7E67),
      const Color(0xFF4FC3F7),
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bố đăng ký theo năm học',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tỷ lệ sinh viên theo từng năm học đã đăng ký.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Custom pie chart visualization
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    data: _academicYearDistribution.values.toList(),
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_academicYearDistribution.length, (index) {
                    final entry = _academicYearDistribution.entries.toList()[index];
                    final percentage = (entry.value / total * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[index],
                              shape: BoxShape.rectangle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sinh viên ${entry.key}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFeedback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phản hồi gần đây',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._recentFeedbacks.map((feedback) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                child: ClipOval(
                  child: Image.asset(
                    feedback['avatar'] as String,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => const Icon(Icons.person),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback['name'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 16,
                          color: index < (feedback['rating'] as int)
                              ? Colors.amber
                              : Colors.grey.shade300,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feedback['comment'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildEventHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Điểm nhấn sự kiện',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Navigate to all highlights
              },
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  color: Color(0xFF5568FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          children: _eventHighlights.map((imagePath) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 48),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExportReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xuất báo cáo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildExportButton(
          icon: Icons.description,
          label: 'Xuất báo cáo tham dự (PDF)',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng xuất PDF đang được phát triển')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildExportButton(
          icon: Icons.download,
          label: 'Xuất danh sách đăng ký (Excel)',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng xuất Excel đang được phát triển')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildExportButton(
          icon: Icons.email,
          label: 'Gửi báo cáo trường (Email)',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng gửi email đang được phát triển')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5568FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Custom painter for pie chart
class _PieChartPainter extends CustomPainter {
  final List<int> data;
  final List<Color> colors;

  _PieChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.reduce((a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    double startAngle = -90 * (3.14159 / 180); // Start from top
    
    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i] / total) * 360 * (3.14159 / 180);
      
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Mini sparkline painter for KPI cards
class _MiniSparklinePainter extends CustomPainter {
  final List<double> values;
  _MiniSparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs() < 1 ? 1 : maxVal - minVal;

    final linePaint = Paint()
      ..color = const Color(0xFF5C6BF0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF5C6BF0).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fill = Path();

    for (int i = 0; i < values.length; i++) {
      final dx = i / (values.length - 1) * size.width;
      final dy = size.height - ((values[i] - minVal) / range * size.height);
      if (i == 0) {
        path.moveTo(dx, dy);
        fill.moveTo(dx, size.height);
        fill.lineTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
        fill.lineTo(dx, dy);
      }
      if (i == values.length - 1) {
        fill.lineTo(dx, size.height);
      }
    }
    fill.close();

    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

