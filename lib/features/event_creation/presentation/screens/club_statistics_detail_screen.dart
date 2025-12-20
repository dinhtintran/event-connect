import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/app_routes.dart';
import 'package:event_connect/features/authentication/authentication.dart';

class ClubStatisticsDetailScreen extends StatefulWidget {
  const ClubStatisticsDetailScreen({super.key});

  @override
  State<ClubStatisticsDetailScreen> createState() => _ClubStatisticsDetailScreenState();
}

class _ClubStatisticsDetailScreenState extends State<ClubStatisticsDetailScreen> {
  int _selectedIndex = 3; // Tab "Thống Kê"
  bool _isLoading = false;

  // Mock data for illustration
  final List<double> _trendData = [120, 180, 160, 220, 260, 230, 280];
  final List<int> _eventCompletion = [3, 2, 4, 3, 1, 2, 5];
  final Map<String, double> _channelShare = {
    'Email': 32,
    'Mạng xã hội': 28,
    'Bạn bè giới thiệu': 18,
    'Khác': 22,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E102B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E102B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thống kê chi tiết',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Tổng quan nhanh'),
                    const SizedBox(height: 12),
                    _buildKpiRow(),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Xu hướng tham dự'),
                    const SizedBox(height: 12),
                    _buildLineChart(),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Tiến độ hoàn thành sự kiện'),
                    const SizedBox(height: 12),
                    _buildBarChart(),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Nguồn đăng ký'),
                    const SizedBox(height: 12),
                    _buildDonutChart(),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Insight nhanh'),
                    const SizedBox(height: 12),
                    _buildInsightList(),
                    const SizedBox(height: 32),

                    _buildExportActions(),
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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushNamed(context, AppRoutes.clubHome);
    } else if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.clubEvents);
    } else if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.clubStatistics);
    } else if (index == 3) {
      // Stay on statistics detail page
    } else if (index == 4) {
      Navigator.pushNamed(context, AppRoutes.profile);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // TODO: Fetch real data from API
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildKpiRow() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: const [
        _KpiCard(label: 'Tổng tham dự', value: '1.200', delta: '+12%', positive: true),
        _KpiCard(label: 'Tỷ lệ tham dự', value: '85%', delta: '-3%', positive: false),
        _KpiCard(label: 'Sự kiện hoàn thành', value: '15', delta: '+1', positive: true),
        _KpiCard(label: 'Hài lòng', value: '4.7/5', delta: '+0.2', positive: true),
      ],
    );
  }

  Widget _buildLineChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: SizedBox(
        height: 220,
        child: CustomPaint(
          painter: _LineChartPainter(_trendData),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: SizedBox(
        height: 220,
        child: CustomPaint(
          painter: _BarChartPainter(_eventCompletion),
        ),
      ),
    );
  }

  Widget _buildDonutChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _DonutChartPainter(_channelShare.values.toList()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _channelShare.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _DonutChartPainter.palette[_channelShare.keys.toList().indexOf(e.key) % _DonutChartPainter.palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${e.value.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInsightList() {
    final insights = [
      'Thời gian vàng: 18h-20h cho lượng tham dự cao nhất.',
      'Email + mạng xã hội đóng góp ~60% lượt đăng ký.',
      'Sự kiện kỹ năng mềm có mức hài lòng cao nhất (4.8/5).',
      'Tỷ lệ no-show giảm 5% khi gửi nhắc lịch 24h trước sự kiện.',
    ];
    return Column(
      children: insights
          .map((text) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: _cardBox(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.insights, color: Color(0xFF5C6BF0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(color: Colors.grey.shade100, fontSize: 13.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildExportActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hành động nhanh',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _primaryButton(Icons.picture_as_pdf, 'Xuất báo cáo PDF'),
        const SizedBox(height: 12),
        _primaryButton(Icons.table_chart_outlined, 'Xuất bảng dữ liệu (CSV/Excel)'),
        const SizedBox(height: 12),
        _primaryButton(Icons.email_outlined, 'Gửi báo cáo qua email'),
      ],
    );
  }

  Widget _primaryButton(IconData icon, String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label đang được phát triển')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C6BF0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          elevation: 0,
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  BoxDecoration _cardBox() {
    return BoxDecoration(
      color: const Color(0xFF16193A),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool positive;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16193A),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade200, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: positive ? Colors.green.shade100.withOpacity(0.2) : Colors.red.shade100.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  delta,
                  style: TextStyle(
                    color: positive ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs() < 1 ? 1 : maxVal - minVal;

    final paintLine = Paint()
      ..color = const Color(0xFF5C6BF0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..color = const Color(0xFF5C6BF0).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final dx = i / (data.length - 1) * size.width;
      final dy = size.height - ((data[i] - minVal) / range * size.height);
      if (i == 0) {
        path.moveTo(dx, dy);
        fillPath.moveTo(dx, size.height);
        fillPath.lineTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
        fillPath.lineTo(dx, dy);
      }
      if (i == data.length - 1) {
        fillPath.lineTo(dx, size.height);
      }
    }

    fillPath.close();
    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartPainter extends CustomPainter {
  final List<int> data;
  _BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final barWidth = size.width / (data.length * 1.6);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF5C6BF0), Color(0xFF7E5AF0)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      final barHeight = (value / maxVal) * (size.height * 0.9);
      final dx = (i + 0.2) * (barWidth * 1.6);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  static const palette = [
    Color(0xFF5C6BF0),
    Color(0xFF00C49A),
    Color(0xFFFF7E67),
    Color(0xFF4FC3F7),
  ];

  _DonutChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (p, c) => p + c);
    double startAngle = -90 * (3.14159 / 180);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 360 * (3.14159 / 180);
      final paint = Paint()
        ..color = palette[i % palette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false, paint);
      startAngle += sweep;
    }

    final holePaint = Paint()
      ..color = const Color(0xFF16193A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


