import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/event_creation/presentation/screens/club_home_page.dart';
import 'package:event_connect/features/event_creation/presentation/screens/create_event_screen.dart';
import 'package:event_connect/core/widgets/app_nav_bar.dart';
import 'package:event_connect/features/event_creation/presentation/widgets/club_event_card.dart';
import 'package:event_connect/features/event_creation/data/repositories/club_admin_repository.dart';
import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/authentication/authentication.dart';
import 'package:intl/intl.dart';

class ClubEventsPage extends StatefulWidget {
  const ClubEventsPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _repository = ClubAdminRepository(api: ClubAdminApi());
    _loadClubIdAndEvents();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadClubIdAndEvents() async {
    // Get club ID from user profile
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user == null) {
      setState(() {
        _errorMessage = 'Vui lòng đăng nhập';
        _isLoading = false;
      });
      return;
    }
    
    // Try to get club ID (similar to club_home_page logic)
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
    
    _clubId = clubId ?? '1'; // Fallback
    _loadEvents();
  }
  
  Future<void> _loadEvents() async {
    if (_clubId == null) return;
    
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
                  buildFilterChip('Đã kết thúc', 'completed', _selectedStatus == 'completed'),
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
              ..._events.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClubEventCard(
                  status: _getStatusText(event),
                  statusColor: _getStatusColor(event),
                  title: event.title,
                  date: _formatDate(event.startAt),
                  location: event.location,
                  organizer: event.clubName,
                  image: event.posterUrl,
                ),
              )).toList(),
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
      bottomNavigationBar: AppNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        roleOverride: 'club_admin',
      ),
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

