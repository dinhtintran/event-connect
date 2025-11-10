import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/event_management/data/api/event_api.dart';
import 'package:event_connect/features/event_management/presentation/screens/event_detail_screen.dart';
import 'package:event_connect/app_routes.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  final _eventApi = EventApi();
  final _storage = const FlutterSecureStorage();
  late TabController _tabController;
  final TextEditingController searchController = TextEditingController();

  // API data
  List<Event> _allRegisteredEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get access token
      final accessToken = await _storage.read(key: 'auth_access');

      if (accessToken == null) {
        setState(() {
          _errorMessage = 'Bạn cần đăng nhập để xem sự kiện của mình';
          _isLoading = false;
        });
        return;
      }

      // Get user's registered events
      final result = await _eventApi.getMyEvents(accessToken: accessToken);

      if (result['status'] == 200) {
        final data = result['body'];

        setState(() {
          if (data['results'] != null) {
            // Parse registrations and extract events
            _allRegisteredEvents = (data['results'] as List)
                .map((registration) {
                  // Each registration has an 'event' field
                  if (registration['event'] != null) {
                    return Event.fromJson(registration['event']);
                  }
                  return null;
                })
                .whereType<Event>()
                .toList();
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không thể tải sự kiện đã đăng ký';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  List<Event> get upcomingEvents {
    final now = DateTime.now();
    var events = _allRegisteredEvents.where((event) => event.date.isAfter(now)).toList();

    // Apply search filter
    if (searchController.text.isNotEmpty) {
      events = events.where((event) =>
          event.title.toLowerCase().contains(searchController.text.toLowerCase())
      ).toList();
    }

    return events;
  }

  List<Event> get pastEvents {
    final now = DateTime.now();
    var events = _allRegisteredEvents.where((event) => event.date.isBefore(now)).toList();

    // Apply search filter
    if (searchController.text.isNotEmpty) {
      events = events.where((event) =>
          event.title.toLowerCase().contains(searchController.text.toLowerCase())
      ).toList();
    }

    return events;
  }

  List<Event> get savedEvents {
    // TODO: Need separate API for saved/bookmarked events
    // For now, return empty list as we're only showing registered events
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_errorMessage!),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadEvents,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildEventsList(upcomingEvents, isUpcoming: true),
                            _buildEventsList(pastEvents, isUpcoming: false),
                            _buildEventsList(savedEvents, isUpcoming: true, isSaved: true),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Sự Kiện Của Tôi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF120D26),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm sự kiện...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (value) {
                  setState(() {}); // Rebuild to apply search filter
                },
              ),
            ),
            if (searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    searchController.clear();
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF5669FF),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: const Color(0xFF5669FF),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Sắp tới'),
                Tab(text: 'Đã qua'),
                Tab(text: 'Đã lưu'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: Color(0xFF5669FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events,
      {required bool isUpcoming, bool isSaved = false}) {
    if (events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadEvents,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có sự kiện nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(event: events[index]),
                ),
              );
            },
            child: MyEventCard(
              event: events[index],
              isUpcoming: isUpcoming,
              isSaved: isSaved,
            ),
          );
        },
      ),
    );
  }
}

class MyEventCard extends StatelessWidget {
  final Event event;
  final bool isUpcoming;
  final bool isSaved;

  const MyEventCard({
    super.key,
    required this.event,
    required this.isUpcoming,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Event Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF120D26),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF747688),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(event.date),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF747688),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF747688),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('hh:mm a').format(event.date),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF747688),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFF747688),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF747688),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (isUpcoming) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            // Handle check-in
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Check-in thành công!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.login,
                            size: 18,
                          ),
                          label: const Text('Check-in'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF5669FF),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            // Handle cancel
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hủy sự kiện'),
                                content: const Text(
                                    'Bạn có chắc chắn muốn hủy tham gia sự kiện này?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Không'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Đã hủy tham gia sự kiện'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: const Text('Có'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                          ),
                          label: const Text('Cancel'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

