import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/app_routes.dart';
import 'package:event_connect/features/authentication/authentication.dart';
import 'package:event_connect/features/event_creation/data/repositories/club_admin_repository.dart';
import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';
import 'package:event_connect/features/event_creation/domain/models/club_statistics_summary.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ClubStatisticsScreen extends StatefulWidget {
  const ClubStatisticsScreen({super.key});

  @override
  State<ClubStatisticsScreen> createState() => _ClubStatisticsScreenState();
}

class _ClubStatisticsScreenState extends State<ClubStatisticsScreen> {
  int _selectedIndex = 3; // Tab "Thống kê"
  bool _isLoading = false;
  String? _clubId;
  String? _errorMessage;
  ClubStatisticsSummary? _statistics;
  late final ClubAdminRepository _repository;
  late final DateFormat _fallbackMonthFormatter;
  DateFormat? _viMonthFormatter;

  static const Color _primaryBlue = Color(0xFF2F5BFF);
  static const Color _secondaryBlue = Color(0xFF6A8CFF);
  static const Color _textPrimary = Color(0xFF111B4A);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _borderColor = Color(0xFFE1E6F7);
  static const Color _chipBackground = Color(0xFFEFF3FF);

  @override
  void initState() {
    super.initState();
    _repository = ClubAdminRepository(api: ClubAdminApi());
    _fallbackMonthFormatter = DateFormat.MMM();
    _initLocaleData();
    _loadClubId();
  }

  Future<void> _initLocaleData() async {
    try {
      await initializeDateFormatting('vi');
      if (!mounted) return;
      setState(() {
        _viMonthFormatter = DateFormat.MMM('vi');
      });
    } catch (error) {
      debugPrint('Failed to init vi locale: $error');
    }
  }

