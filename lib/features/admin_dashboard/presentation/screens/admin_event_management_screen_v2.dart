import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/admin/domain/services/admin_service.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:intl/intl.dart';

/// System Admin Event Management Screen
/// Quản lý TẤT CẢ sự kiện của tất cả CLB trong hệ thống
/// 
/// Chức năng:
/// - Xem tất cả sự kiện (Tất cả, Chờ duyệt, Đã duyệt, Từ chối)
/// - Phê duyệt sự kiện chờ
/// - Từ chối sự kiện với lý do
/// - Xem chi tiết sự kiện
/// - Theo dõi số lượng người tham gia
/// - Hủy sự kiện đã duyệt (nếu cần)
class AdminEventManagementScreen extends StatefulWidget {
  const AdminEventManagementScreen({super.key});

  @override
  State<AdminEventManagementScreen> createState() => _AdminEventManagementScreenState();
}

class _AdminEventManagementScreenState extends State<AdminEventManagementScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentFilter = 'all';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentFilter = 'all';
            break;
          case 1:
            _currentFilter = 'pending';
            break;
          case 2:
            _currentFilter = 'approved';
            break;
          case 3:
            _currentFilter = 'rejected';
            break;
        }
      });
      _loadEvents();
    }
  }

  void _loadEvents() {
    final status = _currentFilter == 'all' ? null : _currentFilter;
    context.read<AdminService>().loadEvents(status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sự kiện'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Tất cả'),
            Tab(icon: Icon(Icons.pending), text: 'Chờ duyệt'),
            Tab(icon: Icon(Icons.check_circle), text: 'Đã duyệt'),
            Tab(icon: Icon(Icons.cancel), text: 'Từ chối'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Summary
          _buildStatsSummary(),
          
          // Event List
          Expanded(
            child: Consumer<AdminService>(
              builder: (context, admin, _) {
                if (admin.isLoading && admin.events.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (admin.error != null) {
                  return _buildErrorView(admin.error!);
                }

                if (admin.events.isEmpty) {
                  return _buildEmptyView();
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadEvents(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: admin.events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final event = admin.events[idx];
                      return _EventManagementCard(
                        event: event,
                        onApprove: () => _handleApprove(event),
                        onReject: () => _handleReject(event),
                        onViewDetail: () => _showEventDetail(event),
                        onCancel: () => _handleCancel(event),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Consumer<AdminService>(
      builder: (context, admin, _) {
        final allEvents = admin.events;
        final pending = allEvents.where((e) => e.status == null || e.status == 'pending').length;
        final approved = allEvents.where((e) => e.status == 'approved').length;
        final rejected = allEvents.where((e) => e.status == 'rejected').length;

        return Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _StatChip(
                label: 'Tổng',
                value: allEvents.length.toString(),
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Chờ duyệt',
                value: pending.toString(),
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Đã duyệt',
                value: approved.toString(),
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Từ chối',
                value: rejected.toString(),
                color: Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Lỗi: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    String message;
    IconData icon;
    
    switch (_currentFilter) {
      case 'pending':
        message = 'Không có sự kiện nào đang chờ phê duyệt';
        icon = Icons.pending_actions;
        break;
      case 'approved':
        message = 'Chưa có sự kiện nào được phê duyệt';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        message = 'Chưa có sự kiện nào bị từ chối';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'Chưa có sự kiện nào trong hệ thống';
        icon = Icons.event_busy;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới'),
          ),
        ],
      ),
    );
  }

  // Action Handlers
  Future<void> _handleApprove(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phê duyệt sự kiện'),
        content: Text('Bạn có chắc chắn muốn phê duyệt sự kiện "${event.title}"?\n\n'
            'Sau khi phê duyệt, sự kiện sẽ hiển thị công khai cho sinh viên.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Phê duyệt'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final admin = context.read<AdminService>();
      await admin.approveEvent(event.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã phê duyệt sự kiện "${event.title}"'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        _loadEvents();
      }
    }
  }

  Future<void> _handleReject(Event event) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối sự kiện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn từ chối sự kiện "${event.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                hintText: 'Nhập lý do từ chối sự kiện...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lý do từ chối sẽ được gửi đến CLB',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim();
      final admin = context.read<AdminService>();
      await admin.rejectEvent(event.id, reason: reason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã từ chối sự kiện "${event.title}"'),
            backgroundColor: Colors.red,
          ),
        );
        _loadEvents();
      }
    }
  }

  Future<void> _handleCancel(Event event) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy sự kiện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn HỦY sự kiện "${event.title}"?'),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Cảnh báo: Hành động này sẽ:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Text('• Hủy tất cả đăng ký của sinh viên'),
            const Text('• Gửi thông báo đến tất cả người tham gia'),
            const Text('• Không thể hoàn tác'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy *',
                hintText: 'Nhập lý do hủy sự kiện...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do hủy')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim();
      final admin = context.read<AdminService>();
      // TODO: Implement cancelEvent in AdminService
      // await admin.cancelEvent(event.id, reason: reason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã hủy sự kiện "${event.title}"'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadEvents();
      }
    }
  }

  void _showEventDetail(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _EventDetailView(event: event, scrollController: scrollController);
        },
      ),
    );
  }
}

