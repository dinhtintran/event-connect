import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/event_management/presentation/widgets/notification_bell_student.dart';
import 'package:event_connect/features/event_management/domain/services/event_service.dart';
import 'package:event_connect/features/event_management/presentation/screens/event_detail_screen.dart';
import 'package:event_connect/app_routes.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs now
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventService>().loadMyRegisteredEvents();
      context.read<EventService>().loadSavedEvents(); // ✨ Load saved events
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Event> getUpcomingEvents(EventService eventService) {
    final now = DateTime.now();
    return eventService.myRegisteredEvents
        .where((event) {
          // Sự kiện sắp tới: chưa bắt đầu (startAt > now)
          return event.startAt.isAfter(now);
        })
        .toList();
  }

  List<Event> getOngoingEvents(EventService eventService) {
    final now = DateTime.now();
    return eventService.myRegisteredEvents
        .where((event) {
          // Sự kiện đang diễn ra: đã bắt đầu nhưng chưa kết thúc
          // startAt <= now < endAt
          final eventEndTime = event.endAt ?? event.startAt.add(const Duration(hours: 2)); // Default 2h nếu không có endAt
          return event.startAt.isBefore(now) && eventEndTime.isAfter(now);
        })
        .toList();
  }

  List<Event> getPastEvents(EventService eventService) {
    final now = DateTime.now();
    return eventService.myRegisteredEvents
        .where((event) {
          // Sự kiện đã qua: đã kết thúc (endAt < now)
          final eventEndTime = event.endAt ?? event.startAt.add(const Duration(hours: 2)); // Default 2h nếu không có endAt
          return eventEndTime.isBefore(now);
        })
        .toList();
  }

  List<Event> getSavedEvents(EventService eventService) {
    return eventService.savedEvents;  // ✅ Get from service
  }

  @override
  Widget build(BuildContext context) {
    final eventService = context.watch<EventService>();
    final upcomingEvents = getUpcomingEvents(eventService);
    final ongoingEvents = getOngoingEvents(eventService);
    final pastEvents = getPastEvents(eventService);
    final savedEvents = getSavedEvents(eventService);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: eventService.isLoading && eventService.myRegisteredEvents.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildTabs(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<EventService>().loadMyRegisteredEvents(),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventsList(upcomingEvents, isUpcoming: true),
                    _buildEventsList(ongoingEvents, isUpcoming: true, isOngoing: true),
                    _buildEventsList(pastEvents, isUpcoming: false),
                    _buildEventsList(savedEvents, isUpcoming: true, isSaved: true),
                  ],
                ),
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
              NotificationBellStudent(iconColor: Color(0xFF120D26)),
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
                Tab(text: 'Đang diễn ra'),
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
      {required bool isUpcoming, bool isOngoing = false, bool isSaved = false}) {
    if (events.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await context.read<EventService>().loadMyRegisteredEvents();
        },
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
      onRefresh: () async {
        await context.read<EventService>().loadMyRegisteredEvents();
      },
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
              isOngoing: isOngoing,
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
  final bool isOngoing;
  final bool isSaved;

  const MyEventCard({
    super.key,
    required this.event,
    required this.isUpcoming,
    this.isOngoing = false,
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
                // Only show Check-in/Cancel buttons for REGISTERED events, NOT saved events
                if ((isUpcoming || isOngoing) && !isSaved) ...[
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
                            // Handle cancel registration with modern dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.red.shade400,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Hủy đăng ký',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                content: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Bạn có chắc chắn muốn hủy đăng ký sự kiện này không? Bạn có thể đăng ký lại sau.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF747688),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                                actions: [
                                  // Không button (outlined)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF5669FF),
                                        side: const BorderSide(
                                          color: Color(0xFF5669FF),
                                          width: 1.5,
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Không',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Có button (filled with gradient)
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red.shade400,
                                            Colors.red.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          
                                          // Call API to unregister
                                          final eventService = context.read<EventService>();
                                          final success = await eventService.unregisterFromEvent(event.id);
                                          
                                          if (success) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: const [
                                                      Icon(Icons.check_circle, color: Colors.white),
                                                      SizedBox(width: 12),
                                                      Text('Đã hủy đăng ký thành công'),
                                                    ],
                                                  ),
                                                  duration: const Duration(seconds: 2),
                                                  backgroundColor: Colors.green,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              );
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: const [
                                                      Icon(Icons.error_outline, color: Colors.white),
                                                      SizedBox(width: 12),
                                                      Text('Có lỗi xảy ra, vui lòng thử lại'),
                                                    ],
                                                  ),
                                                  duration: const Duration(seconds: 2),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Hủy đăng ký',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.cancel_rounded,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                          label: Text(
                            'Hủy',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade400,
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

