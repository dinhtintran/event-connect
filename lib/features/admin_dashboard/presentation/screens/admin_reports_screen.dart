import 'package:event_connect/features/admin_dashboard/presentation/widgets/notification_bell_admin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:event_connect/features/admin_dashboard/domain/models/admin_stats.dart';
import 'package:event_connect/features/admin_dashboard/domain/services/admin_service.dart';
import 'package:event_connect/features/admin_dashboard/presentation/widgets/stat_card.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  static const _ranges = [
    ('today', 'Hôm nay'),
    ('week', '7 ngày'),
    ('month', '30 ngày'),
    ('quarter', 'Quý'),
  ];

  final NumberFormat _numberFormat = NumberFormat.compact(locale: 'vi');
  String _selectedRange = 'week';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    final service = context.read<AdminService>();
    await service.fetchStats(period: _selectedRange);
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _onRangeSelected(String range) {
    if (_selectedRange == range) return;
    setState(() => _selectedRange = range);
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminService>(
      builder: (context, adminService, _) {
        final stats = adminService.stats;
        final hasError = adminService.error != null;
        final isInitialLoading = adminService.isLoading && stats == null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Báo cáo & Thống kê'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xuất báo cáo sẽ có sau khi backend sẵn sàng.')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadStats,
              ),
              NotificationBellAdmin(iconColor: Colors.black),
            ],
          ),
          body: isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      _buildFilterRow(),
                      if (_isRefreshing) const SizedBox(height: 8),
                      if (_isRefreshing)
                        const LinearProgressIndicator(minHeight: 2),
                      if (hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _ErrorBanner(
                            message: adminService.error!,
                            onRetry: _loadStats,
                          ),
                        ),
                      if (stats != null) ...[
                        const SizedBox(height: 16),
                        _buildOverview(stats),
                        const SizedBox(height: 24),
                        _buildEventsSection(stats.events),
                        const SizedBox(height: 24),
                        _buildRecentActivity(stats.recentActivity),
                        const SizedBox(height: 24),
                        _buildTopEvents(stats.topEvents),
                        const SizedBox(height: 24),
                        _buildTopClubs(stats.topClubs),
                        const SizedBox(height: 24),
                        _buildAlertPlaceholder(),
                      ] else if (!hasError)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text(
                              'Chưa có dữ liệu báo cáo cho bộ lọc hiện tại.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _ranges.map((tuple) {
          final value = tuple.$1;
          final label = tuple.$2;
          final isSelected = value == _selectedRange;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => _onRangeSelected(value),
              selectedColor: const Color(0xFFEEF2FF),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF4F46E5) : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverview(AdminStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Tổng quan hệ thống'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            StatCard(
              icon: Icons.event_available_outlined,
              label: 'Tổng sự kiện',
              value: _formatNumber(stats.overview.totalEvents),
              backgroundColor: Colors.blue,
              iconColor: Colors.blue,
            ),
            StatCard(
              icon: Icons.people_alt_outlined,
              label: 'Tổng người dùng',
              value: _formatNumber(stats.overview.totalUsers),
              backgroundColor: Colors.orange,
              iconColor: Colors.orange,
            ),
            StatCard(
              icon: Icons.groups_2_outlined,
              label: 'Tổng CLB',
              value: _formatNumber(stats.overview.totalClubs),
              backgroundColor: Colors.purple,
              iconColor: Colors.purple,
            ),
            StatCard(
              icon: Icons.how_to_reg_outlined,
              label: 'Đăng ký',
              value: _formatNumber(stats.overview.totalRegistrations),
              backgroundColor: Colors.green,
              iconColor: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventsSection(EventsByStatus events) {
    final statuses = [
      _StatusBreakdown('Đang chờ', events.pending, Colors.orange),
      _StatusBreakdown('Đã duyệt', events.approved, Colors.green),
      _StatusBreakdown('Đang diễn ra', events.ongoing, Colors.blue),
      _StatusBreakdown('Hoàn tất', events.completed, Colors.grey.shade700),
    ];
    final total = statuses.fold<int>(0, (sum, item) => sum + item.value);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Trạng thái sự kiện'),
            const SizedBox(height: 16),
            ...statuses.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StatusRow(
                    label: item.label,
                    value: item.value,
                    total: total,
                    color: item.color,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(RecentActivity activity) {
    final metrics = [
      _ActivityMetric(
        icon: Icons.campaign_outlined,
        label: 'Sự kiện mới tuần này',
        value: _formatNumber(activity.newEventsThisWeek),
        color: Colors.indigo,
      ),
      _ActivityMetric(
        icon: Icons.person_add_alt,
        label: 'Người dùng mới',
        value: _formatNumber(activity.newUsersThisWeek),
        color: Colors.teal,
      ),
      _ActivityMetric(
        icon: Icons.badge_outlined,
        label: 'Lượt đăng ký',
        value: _formatNumber(activity.registrationsThisWeek),
        color: Colors.pink,
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: metrics
            .map((metric) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: metric.color.withValues(alpha: 0.15),
                    child: Icon(metric.icon, color: metric.color),
                  ),
                  title: Text(metric.label),
                  trailing: Text(
                    metric.value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTopEvents(List<TopEvent> events) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Sự kiện nổi bật',
              actionLabel: events.isNotEmpty ? 'Xem tất cả' : null,
              onActionTap: events.isNotEmpty
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Danh sách chi tiết sẽ mở khi thiết kế hoàn tất.')),
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              const _EmptySectionPlaceholder(message: 'Chưa có sự kiện nào đạt KPI được đặt.')
            else
              ...events.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final event = entry.value;
                return _RankedTile(
                  rank: index,
                  title: event.title,
                  subtitle: '${_formatNumber(event.registrationCount)} lượt đăng ký • ⭐ ${event.averageRating.toStringAsFixed(1)}',
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClubs(List<TopClub> clubs) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'CLB hoạt động mạnh',
              actionLabel: clubs.isNotEmpty ? 'So sánh' : null,
              onActionTap: clubs.isNotEmpty
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chức năng so sánh sẽ xuất hiện sau.')),
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            if (clubs.isEmpty)
              const _EmptySectionPlaceholder(message: 'CLB chưa đạt chỉ số tối thiểu để xếp hạng.')
            else
              ...clubs.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final club = entry.value;
                return _RankedTile(
                  rank: index,
                  title: club.name,
                  subtitle: '${_formatNumber(club.eventCount)} sự kiện • ${_formatNumber(club.memberCount)} thành viên',
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertPlaceholder() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFFBEB),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_outlined, color: Color(0xFFF59E0B)),
        title: const Text('Cảnh báo & SLA'),
        subtitle: const Text(
          'Cảnh báo thời gian thực sẽ hiển thị khi backend cung cấp endpoint `/api/admin/reports/alerts`.',
        ),
        trailing: TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đang chờ kết nối API alerts.')),
            );
          },
          child: const Text('Chi tiết'),
        ),
      ),
    );
  }

  String _formatNumber(num value) => _numberFormat.format(value);
}

class _StatusBreakdown {
  final String label;
  final int value;
  final Color color;

  const _StatusBreakdown(this.label, this.value, this.color);
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActivityMetric {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ActivityMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _RankedTile extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;

  const _RankedTile({
    required this.rank,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEEF2FF),
            foregroundColor: const Color(0xFF4C1D95),
            child: Text(rank.toString()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _EmptySectionPlaceholder extends StatelessWidget {
  final String message;

  const _EmptySectionPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7F1D1D)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}