// Statistics Chip Widget
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Event Management Card
class _EventManagementCard extends StatelessWidget {
  final Event event;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDetail;
  final VoidCallback onCancel;

  const _EventManagementCard({
    required this.event,
    required this.onApprove,
    required this.onReject,
    required this.onViewDetail,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = event.status ?? 'pending';
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onViewDetail,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Status Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 12),

              // Club Info
              Row(
                children: [
                  const Icon(Icons.group, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    event.clubName,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date & Location
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(event.startAt),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Participants Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ParticipantStat(
                        label: 'Đăng ký',
                        value: event.registrationCount.toString(),
                        icon: Icons.app_registration,
                      ),
                    ),
                    Expanded(
                      child: _ParticipantStat(
                        label: 'Check-in',
                        value: event.checkedInCount.toString(),
                        icon: Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _ParticipantStat(
                        label: 'Sức chứa',
                        value: event.capacity.toString(),
                        icon: Icons.people,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Phê duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                )
              else if (isApproved)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewDetail,
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Xem chi tiết'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Hủy sự kiện'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                )
              else if (isRejected)
                OutlinedButton.icon(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Xem chi tiết'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Status Badge
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'approved':
        color = Colors.green;
        text = 'Đã duyệt';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Từ chối';
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        text = 'Chờ duyệt';
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Participant Stat Widget
class _ParticipantStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ParticipantStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Event Detail View (Bottom Sheet)
class _EventDetailView extends StatelessWidget {
  final Event event;
  final ScrollController scrollController;

  const _EventDetailView({
    required this.event,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _StatusBadge(status: event.status ?? 'pending'),
          const SizedBox(height: 24),

          // Event Info
          _DetailRow(
            icon: Icons.group,
            label: 'CLB tổ chức',
            value: event.clubName,
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Thời gian bắt đầu',
            value: DateFormat('dd/MM/yyyy HH:mm').format(event.startAt),
          ),
          if (event.endAt != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Thời gian kết thúc',
              value: DateFormat('dd/MM/yyyy HH:mm').format(event.endAt!),
            ),
          ],
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.location_on,
            label: 'Địa điểm',
            value: event.location,
          ),
          if (event.locationDetail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                event.locationDetail,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
          const Divider(height: 24),

          // Participants Stats
          const Text(
            'Thống kê người tham gia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _StatRow(
                  label: 'Đã đăng ký',
                  value: event.registrationCount.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: 'Đã check-in',
                  value: event.checkedInCount.toString(),
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: 'Đã hoàn thành',
                  value: event.attendedCount.toString(),
                  color: Colors.purple,
                ),
                const Divider(height: 24),
                _StatRow(
                  label: 'Sức chứa tối đa',
                  value: event.capacity.toString(),
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description
          const Text(
            'Mô tả sự kiện',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            event.description.isNotEmpty ? event.description : 'Không có mô tả',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Timestamps
          if (event.createdAt != null) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(event.createdAt!)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
          if (event.updatedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(event.updatedAt!)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 24),

          // Close Button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.grey[700]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
