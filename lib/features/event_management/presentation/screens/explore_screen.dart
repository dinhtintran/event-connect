import 'package:flutter/material.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/event_management/data/api/event_api.dart';
import 'package:event_connect/features/event_management/presentation/widgets/category_chip.dart';
import 'package:event_connect/features/event_management/presentation/screens/event_detail_screen.dart';
import 'package:event_connect/app_routes.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _eventApi = EventApi();

  String selectedCategory = 'Tất cả';
  final TextEditingController searchController = TextEditingController();
  bool isGridView = true;
  int displayedEventsCount = 4;
  bool isLoadingMore = false;
  
  // Filter states
  Set<String> selectedCategories = {};
  DateTimeRange? selectedDateRange;

  // API data
  List<Event> _allEvents = [];
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
      final result = await _eventApi.getUpcomingEvents(page: 1);

      if (result['status'] == 200) {
        final data = result['body'];

        setState(() {
          if (data['results'] != null) {
            _allEvents = (data['results'] as List)
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
    List<Event> events = _allEvents;

    // Filter by category chip
    if (selectedCategory != 'Tất cả') {
      events = events.where((event) => event.category == selectedCategory).toList();
    }
    
    // Filter by selected categories from filter dialog
    if (selectedCategories.isNotEmpty) {
      events = events.where((event) => selectedCategories.contains(event.category)).toList();
    }
    
    // Filter by date range
    if (selectedDateRange != null) {
      events = events.where((event) {
        return event.date.isAfter(selectedDateRange!.start.subtract(const Duration(days: 1))) &&
               event.date.isBefore(selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by search text
    if (searchController.text.isNotEmpty) {
      events = events.where((event) => 
        event.title.toLowerCase().contains(searchController.text.toLowerCase())
      ).toList();
    }

    return events;
  }

  List<Event> get displayedEvents {
    return filteredEvents.take(displayedEventsCount).toList();
  }

  bool get hasMoreEvents {
    return displayedEventsCount < filteredEvents.length;
  }

  void _loadMoreEvents() {
    setState(() {
      isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        displayedEventsCount += 4;
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
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildCategorySection(),
            const SizedBox(height: 16),
            _buildFilterBar(),
            const SizedBox(height: 16),
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
                              children: [
                                if (isGridView)
                                  _buildGridView()
                                else
                                  _buildListView(),
                                if (hasMoreEvents) ...[
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: _buildLoadMoreButton(),
                                  ),
                                ],
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
            'Khám phá sự kiện',
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
                  setState(() {
                    displayedEventsCount = 4; // Reset khi search
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = ['Tất cả', 'Âm nhạc', 'Công nghệ', 'Nghệ thuật', 'Thể thao'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Danh mục',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF120D26),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CategoryChip(
                  label: category,
                  isSelected: selectedCategory == category,
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      displayedEventsCount = 4;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Filter Button
          OutlinedButton.icon(
            onPressed: () {
              // Show filter dialog
              _showFilterDialog();
            },
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Bộ lọc'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF120D26),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const Spacer(),
          // View Toggle Buttons
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildViewToggleButton(
                  icon: Icons.grid_view,
                  isSelected: isGridView,
                  onTap: () {
                    setState(() {
                      isGridView = true;
                    });
                  },
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey.shade300,
                ),
                _buildViewToggleButton(
                  icon: Icons.list,
                  isSelected: !isGridView,
                  onTap: () {
                    setState(() {
                      isGridView = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5669FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7, // Tỷ lệ tốt hơn cho card
        ),
        itemCount: displayedEvents.length,
        itemBuilder: (context, index) {
          return _buildEventCard(displayedEvents[index]);
        },
      ),
    );
  }

  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: displayedEvents.map((event) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildEventListItem(event),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.08 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                event.imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 110,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),
            // Content - Expanded để fill space còn lại
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title với chiều cao cố định
                    SizedBox(
                      height: 38, // Đủ cho 2 dòng text
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF120D26),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(), // Push nút xuống dưới
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(event: event),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: const Color(0xFF120D26),
                        ),
                        child: const Text(
                          'Xem',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventListItem(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                event.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF120D26),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoadingMore ? null : _loadMoreEvents,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5669FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoadingMore
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Tải thêm sự kiện',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showFilterDialog() {
    // Tạo bản sao của filter states để có thể cancel
    Set<String> tempSelectedCategories = Set.from(selectedCategories);
    DateTimeRange? tempDateRange = selectedDateRange;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bộ lọc sự kiện',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF120D26),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Categories Section
                  const Text(
                    'Danh mục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF120D26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildCategoryCheckbox('Âm nhạc', tempSelectedCategories, setModalState),
                  _buildCategoryCheckbox('Thể thao', tempSelectedCategories, setModalState),
                  _buildCategoryCheckbox('Nghệ thuật', tempSelectedCategories, setModalState),
                  _buildCategoryCheckbox('Giáo dục', tempSelectedCategories, setModalState),
                  _buildCategoryCheckbox('Công nghệ', tempSelectedCategories, setModalState),
                  _buildCategoryCheckbox('Môi trường', tempSelectedCategories, setModalState),
                  
                  const SizedBox(height: 24),
                  
                  // Date Section
                  const Text(
                    'Ngày',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF120D26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  InkWell(
                    onTap: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2026),
                        initialDateRange: tempDateRange,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF5669FF),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempDateRange = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Color(0xFF5669FF),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tempDateRange == null
                                  ? '01/01/2024 - 31/12/2024'
                                  : '${tempDateRange!.start.day.toString().padLeft(2, '0')}/${tempDateRange!.start.month.toString().padLeft(2, '0')}/${tempDateRange!.start.year} - ${tempDateRange!.end.day.toString().padLeft(2, '0')}/${tempDateRange!.end.month.toString().padLeft(2, '0')}/${tempDateRange!.end.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF120D26),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedCategories = tempSelectedCategories;
                          selectedDateRange = tempDateRange;
                          displayedEventsCount = 4; // Reset
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5669FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Áp dụng bộ lọc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Reset Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          tempSelectedCategories.clear();
                          tempDateRange = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF120D26),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đặt lại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCheckbox(
    String category,
    Set<String> selectedCategories,
    StateSetter setModalState,
  ) {
    final isSelected = selectedCategories.contains(category);
    return CheckboxListTile(
      title: Text(
        category,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF120D26),
        ),
      ),
      value: isSelected,
      onChanged: (bool? value) {
        setModalState(() {
          if (value == true) {
            selectedCategories.add(category);
          } else {
            selectedCategories.remove(category);
          }
        });
      },
      activeColor: const Color(0xFF5669FF),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

