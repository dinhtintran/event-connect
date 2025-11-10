import 'package:flutter/material.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/event_management/data/api/event_api.dart';
import 'package:event_connect/features/event_management/presentation/widgets/category_chip.dart';
import 'package:event_connect/features/event_management/presentation/widgets/event_card_large.dart';
import 'package:event_connect/features/event_management/presentation/widgets/event_list_item.dart';
import 'package:event_connect/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _eventApi = EventApi();

  String selectedCategory = 'Tất cả';
  final TextEditingController searchController = TextEditingController();
  int displayedUpcomingEventsCount = 3;
  bool isLoadingMore = false;

  // Data from API
  List<Event> _allEvents = [];
  List<Event> _featuredEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load featured events
      final featuredResult = await _eventApi.getFeaturedEvents();

      // Load upcoming events
      final upcomingResult = await _eventApi.getUpcomingEvents();

      if (featuredResult['status'] == 200 && upcomingResult['status'] == 200) {
        final featuredData = featuredResult['body'];
        final upcomingData = upcomingResult['body'];

        setState(() {
          // Parse featured events
          if (featuredData['results'] != null) {
            _featuredEvents = (featuredData['results'] as List)
                .map((json) => Event.fromJson(json))
                .toList();
          }

          // Parse all events
          if (upcomingData['results'] != null) {
            _allEvents = (upcomingData['results'] as List)
                .map((json) => Event.fromJson(json))
                .toList();
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không thể tải sự kiện';
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

  List<Event> get filteredEvents {
    if (selectedCategory == 'Tất cả') {
      return _allEvents;
    }
    return _allEvents
        .where((event) => event.category == selectedCategory)
        .toList();
  }

  List<Event> get featuredEvents => _featuredEvents;

  List<Event> get allUpcomingEvents {
    return _allEvents.where((event) => !event.isFeatured).toList();
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

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        displayedUpcomingEventsCount += 3;
        isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                  : RefreshIndicator(
                onRefresh: _loadEvents,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      _buildCategoryFilter(),
                      const SizedBox(height: 24),
                      if (featuredEvents.isNotEmpty)
                        _buildSection(
                          title: 'Dành cho bạn',
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
                      if (featuredEvents.isNotEmpty)
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
                      _buildSection(
                        title: 'Sự kiện sắp tới',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              ...displayedUpcomingEvents.map((event) => EventListItem(event: event)),
                              if (hasMoreEvents) ...[
                                const SizedBox(height: 16),
                                _buildLoadMoreButton(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
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
    final categories = ['Tất cả', 'Âm nhạc', 'Công nghệ', 'Nghệ thuật', 'Thể thao'];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
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
              fontSize: 18,
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
    return isLoadingMore
        ? const Center(child: CircularProgressIndicator())
        : OutlinedButton(
      onPressed: _loadMoreEvents,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('Xem thêm'),
    );
  }
}