  Future<void> _loadClubId() async {
    final authService = context.read<AuthService>();
    final user = authService.user;
    
    if (user == null) {
      setState(() {
        _errorMessage = 'Bạn cần đăng nhập để xem thống kê CLB.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clubId = await _repository.getCurrentClubId();
      if (!mounted) return;

      setState(() {
        _clubId = clubId;
      });

      await _loadStatistics(overrideClubId: clubId);
    } on ClubNotAssignedException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } on ClubAssignmentException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics({String? overrideClubId}) async {
    final targetClubId = overrideClubId ?? _clubId;
    if (targetClubId == null || targetClubId.isEmpty) {
      setState(() {
        _errorMessage = 'Không tìm thấy mã CLB để tải thống kê.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _repository.getClubStatistics(targetClubId);
      if (!mounted) return;
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
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
      backgroundColor: _surfaceColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            border: const Border(bottom: BorderSide(color: _borderColor)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
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
                      children: [
                        Text(
                          'Báo cáo sự kiện',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tổng quan hiệu suất & mức độ hài lòng',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_none, color: _primaryBlue),
                    onPressed: () {},
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _chipBackground,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/beongnho2.jpg',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Icon(Icons.person, size: 18, color: _primaryBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: _textSecondary,
        backgroundColor: _surfaceColor,
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

  Widget _buildBody() {
    if (_isLoading && _statistics == null) {
      return Center(child: CircularProgressIndicator(color: _primaryBlue));
    }

    final stats = _statistics ?? ClubStatisticsSummary.empty();
    final hasData = stats.hasRealData;

    return RefreshIndicator(
      onRefresh: () => _loadStatistics(),
      color: _primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              _buildErrorBanner(_errorMessage!),
              const SizedBox(height: 16),
            ],
            _buildHeroSummary(stats),
            const SizedBox(height: 18),
            if (!hasData)
              _buildEmptyState()
            else ...[
              _buildStatisticsOverview(stats),
              const SizedBox(height: 20),
              _buildMonthlyAttendanceChart(stats.monthlyAttendance),
              const SizedBox(height: 20),
              _buildAcademicYearChart(stats.academicYearDistribution),
              const SizedBox(height: 20),
              _buildRecentFeedback(stats.recentFeedbacks),
              const SizedBox(height: 20),
              _buildEventHighlights(stats.eventHighlights),
              const SizedBox(height: 20),
            ],
            _buildExportReport(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => _loadStatistics(),
            style: TextButton.styleFrom(foregroundColor: _primaryBlue),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Chưa có dữ liệu thống kê',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Hệ thống sẽ tự động tổng hợp số liệu sau khi CLB có sự kiện hoặc người tham dự đầu tiên.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _loadStatistics(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _primaryBlue),
              foregroundColor: _primaryBlue,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử tải lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsOverview(ClubStatisticsSummary stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tổng quan thống kê',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.clubStatisticsDetail),
              style: TextButton.styleFrom(foregroundColor: _primaryBlue),
              child: const Text(
                'Xem chi tiết',
                style: TextStyle(fontWeight: FontWeight.w600),
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
                change: stats.participantsChange,
                value: _formatParticipants(stats.totalParticipants),
                label: 'Tổng số người tham dự',
                isPositive: stats.participantsChange >= 0,
                sparkline: stats.monthlyAttendance.map((e) => e.toDouble()).toList(),
              ),
              _buildStatCard(
                icon: Icons.check_circle,
                change: stats.attendanceChange,
                value: '${stats.attendanceRate.toStringAsFixed(1)}%',
                label: 'Tỷ lệ tham dự',
                isPositive: stats.attendanceChange >= 0,
                sparkline: stats.monthlyAttendance.map((e) => e.toDouble()).toList(),
              ),
              _buildStatCard(
                icon: Icons.calendar_today,
                change: stats.eventsChange.toDouble(),
                value: stats.completedEvents.toString(),
                label: 'Sự kiện đã hoàn thành',
                isPositive: stats.eventsChange >= 0,
                changeSuffix: '',
                sparkline: stats.monthlyAttendance.map((e) => e.toDouble()).toList(),
              ),
              _buildStatCard(
                icon: Icons.favorite,
                change: stats.satisfactionChange,
                value: '${stats.satisfactionLevel.toStringAsFixed(1)}/5',
                label: 'Mức độ hài lòng',
                isPositive: stats.satisfactionChange >= 0,
                sparkline: List<double>.filled(
                  stats.monthlyAttendance.length,
                  stats.satisfactionLevel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatParticipants(int value) {
    return NumberFormat.compact(locale: 'vi').format(value);
  }

  String _formatDelta(double value, {String suffix = '%'}) {
    if (value == 0) return '0$suffix';
    final decimals = value.abs() >= 10 ? 0 : 1;
    final formatted = value.toStringAsFixed(decimals);
    final sign = value > 0 ? '+' : '';
    return '$sign$formatted$suffix';
  }

  Widget _buildHeroSummary(ClubStatisticsSummary stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hiệu suất tổng quan',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildHeroChip(
                      Icons.trending_up,
                      '${_formatDelta(stats.participantsChange)} tham dự',
                    ),
                    const SizedBox(width: 8),
                    _buildHeroChip(
                      Icons.emoji_events_outlined,
                      '${stats.satisfactionLevel.toStringAsFixed(1)}/5 hài lòng',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${stats.completedEvents} sự kiện hoàn thành · ${stats.attendanceRate.toStringAsFixed(1)}% tỷ lệ tham dự',
                  style: TextStyle(
                    color: _textSecondary,
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
              color: _chipBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bar_chart_rounded, color: _primaryBlue, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _chipBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _primaryBlue, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _primaryBlue,
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
    String changeSuffix = '%',
    List<double>? sparkline,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: _chipBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _primaryBlue, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${change == 0 ? '' : (change > 0 ? '+' : '')}${change.toStringAsFixed(change % 1 == 0 ? 0 : 1)}$changeSuffix',
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
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

  Widget _buildMonthlyAttendanceChart(List<int> series) {
    if (series.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = max(series.reduce(max), 1).toDouble();
    final chartHeight = 200.0;
    final now = DateTime.now();
    final monthLabels = List<String>.generate(series.length, (index) {
      final monthDate = DateTime(now.year, now.month - (series.length - 1 - index));
      return _formatMonth(monthDate);
    });
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Xu hướng tham dự theo tháng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _chipBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 14, color: _primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      '6 tháng gần đây',
                      style: TextStyle(
                        fontSize: 12,
                        color: _primaryBlue,
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
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(series.length, (index) {
                final value = series[index];
                final height = (value / maxValue) * (chartHeight - 40);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryBlue, _secondaryBlue],
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

  String _formatMonth(DateTime date) {
    try {
      final formatter = _viMonthFormatter;
      if (formatter != null) return formatter.format(date);
    } catch (_) {
      // fallback below
    }
    return _fallbackMonthFormatter.format(date);
  }

  Widget _buildAcademicYearChart(Map<String, int> distribution) {
    final total = distribution.values.fold<int>(0, (sum, val) => sum + val);
    final colors = [
      const Color(0xFF5568FF),
      const Color(0xFF00C49A),
      const Color(0xFFFF7E67),
      const Color(0xFF4FC3F7),
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bố đăng ký theo năm học',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tỷ lệ sinh viên theo từng năm học đã đăng ký.',
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
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
                    data: distribution.values.toList(),
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(distribution.length, (index) {
                    final entry = distribution.entries.toList()[index];
                    final color = colors[index % colors.length];
                    final percentage = total == 0
                        ? '0'
                        : (entry.value / total * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.rectangle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sinh viên ${entry.key}',
                              style: TextStyle(fontSize: 13, color: _textPrimary),
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
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

  Widget _buildRecentFeedback(List<ClubFeedbackSummary> feedbacks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phản hồi gần đây',
          style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (feedbacks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              'Chưa có phản hồi đủ dữ liệu.',
              style: TextStyle(color: _textSecondary),
            ),
          )
        else ...feedbacks.map(
          (feedback) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: _buildFeedbackAvatar(feedback.avatarUrl),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 16,
                            color: index < feedback.rating.round()
                                ? Colors.amber
                                : Colors.grey.shade300,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feedback.comment,
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventHighlights(List<ClubHighlightSummary> highlights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Điểm nhấn sự kiện',
              style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Navigate to all highlights
              },
              child: Text(
                'Xem tất cả',
                style: TextStyle(
                  color: _primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (highlights.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              'Chưa có hình ảnh nổi bật.',
              style: TextStyle(color: _textSecondary),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: highlights.map((highlight) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildHighlightImage(highlight.posterUrl),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Text(
                        highlight.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFeedbackAvatar(String avatarUrl) {
    if (avatarUrl.isEmpty) {
      return Image.asset(
        'assets/images/beongnho2.jpg',
        fit: BoxFit.cover,
      );
    }
    if (avatarUrl.startsWith('http')) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/beongnho2.jpg', fit: BoxFit.cover);
        },
      );
    }
    return Image.asset(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset('assets/images/beongnho2.jpg', fit: BoxFit.cover);
      },
    );
  }

  Widget _buildHighlightImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.image, size: 48),
        ),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, st) => Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, size: 48),
      ),
    );
  }

  Widget _buildExportReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xuất báo cáo',
          style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
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
          backgroundColor: _primaryBlue,
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
    final total = data.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
      return;
    }
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
      ..color = const Color(0xFF2F5BFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF2F5BFF).withValues(alpha: 0.15)
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

