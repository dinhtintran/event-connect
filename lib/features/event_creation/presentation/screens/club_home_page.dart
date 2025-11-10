import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/app_routes.dart';
import 'package:event_connect/features/event_creation/presentation/widgets/club_event_card_summary.dart';
import 'package:event_connect/features/event_creation/presentation/widgets/club_notification_tile.dart';
import 'package:event_connect/features/event_creation/data/repositories/club_admin_repository.dart';
import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/models/notification.dart';
import 'package:event_connect/features/authentication/authentication.dart';
import 'package:event_connect/features/event_creation/domain/models/club.dart';

class ClubHomePage extends StatefulWidget {
  const ClubHomePage({super.key});

  @override
  State<ClubHomePage> createState() => _ClubHomePageState();
}

class _ClubHomePageState extends State<ClubHomePage> {
  int _selectedIndex = 0; // 0 = Trang chủ
  
  // Data state
  List<Event> _recentEvents = [];
  List<AppNotification> _notifications = [];
  Club? _clubInfo;
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Repository
  late final ClubAdminRepository _repository;
  
  @override
  void initState() {
    super.initState();
    _repository = ClubAdminRepository(api: ClubAdminApi());
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get current user to find club ID
      final authService = context.read<AuthService>();
      final user = authService.user;
      
      if (user == null) {
        setState(() {
          _errorMessage = 'Vui lòng đăng nhập';
          _isLoading = false;
        });
        return;
      }
      
      // Try to get club ID from user profile or fetch clubs list
      String? clubId;
      String? clubName;
      
      // Check if user has club info in profile
      if (user.profile.clubName != null && user.profile.clubName!.isNotEmpty) {
        clubName = user.profile.clubName;
        // Try to find club ID by fetching clubs list
        try {
          final clubApi = ClubAdminApi();
          final clubsResult = await clubApi.clubApi.getAllClubs();
          if (clubsResult['status'] == 200) {
            final clubs = clubsResult['body'];
            if (clubs is Map && clubs.containsKey('results')) {
              final results = clubs['results'] as List;
              try {
                final matchingClub = results.firstWhere(
                  (c) => c['name'] == clubName,
                );
                clubId = matchingClub['id']?.toString();
              } catch (e) {
                // Club not found by name
              }
            } else if (clubs is List) {
              try {
                final matchingClub = clubs.firstWhere(
                  (c) => c['name'] == clubName,
                );
                clubId = matchingClub['id']?.toString();
              } catch (e) {
                // Club not found by name
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching clubs: $e');
        }
      }
      
      // Fallback: use default club ID if not found (for testing)
      clubId = clubId ?? '1';
      
      // Fetch data sequentially with error handling for each
      List<Event> recentEvents = [];
      List<AppNotification> notifications = [];
      int unreadCount = 0;
      Club? clubInfo;
      
      try {
        debugPrint('Fetching recent events...');
        recentEvents = await _repository.getRecentClubEvents(clubId, limit: 5);
        debugPrint('Recent events loaded: ${recentEvents.length}');
      } catch (e) {
        debugPrint('Error fetching recent events: $e');
      }
      
      try {
        debugPrint('Fetching notifications...');
        notifications = await _repository.getNotifications(isRead: false);
        debugPrint('Notifications loaded: ${notifications.length}');
      } catch (e) {
        debugPrint('Error fetching notifications: $e');
      }
      
      try {
        debugPrint('Fetching unread count...');
        unreadCount = await _repository.getUnreadNotificationCount();
        debugPrint('Unread count: $unreadCount');
      } catch (e) {
        debugPrint('Error fetching unread count: $e');
      }
      
      try {
        debugPrint('Fetching club info...');
        final clubData = await _repository.getClubInfo(clubId);
        clubInfo = Club.fromJson(clubData);
        debugPrint('Club info loaded: ${clubInfo.name}');
      } catch (e) {
        debugPrint('Error fetching club info: $e');
      }
      
      setState(() {
        _recentEvents = recentEvents;
        _notifications = notifications;
        _unreadCount = unreadCount;
        _clubInfo = clubInfo;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading club home data: $e');
      setState(() {
        _errorMessage = 'Lỗi khi tải dữ liệu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  String _getStatusText(Event event) {
    final now = DateTime.now();
    if (event.status == 'approved' && event.startAt.isBefore(now) && (event.endAt == null || event.endAt!.isAfter(now))) {
      return 'Live';
    } else if (event.status == 'approved' && event.startAt.isAfter(now)) {
      return 'Scheduled';
    } else if (event.status == 'pending') {
      return 'Chờ duyệt';
    } else if (event.status == 'draft') {
      return 'Bản nháp';
    } else if (event.status == 'completed') {
      return 'Đã kết thúc';
    }
    return event.status ?? 'N/A';
  }
  
  bool _isEventLive(Event event) {
    final now = DateTime.now();
    return event.status == 'approved' && 
           event.startAt.isBefore(now) && 
           (event.endAt == null || event.endAt!.isAfter(now));
  }
  
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'event_approved':
        return Icons.check_circle_outline;
      case 'event_rejected':
        return Icons.cancel_outlined;
      case 'event_reminder':
        return Icons.notifications_active;
      case 'event_cancelled':
        return Icons.event_busy;
      case 'event_updated':
        return Icons.update;
      case 'registration_confirmed':
        return Icons.confirmation_number;
      case 'club_announcement':
        return Icons.campaign;
      default:
        return Icons.info_outline;
    }
  }
  
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'event_approved':
        return Colors.green;
      case 'event_rejected':
        return Colors.red;
      case 'event_reminder':
        return Colors.orange;
      case 'event_cancelled':
        return Colors.red;
      case 'event_updated':
        return Colors.blue;
      case 'registration_confirmed':
        return Colors.green;
      case 'club_announcement':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Note: navigation to ClubEventsPage now uses named routes

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    // Navigation based on index:
    // 0 -> Trang Chủ (stay here)
    // 1 -> Sự kiện
    // 2 -> Thư (not implemented)
    // 3 -> Thống Kê (not implemented)
    // 4 -> Hồ Sơ

    if (index == 1) {
      // Navigate to Events page
      debugPrint('ClubHomePage: tapping Sự kiện tab -> navigate to ClubEventsPage (named)');
      try {
        Navigator.pushNamed(context, AppRoutes.clubEvents);
      } catch (e, st) {
        debugPrint('Failed to navigate to ClubEventsPage (named): $e\n$st');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi chuyển trang: ${e.toString()}')));
        }
      }
    } else if (index == 4) {
      // Navigate to Profile
      debugPrint('ClubHomePage: tapping Hồ Sơ tab -> navigate to Profile');
      try {
        Navigator.pushNamed(context, AppRoutes.profile);
      } catch (e, st) {
        debugPrint('Failed to navigate to Profile: $e\n$st');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi chuyển trang: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black54),
                onPressed: () {},
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
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
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
            padding: const EdgeInsets.only(right: 12.0),
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
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner card
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                              width: double.infinity,
                              height: 140,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _clubInfo?.logo != null && _clubInfo!.logo!.isNotEmpty
                                        ? Image.network(
                                            _clubInfo!.logo!,
                                            width: double.infinity,
                                            height: 140,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, st) => Image.asset(
                                              'assets/images/background.jpg',
                                              width: double.infinity,
                                              height: 140,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx2, err2, st2) => Container(
                                                width: double.infinity,
                                                height: 140,
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          )
                                        : Image.asset(
                                            'assets/images/background.jpg',
                                            width: double.infinity,
                                            height: 140,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, st) => Container(
                                              width: double.infinity,
                                              height: 140,
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withAlpha((0.45 * 255).round()),
                                          Colors.transparent
                                        ],
                                        begin: Alignment.bottomLeft,
                                        end: Alignment.topRight,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    alignment: Alignment.bottomLeft,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _clubInfo != null
                                              ? 'Chào mừng bạn trở lại, ${_clubInfo!.name}!'
                                              : 'Chào mừng bạn trở lại, Đội ngũ EventConnect!',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Tổng quan sự kiện của bạn trong nháy mắt.',
                                          style: TextStyle(
                                              color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                                // 👉 Khi bấm "Xem tất cả" -> chuyển sang trang ClubEventsPage (có hiệu ứng trượt)
                                onTap: () {
                                  debugPrint('ClubHomePage: tapped Xem tất cả -> navigate to ClubEventsPage (named)');
                                  try {
                                    Navigator.pushNamed(context, AppRoutes.clubEvents);
                                  } catch (e, st) {
                                    debugPrint('Failed to navigate to ClubEventsPage (named): $e\n$st');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi chuyển trang: ${e.toString()}')));
                                    }
                                  }
                                },
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

                          const SizedBox(height: 14),

                          // Event cards - dynamic from API
                          if (_recentEvents.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Chưa có sự kiện nào',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            )
                          else
                            ..._recentEvents.map((event) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClubEventCardSummary(
                                title: event.title,
                                status: _getStatusText(event),
                                registered: event.participantCount,
                                capacity: event.capacity,
                                isLive: _isEventLive(event),
                                onManage: () {
                                  // TODO: Navigate to event management page
                                },
                                onRegister: () {
                                  // TODO: Handle registration
                                },
                                onEdit: () {
                                  // TODO: Navigate to edit event page
                                },
                              ),
                            )),

                          const SizedBox(height: 22),

                          const Text(
                            'Thông báo quan trọng',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),

                          const SizedBox(height: 12),

                          // Notifications - dynamic from API
                          if (_notifications.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Không có thông báo nào',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            )
                          else
                            ..._notifications.take(5).map((notification) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ClubNotificationTile(
                                title: notification.title,
                                subtitle: notification.message,
                                icon: _getNotificationIcon(notification.type),
                                accent: _getNotificationColor(notification.type),
                                onTap: () {
                                  // TODO: Handle notification tap
                                },
                              ),
                            )),

                          const SizedBox(height: 40),
                        ],
                      ),
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

