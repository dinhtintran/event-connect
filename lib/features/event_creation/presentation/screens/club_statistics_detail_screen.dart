import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/app_routes.dart';
import 'package:event_connect/features/authentication/authentication.dart';
import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';
import 'package:event_connect/features/event_creation/data/repositories/club_admin_repository.dart';
import 'package:event_connect/features/event_creation/domain/models/club_statistics_summary.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';

class ClubStatisticsDetailScreen extends StatefulWidget {
  final bool showBottomNav;

  const ClubStatisticsDetailScreen({super.key, this.showBottomNav = true});

  @override
  State<ClubStatisticsDetailScreen> createState() => _ClubStatisticsDetailScreenState();
}

class _ClubStatisticsDetailScreenState extends State<ClubStatisticsDetailScreen> {
  int _selectedIndex = 3; // Tab "Thống kê"
  bool _isLoading = false;
  String? _clubId;
  String? _errorMessage;
  int _rangeDays = 90;
  final List<int> _rangeOptions = [30, 60, 90, 180];
  ClubStatisticsSummary? _statistics;
  List<Event> _rawEvents = [];
  late final ClubAdminRepository _repository;
  late DateFormat _dateFormatter;
  late DateFormat _monthFormatter;

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
    _dateFormatter = DateFormat('dd MMM');
    _monthFormatter = DateFormat('MMM');
    _initLocaleData();
    _loadClubId();
  }

  Future<void> _initLocaleData() async {
    try {
      await initializeDateFormatting('vi');
      if (!mounted) return;
      setState(() {
        _dateFormatter = DateFormat('dd MMM', 'vi');
        _monthFormatter = DateFormat('MMM', 'vi');
      });
    } catch (error) {
      debugPrint('Failed to init vi locale: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: _primaryBlue),
        shape: Border(bottom: BorderSide(color: _borderColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thống kê chi tiết',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: _primaryBlue),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
          ),
          // Add NotificationBellWithBadge for club
          // Replace above IconButton with NotificationBellWithBadge if unread count logic is available
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              selectedItemColor: _primaryBlue,
              unselectedItemColor: _textSecondary,
              backgroundColor: _surfaceColor,
              showUnselectedLabels: true,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
                BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Sự Kiện'),
                BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Báo cáo'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Thống Kê'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Hồ Sơ'),
              ],
            )
          : null,
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

  Future<void> _loadData({bool showLoader = true}) async {
    final targetClubId = _clubId;
    if (targetClubId == null || targetClubId.isEmpty) {
      await _loadClubId();
      return;
    }

    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = null);
    }

    try {
      final statsFuture = _repository.getClubStatistics(
        targetClubId,
        rangeDays: _rangeDays,
        limitFeedback: 5,
        limitHighlights: 6,
      );
      final rawEventsFuture = _repository.getClubStatisticsRawEvents(
        targetClubId,
        rangeDays: _rangeDays,
        pageSize: 50,
      );

      final results = await Future.wait<dynamic>([statsFuture, rawEventsFuture]);
      final fetchedStats = results[0] as ClubStatisticsSummary;
      final fetchedEvents = List<Event>.from(results[1] as List<Event>);

      debugPrint('[ClubStatsDetail] monthly=${fetchedStats.monthlyAttendance}');
      debugPrint('[ClubStatsDetail] rawEvents=${fetchedEvents.length}');

      if (!mounted) return;
      setState(() {
        _statistics = fetchedStats;
        final events = fetchedEvents;
        events.sort((a, b) => b.startAt.compareTo(a.startAt));
        _rawEvents = events;
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

  Future<void> _loadClubId() async {
    final authService = context.read<AuthService>();
    final user = authService.user;
    if (user == null) {
      setState(() => _errorMessage = 'Bạn cần đăng nhập để xem thống kê.');
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

      await _loadData();
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

  void _onSelectRange(int days) {
    if (_rangeDays == days || _isLoading) return;
    setState(() => _rangeDays = days);
    _loadData();
  }

  Widget _buildBody() {
    if (_isLoading && _statistics == null) {
      return Center(child: CircularProgressIndicator(color: _primaryBlue));
    }

    final stats = _statistics ?? ClubStatisticsSummary.empty();
    final trendData = stats.monthlyAttendance.map((e) => e.toDouble()).toList();
    final completionData = _buildCompletionRates();
    final channelShare = _buildChannelShare();
    final insights = _generateInsights(stats);
    final hasData = stats.hasRealData || _rawEvents.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoader: false),
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
            _buildSectionTitle('Khoảng phân tích'),
            const SizedBox(height: 12),
            _buildRangeFilter(),
            const SizedBox(height: 20),
            if (!hasData)
              _buildEmptyState()
            else ...[
              _buildSectionTitle('Tổng quan nhanh'),
              const SizedBox(height: 12),
              _buildKpiRow(stats),
              const SizedBox(height: 20),
              _buildSectionTitle('Xu hướng tham dự'),
              const SizedBox(height: 12),
              _buildLineChart(trendData),
              const SizedBox(height: 20),
              _buildSectionTitle('Tiến độ hoàn thành sự kiện'),
              const SizedBox(height: 12),
              _buildBarChart(completionData),
              const SizedBox(height: 20),
              _buildSectionTitle('Nguồn đăng ký'),
              const SizedBox(height: 12),
              _buildDonutChart(channelShare),
              const SizedBox(height: 20),
              _buildSectionTitle('Bảng sự kiện thô'),
              const SizedBox(height: 12),
              _buildRawEventsTable(),
              const SizedBox(height: 20),
              _buildSectionTitle('Insight nhanh'),
              const SizedBox(height: 12),
              _buildInsightList(insights),
              const SizedBox(height: 32),
            ],
            _buildExportActions(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
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
            onPressed: () => _loadData(),
            style: TextButton.styleFrom(foregroundColor: _primaryBlue),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeFilter() {
    return Wrap(
      spacing: 10,
      children: _rangeOptions.map((days) {
        final selected = _rangeDays == days;
        return ChoiceChip(
          label: Text('$days ngày'),
          selected: selected,
          onSelected: (_) => _onSelectRange(days),
          selectedColor: _primaryBlue,
          backgroundColor: _chipBackground,
          side: BorderSide(color: selected ? _primaryBlue : _borderColor),
          labelStyle: TextStyle(
            color: selected ? Colors.white : _textSecondary,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, color: _primaryBlue),
          const SizedBox(height: 12),
          Text(
            'Chưa có dữ liệu thống kê',
            style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống sẽ tự động tổng hợp sau khi CLB có thêm sự kiện và người tham dự.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(ClubStatisticsSummary stats) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _KpiCard(
          label: 'Tổng tham dự',
          value: stats.totalParticipants.toString(),
          delta: _formatDelta(stats.participantsChange),
          positive: stats.participantsChange >= 0,
        ),
        _KpiCard(
          label: 'Tỷ lệ tham dự',
          value: '${stats.attendanceRate.toStringAsFixed(1)}% ',
          delta: _formatDelta(stats.attendanceChange),
          positive: stats.attendanceChange >= 0,
        ),
        _KpiCard(
          label: 'Sự kiện hoàn thành',
          value: stats.completedEvents.toString(),
          delta: _formatDelta(stats.eventsChange.toDouble(), suffix: ''),
          positive: stats.eventsChange >= 0,
        ),
        _KpiCard(
          label: 'Hài lòng',
          value: '${stats.satisfactionLevel.toStringAsFixed(1)}/5',
          delta: _formatDelta(stats.satisfactionChange),
          positive: stats.satisfactionChange >= 0,
        ),
      ],
    );
  }

  Widget _buildLineChart(List<double> data) {
    final hasData = data.isNotEmpty;
    final labels = _generateRecentMonthLabels(data.length);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (!hasData) {
                    return _buildChartPlaceholder('Chưa có dữ liệu xu hướng trong khoảng này.');
                  }
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _LineChartPainter(data),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(labels.length, (index) {
                return Expanded(
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<_CompletionRate> data) {
    final hasData = data.isNotEmpty;
    final values = data.map((e) => e.value).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (!hasData) {
                    return _buildChartPlaceholder('Chưa có dữ liệu hoàn thành sự kiện.');
                  }
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _BarChartPainter(values),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(data.length, (index) {
                return Expanded(
                  child: Text(
                    data[index].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart(Map<String, double> data) {
    final hasData = data.isNotEmpty && data.values.any((value) => value > 0);
    if (!hasData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardBox(),
        child: _buildChartPlaceholder('Chưa có dữ liệu nguồn đăng ký.'),
      );
    }

    final entries = data.entries.toList();
    final values = entries.map((e) => e.value).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _DonutChartPainter(values),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (index) {
                final entry = entries[index];
                final color = _DonutChartPainter.palette[index % _DonutChartPainter.palette.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(color: _textPrimary, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(0)}%',
                        style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRawEventsTable() {
    if (_rawEvents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardBox(),
        child: Text(
          'Chưa có dữ liệu sự kiện trong khoảng thời gian đã chọn.',
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    final events = _rawEvents.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(flex: 4, child: Text('Sự kiện', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Đăng ký', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Tham dự', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Tỷ lệ', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 12),
          ...events.map((event) => _buildEventRow(event)),
        ],
      ),
    );
  }

  Widget _buildEventRow(Event event) {
    final denominator = event.registrationCount > 0
        ? event.registrationCount
        : (event.capacity > 0 ? event.capacity : event.totalParticipants);
    final attendanceRate = denominator > 0 ? (event.attendedCount / denominator * 100).clamp(0, 100) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF111B4A), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateFormatter.format(event.startAt),
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              event.registrationCount.toString(),
              style: const TextStyle(color: Color(0xFF111B4A), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              event.attendedCount.toString(),
              style: const TextStyle(color: Color(0xFF111B4A), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${attendanceRate.toStringAsFixed(0)}%',
              style: TextStyle(
                color: attendanceRate >= 70 ? const Color(0xFF16A34A) : const Color(0xFFF97316),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightList(List<String> insights) {
    if (insights.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardBox(),
        child: Text(
          'Hệ thống chưa có đủ dữ liệu để đưa ra insight.',
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    return Column(
      children: insights
          .map((text) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: _cardBox(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.insights, color: _primaryBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(color: _textPrimary, fontSize: 13.5, height: 1.4),
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
        Text(
          'Hành động nhanh',
          style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
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

  String _formatDelta(double value, {String suffix = '%'}) {
    if (value == 0) return '0$suffix';
    final sign = value > 0 ? '+' : '';
    final formatted = value.abs() >= 1 ? value.toStringAsFixed(value % 1 == 0 ? 0 : 1) : value.toStringAsFixed(1);
    return '$sign$formatted$suffix';
  }

  List<_CompletionRate> _buildCompletionRates() {
    if (_rawEvents.isEmpty) return [];
    return _rawEvents
        .take(7)
        .map((event) {
          final denominator = event.registrationCount > 0
              ? event.registrationCount
              : (event.capacity > 0 ? event.capacity : event.totalParticipants);
          if (denominator <= 0) {
            return _CompletionRate(label: _shortenTitle(event.title), value: 0);
          }
          final rate = (event.attendedCount / denominator * 100).clamp(0, 100);
          return _CompletionRate(label: _shortenTitle(event.title), value: rate.round());
        })
        .toList();
  }

  Map<String, double> _buildChannelShare() {
    if (_rawEvents.isEmpty) return {};
    final distribution = <String, int>{};
    for (final event in _rawEvents) {
      final key = event.category.isNotEmpty ? event.category : 'Khác';
      final value = event.registrationCount > 0 ? event.registrationCount : event.totalParticipants;
      distribution[key] = (distribution[key] ?? 0) + value;
    }
    if (distribution.isEmpty) return {};

    final total = distribution.values.fold<int>(0, (prev, curr) => prev + curr);
    if (total == 0) return {};

    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sorted.take(3).toList();
    final others = sorted.skip(3).fold<int>(0, (prev, entry) => prev + entry.value);

    final Map<String, double> result = {
      for (final entry in topEntries) entry.key: (entry.value / total * 100),
    };
    if (others > 0) {
      result['Khác'] = (others / total * 100);
    }
    return result;
  }

  List<String> _generateInsights(ClubStatisticsSummary stats) {
    final insights = <String>[];

    if (stats.attendanceRate > 0) {
      final direction = stats.attendanceChange >= 0 ? 'tăng' : 'giảm';
      insights.add('Tỷ lệ tham dự trung bình đạt ${stats.attendanceRate.toStringAsFixed(1)}%, $direction ${stats.attendanceChange.abs().toStringAsFixed(1)} điểm so với kỳ trước.');
    }

    if (_rawEvents.isNotEmpty) {
      final bestEvent = _rawEvents.reduce((curr, next) => curr.attendedCount >= next.attendedCount ? curr : next);
      if (bestEvent.attendedCount > 0) {
        insights.add('Sự kiện "${bestEvent.title}" thu hút ${bestEvent.attendedCount} lượt tham dự – cao nhất trong $_rangeDays ngày.');
      }

      final avgNoShow = _calculateAverageNoShowRate();
      if (avgNoShow > 0) {
        insights.add('Tỷ lệ vắng mặt trung bình khoảng ${avgNoShow.toStringAsFixed(1)}%. Nên gửi nhắc lịch trước sự kiện để cải thiện.');
      }
    }

    final monthly = stats.monthlyAttendance;
    if (monthly.isNotEmpty) {
      final maxValue = monthly.reduce((a, b) => a > b ? a : b);
      if (maxValue > 0) {
        final index = monthly.lastIndexOf(maxValue);
        final monthDate = DateTime.now().subtract(Duration(days: 30 * (monthly.length - 1 - index)));
        final label = DateFormat('MM/yyyy').format(monthDate);
        insights.add('Tháng $label ghi nhận ${maxValue.toString()} lượt tham dự – cao nhất trong 6 tháng gần nhất.');
      }
    }

    if (insights.isEmpty) {
      insights.add('Hệ thống chưa có đủ dữ liệu để tạo insight. Hãy tiếp tục tổ chức sự kiện và thu thập phản hồi.');
    }

    return insights;
  }

  double _calculateAverageNoShowRate() {
    double total = 0;
    int counted = 0;
    for (final event in _rawEvents) {
      final base = event.registrationCount > 0
          ? event.registrationCount
          : (event.totalParticipants > 0 ? event.totalParticipants : event.capacity);
      if (base <= 0) continue;
      final attended = event.attendedCount.clamp(0, base);
      final rate = (1 - attended / base) * 100;
      total += rate;
      counted++;
    }
    if (counted == 0) return 0;
    return total / counted;
  }

  Widget _buildChartPlaceholder(String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: _textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
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
          backgroundColor: _primaryBlue,
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
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  List<String> _generateRecentMonthLabels(int count) {
    if (count == 0) return const [];
    final now = DateTime.now();
    return List.generate(count, (index) {
      final monthDate = DateTime(now.year, now.month - (count - 1 - index));
      return _monthFormatter.format(monthDate);
    });
  }

  String _shortenTitle(String title) {
    const maxLen = 12;
    if (title.length <= maxLen) return title;
    return '${title.substring(0, maxLen - 1)}…';
  }
}

class _CompletionRate {
  final String label;
  final int value;

  const _CompletionRate({required this.label, required this.value});
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E6F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: positive
                      ? const Color(0xFFE2F5E8)
                      : const Color(0xFFFFE8E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  delta,
                  style: TextStyle(
                    color: positive ? const Color(0xFF16803C) : const Color(0xFFC24122),
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
              color: Color(0xFF111B4A),
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
    if (data.isEmpty) return;
    if (data.length == 1) {
      final paintPoint = Paint()
        ..color = const Color(0xFF2F5BFF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 6, paintPoint);
      return;
    }

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs() < 1 ? 1 : maxVal - minVal;

    final paintLine = Paint()
      ..color = const Color(0xFF2F5BFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..color = const Color(0xFF6A8CFF).withValues(alpha: 0.2)
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
    if (data.isEmpty) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final divisor = maxVal == 0 ? 1 : maxVal;
    final barWidth = size.width / (data.length * 1.6);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2F5BFF), Color(0xFF6A8CFF)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      final barHeight = (value / divisor) * (size.height * 0.9);
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
    Color(0xFF2F5BFF),
    Color(0xFF00C49A),
    Color(0xFFFF7E67),
    Color(0xFF4FC3F7),
  ];

  _DonutChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final total = values.fold<double>(0, (p, c) => p + c);
    if (total <= 0) return;
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
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


