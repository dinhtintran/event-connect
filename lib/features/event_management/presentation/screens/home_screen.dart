import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/event_management/domain/services/event_service.dart';
import 'package:event_connect/features/event_management/presentation/widgets/category_chip.dart';
import 'package:event_connect/features/event_management/presentation/widgets/event_card_large.dart';
import 'package:event_connect/features/event_management/presentation/widgets/event_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'Tất cả';
  final TextEditingController searchController = TextEditingController();
  int displayedUpcomingEventsCount = 3; // Hiển thị 3 sự kiện ban đầu
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Load data khi màn hình được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final eventService = context.read<EventService>();
    await Future.wait([
      eventService.loadAllEvents(),
      eventService.loadFeaturedEvents(),
    ]);
  }

  List<Event> get allUpcomingEvents {
    final eventService = context.watch<EventService>();
    final now = DateTime.now();
    return eventService.filteredEvents
        .where((event) => event.date.isAfter(now) && !event.isFeatured)
        .toList();
  }

  List<Event> get displayedUpcomingEvents {
    return allUpcomingEvents.take(displayedUpcomingEventsCount).toList();
  }

  bool get hasMoreEvents {
    return displayedUpcomingEventsCount < allUpcomingEvents.length;
  }

  void _loadMoreEvents() {
    setState(() {
      isLoadingMore = true;
    });

    // Giả lập việc tải dữ liệu từ server
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        displayedUpcomingEventsCount += 3; // Tải thêm 3 sự kiện mỗi lần
        isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventService = context.watch<EventService>();
    final featuredEvents = eventService.featuredEvents;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: eventService.isLoading && eventService.allEvents.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Header
            _buildHeader(),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInitialData,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      // Category Filter
                      _buildCategoryFilter(),
                      const SizedBox(height: 24),
                      
                      // Error message
                      if (eventService.error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Lỗi: ${eventService.error}',
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Featured Events Section
                      if (featuredEvents.isNotEmpty) ...[
                        _buildSection(
                          title: 'Sự kiện nổi bật',
                          child: SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: featuredEvents.length,
                              itemBuilder: (context, index) {
                                return EventCardLarge(event: featuredEvents[index]);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Upcoming Events Section
                      _buildSection(
                        title: 'Sự kiện sắp tới',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              ...displayedUpcomingEvents.map((event) => EventListItem(event: event)),
                              // Load More Button
                              if (hasMoreEvents) ...[
                                const SizedBox(height: 16),
                                _buildLoadMoreButton(),
                              ],
                              if (displayedUpcomingEvents.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('Không có sự kiện nào'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // Bottom padding for navigation bar
                    ],
                  ),
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
            'Trang Chủ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF120D26),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_outlined, size: 24),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person, color: Colors.grey),
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
                  hintText: 'Tìm sự kiện, chủ đề...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final eventService = context.read<EventService>();
    
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: EventService.categories.length,
        itemBuilder: (context, index) {
          final category = EventService.categories[index];
          IconData? icon;
          
          switch (category) {
            case 'Tất cả':
              icon = Icons.apps;
              break;
            case 'Âm nhạc':
              icon = Icons.music_note;
              break;
            case 'Công nghệ':
              icon = Icons.computer;
              break;
            case 'Nghệ thuật':
              icon = Icons.palette;
              break;
            case 'Thể thao':
              icon = Icons.sports_soccer;
              break;
            case 'Nghề nghiệp':
              icon = Icons.work;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CategoryChip(
              label: category,
              icon: icon,
              isSelected: selectedCategory == category,
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
                eventService.setCategory(category);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF120D26),
            ),
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoadingMore ? null : _loadMoreEvents,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFF5669FF), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: const Color(0xFF5669FF),
        ),
        child: isLoadingMore
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5669FF)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tải thêm sự kiện (${allUpcomingEvents.length - displayedUpcomingEventsCount})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

