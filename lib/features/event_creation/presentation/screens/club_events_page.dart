import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/app_routes.dart';
import 'package:event_connect/features/event_creation/presentation/screens/club_home_page.dart';
import 'package:event_connect/features/event_creation/presentation/screens/create_event_screen.dart';
import 'package:event_connect/features/event_creation/presentation/screens/edit_event_screen.dart';
import 'package:event_connect/features/event_creation/presentation/screens/event_participants_screen.dart';
import 'package:event_connect/core/widgets/app_nav_bar.dart';
import 'package:event_connect/features/event_creation/presentation/widgets/club_event_card.dart';
import 'package:event_connect/features/event_creation/presentation/widgets/request_cancellation_dialog.dart';
import 'package:event_connect/features/event_creation/data/repositories/club_admin_repository.dart';
import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/authentication/authentication.dart';
import 'package:intl/intl.dart';

class ClubEventsPage extends StatefulWidget {
  final bool showBottomNav;

  const ClubEventsPage({super.key, this.showBottomNav = true});

  @override
  State<ClubEventsPage> createState() => _ClubEventsPageState();
}

class _ClubEventsPageState extends State<ClubEventsPage> {
  int _selectedIndex = 1; // Tab "Sự kiện"

  // Data state
  List<Event> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Repository
  late final ClubAdminRepository _repository;
  String? _clubId;

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _repository = ClubAdminRepository(api: ClubAdminApi());
    _loadClubIdAndEvents();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _repository.getUnreadNotificationCount();
      if (!mounted) return;
      setState(() {
        _unreadCount = count;
      });
    } catch (e) {
      // ignore error
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadClubIdAndEvents() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null) {
      setState(() {
        _errorMessage = 'Vui lòng đăng nhập';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resolvedId = await _repository.getCurrentClubId();
      if (!mounted) return;

      setState(() {
        _clubId = resolvedId;
      });

      await _loadEvents();
    } on ClubNotAssignedException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on ClubAssignmentException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải thông tin CLB: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadEvents() async {
    if (_clubId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final status = _selectedStatus == 'all' ? null : _selectedStatus;
      final searchQuery = _searchQuery.isEmpty ? null : _searchQuery;
      
      final events = await _repository.getClubEvents(
        _clubId!,
        status: status,
        searchQuery: searchQuery,
      );
      
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading events: $e');
      setState(() {
        _errorMessage = 'Lỗi khi tải sự kiện: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadEvents();
      }
    });
  }
  
  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadEvents();
  }
  
  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      // Fallback if date formatting fails
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
  
  String _getStatusText(Event event) {
    final now = DateTime.now();
    if (event.status == 'approved' && event.startAt.isBefore(now) && (event.endAt == null || event.endAt!.isAfter(now))) {
      return 'Đang diễn ra';
    } else if (event.status == 'approved' && event.startAt.isAfter(now)) {
      return 'Đã duyệt';
    } else if (event.status == 'pending') {
      return 'Chờ duyệt';
    } else if (event.status == 'draft') {
      return 'Bản nháp';
    } else if (event.status == 'completed') {
      return 'Đã kết thúc';
    } else if (event.status == 'rejected') {
      return 'Bị từ chối';
    }
    return event.status ?? 'N/A';
  }
  
  Color _getStatusColor(Event event) {
    final now = DateTime.now();
    if (event.status == 'approved' && event.startAt.isBefore(now) && (event.endAt == null || event.endAt!.isAfter(now))) {
      return Colors.indigo;
    } else if (event.status == 'approved') {
      return Colors.green;
    } else if (event.status == 'pending') {
      return Colors.orange;
    } else if (event.status == 'draft') {
      return Colors.grey;
    } else if (event.status == 'rejected') {
      return Colors.red;
    }
    return Colors.grey;
  }
  
  void _showCreateEventDialog() async {
    if (_clubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin CLB')),
      );
      return;
    }
    
    // Navigate to create event screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(clubId: _clubId),
      ),
    );
    
    // Reload events if event was created successfully
    if (result == true) {
      _loadEvents();
    }
  }
  
  void _navigateToEditEvent(Event event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventScreen(event: event),
      ),
    );
    
    // Reload events if event was updated successfully
    if (result == true) {
      _loadEvents();
    }
  }
  
  void _navigateToParticipants(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventParticipantsScreen(event: event),
      ),
    );
  }
  
  void _showDeleteConfirmation(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sự kiện "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(event);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteEvent(Event event) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      await _repository.deleteEvent(event.id.toString());
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa sự kiện thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Reload events
      _loadEvents();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa sự kiện: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _showRequestCancellationDialog(Event event) async {
    // Import dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => RequestCancellationDialog(
        eventTitle: event.title,
      ),
    );
    
    if (result != null) {
      _requestCancellation(event, result);
    }
  }
  
  Future<void> _requestCancellation(Event event, Map<String, dynamic> data) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      await _repository.requestCancellation(
        eventId: event.id.toString(),
        reason: data['reason'] as String,
        refundPolicy: data['refund_policy'] as String?,
        alternativeAction: data['alternative_action'] as String?,
      );
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu hủy sự kiện đến System Admin'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Reload events to update status
      _loadEvents();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showSubmitForApprovalDialog(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi duyệt sự kiện'),
        content: Text(
          'Sự kiện "${event.title}" sẽ được chuyển sang trạng thái chờ duyệt và gửi đến System Admin. Bạn có chắc chắn muốn gửi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
            child: const Text(
              'Gửi duyệt',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _submitForApproval(event);
    }
  }

  Future<void> _submitForApproval(Event event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _repository.updateEvent(
        event.id.toString(),
        {'status': 'pending'},
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi duyệt sự kiện. Vui lòng chờ System Admin xét duyệt.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      _loadEvents();
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi duyệt: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
  
  void _navigateToEventDetail(Event event) {
    // Navigate to event detail screen (can create a dedicated route later)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết sự kiện'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.posterUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      event.posterUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        height: 200,
                        color: Colors.grey.shade300,
                        child: const Center(child: Icon(Icons.image, size: 64)),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.calendar_today, 'Thời gian', _formatDate(event.startAt)),
                _buildInfoRow(Icons.location_on, 'Địa điểm', event.location),
                _buildInfoRow(Icons.group, 'CLB', event.clubName),
                
                // Smart participant display
                _buildInfoRow(
                  Icons.people, 
                  'Người tham gia', 
                  event.participantDisplayText,
                ),
                
                // Show breakdown if there are multiple statuses
                if (event.totalParticipants > 0 && 
                    (event.checkedInCount > 0 || event.attendedCount > 0))
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.registrationCount > 0)
                          Text(
                            '• Đang đăng ký: ${event.registrationCount}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        if (event.checkedInCount > 0)
                          Text(
                            '• Đã check-in: ${event.checkedInCount}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        if (event.attendedCount > 0)
                          Text(
                            '• Đã tham dự: ${event.attendedCount}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                
                _buildInfoRow(Icons.info, 'Trạng thái', _getStatusText(event)),
                const SizedBox(height: 16),
                const Text(
                  'Mô tả',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(event.description),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
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
      ),
    );
  }

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

    // Navigation based on index:
    // 0 -> Trang Chủ
    // 1 -> Sự kiện (current page)
    // 2 -> Thư (Báo cáo sự kiện - tổng quan)
    // 3 -> Thống Kê (Thống kê chi tiết)
    // 4 -> Hồ Sơ

    if (index == 0) {
      // Go back to Club Home Page
      Navigator.push(context, _createSlideBackRoute(const ClubHomePage()));
    } else if (index == 2) {
      // Navigate to Statistics/Report page (overview)
      Navigator.pushNamed(context, AppRoutes.clubStatistics);
    } else if (index == 3) {
      // Navigate to Statistics Detail page
      Navigator.pushNamed(context, AppRoutes.clubStatisticsDetail);
    } else if (index == 4) {
      // Navigate to Profile
      Navigator.pushNamed(context, AppRoutes.profile);
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
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
                icon: const Icon(Icons.notifications_none, color: Colors.black),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/beongnho2.jpg',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Icon(Icons.person, size: 18, color: Colors.grey.shade600),
                ),
              ),
            ),
          ),
        ],
      ),

      // Nội dung trang
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          // Constrain the column to the viewport width to avoid horizontal
          // overflow / "BoxConstraints forces an infinite width" errors when
          // widgets inside try to use infinite width.
          width: MediaQuery.of(context).size.width,
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
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm sự kiện...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                  buildFilterChip('Tất cả', 'all', _selectedStatus == 'all'),
                  buildFilterChip('Bản nháp', 'draft', _selectedStatus == 'draft'),
                  buildFilterChip('Chờ duyệt', 'pending', _selectedStatus == 'pending'),
                  buildFilterChip('Đã duyệt', 'approved', _selectedStatus == 'approved'),
                  buildFilterChip('Đang diễn ra', 'ongoing', _selectedStatus == 'ongoing'),
                  buildFilterChip('Bị từ chối', 'rejected', _selectedStatus == 'rejected'),
                  buildFilterChip('Đã kết thúc', 'completed', _selectedStatus == 'completed'),
                  buildFilterChip('Đã hủy', 'cancelled', _selectedStatus == 'cancelled'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bộ lọc & kiểu xem
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Allow the filter button to shrink if space is tight
                Flexible(
                  child: OutlinedButton.icon(
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
                      overflow: TextOverflow.ellipsis,
                    ),
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
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEvents,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_events.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có sự kiện nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tạo sự kiện mới để bắt đầu',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._events.map((event) {
                // Chỉ cho phép xóa sự kiện chưa được phê duyệt
                final canDelete = event.status != 'approved';
                
                // Chỉ cho phép yêu cầu hủy sự kiện đã approved/ongoing và chưa kết thúc
                final now = DateTime.now();
                final canRequestCancellation = (event.status == 'approved' || event.status == 'ongoing') && 
                    (event.endAt == null || event.endAt!.isAfter(now));
                final canSubmitForApproval = event.status == 'draft';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClubEventCard(
                    status: _getStatusText(event),
                    statusColor: _getStatusColor(event),
                    title: event.title,
                    date: _formatDate(event.startAt),
                    location: event.location,
                    organizer: event.clubName,
                    image: event.posterUrl,
                    canDelete: canDelete,
                    canRequestCancellation: canRequestCancellation,
                    canSubmitForApproval: canSubmitForApproval,
                    onEdit: () => _navigateToEditEvent(event),
                    onViewParticipants: () => _navigateToParticipants(event),
                    onDelete: canDelete ? () => _showDeleteConfirmation(event) : null,
                    onRequestCancellation: canRequestCancellation 
                        ? () => _showRequestCancellationDialog(event) 
                        : null,
                    onSubmitForApproval: canSubmitForApproval
                        ? () => _showSubmitForApprovalDialog(event)
                        : null,
                    onTap: () => _navigateToEventDetail(event),
                  ),
                );
              }).toList(),
            const SizedBox(height: 28),

            // ➕ Nút tạo sự kiện
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _showCreateEventDialog,
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
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: widget.showBottomNav
          ? AppNavBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              roleOverride: 'club_admin',
            )
          : null,
    );
  }

  // Widget filter chip
  Widget buildFilterChip(String label, String status, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _onStatusFilterChanged(status),
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
      ),
    );
  }
}

