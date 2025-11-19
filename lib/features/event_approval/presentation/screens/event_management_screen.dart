import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/event_creation/domain/models/event_cancellation_request.dart';
import 'package:event_connect/features/event_approval/domain/models/event_approval.dart';
import 'package:event_connect/features/event_approval/presentation/widgets/approval_event_card.dart';
import 'package:event_connect/features/authentication/domain/services/auth_service.dart';
import 'package:event_connect/features/admin/domain/services/admin_service.dart';
import 'package:event_connect/core/widgets/app_nav_bar.dart';
import 'package:event_connect/app_routes.dart';

/// Event Management Screen - Quản lý tất cả sự kiện cho System Admin
/// Bao gồm 3 tabs: Pending Approval, Approved Events, Cancellation Requests
class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedNavIndex = 1; // Event Management tab is selected

  // Pending Approval Tab
  bool _isLoadingPending = true;
  List<EventApproval> _pendingApprovals = [];

  // Approved Events Tab
  bool _isLoadingApproved = true;
  List<Event> _approvedEvents = [];

  // Cancellation Requests Tab
  bool _isLoadingCancellations = true;
  List<EventCancellationRequest> _cancellationRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadPendingEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;

    switch (_tabController.index) {
      case 0:
        _loadPendingEvents();
        break;
      case 1:
        _loadApprovedEvents();
        break;
      case 2:
        _loadCancellationRequests();
        break;
    }
  }

  // ==================== PENDING APPROVAL TAB ====================

  Future<void> _loadPendingEvents() async {
    setState(() => _isLoadingPending = true);

    final adminService = Provider.of<AdminService>(context, listen: false);
    final response = await adminService.fetchPendingApprovals();

    if (response['status'] == 200 && mounted) {
      final results = response['body']['results'] as List<dynamic>;
      setState(() {
        _pendingApprovals = results
            .map((json) => EventApproval.fromJson(json as Map<String, dynamic>))
            .toList();
        _isLoadingPending = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingPending = false);
      _showErrorSnackBar('Không thể tải danh sách sự kiện chờ duyệt');
    }
  }

  Future<void> _handleApprove(EventApproval approval) async {
    final commentController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận phê duyệt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sự kiện: "${approval.event.title}"'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'Nhập ghi chú về việc phê duyệt...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
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

    if (confirmed != true || !mounted) return;

    final adminService = Provider.of<AdminService>(context, listen: false);
    final success = await adminService.approveEvent(
      approval.id.toString(),  // ✅ Dùng approval.id thay vì event.id
      comment: commentController.text.trim().isEmpty 
          ? null 
          : commentController.text.trim(),
    );

    if (success && mounted) {
      _showSuccessSnackBar('Đã phê duyệt sự kiện "${approval.event.title}"');
      _loadPendingEvents();
    } else if (mounted) {
      _showErrorSnackBar('Không thể phê duyệt sự kiện');
    }
  }

  Future<void> _handleReject(EventApproval approval) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối sự kiện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sự kiện: "${approval.event.title}"'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                hintText: 'Nhập lý do từ chối sự kiện...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do từ chối'),
                    backgroundColor: Colors.orange,
                  ),
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

    if (confirmed != true || !mounted) return;

    final adminService = Provider.of<AdminService>(context, listen: false);
    final success = await adminService.rejectEvent(
      approval.id.toString(),  // ✅ Dùng approval.id thay vì event.id
      reason: reasonController.text.trim(),
    );

    if (success && mounted) {
      _showSuccessSnackBar('Đã từ chối sự kiện "${approval.event.title}"');
      _loadPendingEvents();
    } else if (mounted) {
      _showErrorSnackBar('Không thể từ chối sự kiện');
    }
  }

  // ==================== APPROVED EVENTS TAB ====================

  Future<void> _loadApprovedEvents() async {
    if (!_isLoadingApproved && _approvedEvents.isNotEmpty) return;

    setState(() => _isLoadingApproved = true);

    final adminService = Provider.of<AdminService>(context, listen: false);
    final response = await adminService.fetchApprovedEvents();

    if (response['status'] == 200 && mounted) {
      final results = response['body']['results'] as List<dynamic>;
      setState(() {
        _approvedEvents = results
            .map((json) => Event.fromJson(json as Map<String, dynamic>))
            .toList();
        _isLoadingApproved = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingApproved = false);
      _showErrorSnackBar('Không thể tải danh sách sự kiện đã duyệt');
    }
  }

  // ==================== CANCELLATION REQUESTS TAB ====================

  Future<void> _loadCancellationRequests() async {
    if (!_isLoadingCancellations && _cancellationRequests.isNotEmpty) return;

    setState(() => _isLoadingCancellations = true);

    final adminService = Provider.of<AdminService>(context, listen: false);
    final response = await adminService.fetchPendingCancellationRequests();

    if (response['status'] == 200 && mounted) {
      // Backend có thể trả về List hoặc Map với 'results' key
      final body = response['body'];
      final List<dynamic> results;
      
      if (body is List) {
        results = body;
      } else if (body is Map && body.containsKey('results')) {
        results = body['results'] as List<dynamic>;
      } else {
        results = [];
      }
      
      setState(() {
        _cancellationRequests = results
            .map((json) =>
                EventCancellationRequest.fromJson(json as Map<String, dynamic>))
            .toList();
        _isLoadingCancellations = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingCancellations = false);
      _showErrorSnackBar('Không thể tải danh sách yêu cầu hủy');
    }
  }

  Future<void> _handleApproveCancellation(EventCancellationRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận phê duyệt'),
        content: Text(
            'Bạn có chắc chắn muốn phê duyệt yêu cầu hủy sự kiện "${request.event.title}"?'),
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

    if (confirmed != true || !mounted) return;

    final adminService = Provider.of<AdminService>(context, listen: false);
    final success = await adminService.reviewCancellationRequest(
      requestId: request.id,
      action: 'approve',
    );

    if (success && mounted) {
      _showSuccessSnackBar('Đã phê duyệt yêu cầu hủy sự kiện');
      _loadCancellationRequests();
    } else if (mounted) {
      _showErrorSnackBar('Không thể phê duyệt yêu cầu hủy');
    }
  }

  Future<void> _handleRejectCancellation(EventCancellationRequest request) async {
    final commentController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu hủy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sự kiện: "${request.event.title}"'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối',
                hintText: 'Nhập lý do từ chối yêu cầu hủy...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do từ chối'),
                    backgroundColor: Colors.orange,
                  ),
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

    if (confirmed != true || !mounted) return;

    final adminService = Provider.of<AdminService>(context, listen: false);
    final success = await adminService.reviewCancellationRequest(
      requestId: request.id,
      action: 'reject',
      adminComment: commentController.text.trim(),
    );

    if (success && mounted) {
      _showSuccessSnackBar('Đã từ chối yêu cầu hủy sự kiện');
      _loadCancellationRequests();
    } else if (mounted) {
      _showErrorSnackBar('Không thể từ chối yêu cầu hủy');
    }
  }

  // ==================== UI HELPERS ====================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedNavIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.admin);
        break;
      case 1:
        // Current screen
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.profile);
        break;
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthService>(context, listen: false).logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sự kiện'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Đăng xuất',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chờ duyệt', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Đã duyệt', icon: Icon(Icons.check_circle)),
            Tab(text: 'Yêu cầu hủy', icon: Icon(Icons.cancel_presentation)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildApprovedTab(),
          _buildCancellationTab(),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

  // ==================== TAB BUILDERS ====================

  Widget _buildPendingTab() {
    if (_isLoadingPending) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingApprovals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có sự kiện chờ duyệt',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingApprovals.length,
        itemBuilder: (context, index) {
          final approval = _pendingApprovals[index];
          return ApprovalEventCard(
            event: approval.event,  // Pass the event from approval
            onViewDetails: () {}, // TODO: Implement view details
            onApprove: () => _handleApprove(approval),  // Pass approval object
            onReject: () => _handleReject(approval),    // Pass approval object
          );
        },
      ),
    );
  }

  Widget _buildApprovedTab() {
    if (_isLoadingApproved) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_approvedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có sự kiện được duyệt',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApprovedEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _approvedEvents.length,
        itemBuilder: (context, index) {
          final event = _approvedEvents[index];
          return _buildApprovedEventCard(event);
        },
      ),
    );
  }

  Widget _buildApprovedEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(event.clubName, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(event.location, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${event.startAt.day}/${event.startAt.month}/${event.startAt.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Đã phê duyệt',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancellationTab() {
    if (_isLoadingCancellations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cancellationRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có yêu cầu hủy sự kiện',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCancellationRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cancellationRequests.length,
        itemBuilder: (context, index) {
          final request = _cancellationRequests[index];
          return _buildCancellationRequestCard(request);
        },
      ),
    );
  }

  Widget _buildCancellationRequestCard(EventCancellationRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Chờ duyệt',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Lý do yêu cầu hủy:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(request.reason),
            if (request.refundPolicy != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Chính sách hoàn tiền:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(request.refundPolicy!),
            ],
            if (request.alternativeAction != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Hành động thay thế:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(request.alternativeAction!),
            ],
            const SizedBox(height: 8),
            Text(
              'Yêu cầu vào: ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleRejectCancellation(request),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      'Từ chối',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApproveCancellation(request),
                    icon: const Icon(Icons.check),
                    label: const Text('Phê duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
