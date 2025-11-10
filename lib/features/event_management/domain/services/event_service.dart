import 'package:flutter/foundation.dart';
import 'package:event_connect/features/event_management/data/repositories/event_repository.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';

/// EventService - Quản lý state và business logic cho events
class EventService extends ChangeNotifier {
  final EventRepository repository;

  EventService({required this.repository});

  // State
  List<Event> _allEvents = [];
  List<Event> _featuredEvents = [];
  List<Event> _myRegisteredEvents = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'Tất cả';

  // Getters
  List<Event> get allEvents => _allEvents;
  List<Event> get featuredEvents => _featuredEvents;
  List<Event> get myRegisteredEvents => _myRegisteredEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;

  // Danh mục cố định
  static const List<String> categories = [
    'Tất cả',
    'Âm nhạc',
    'Công nghệ',
    'Nghệ thuật',
    'Thể thao',
    'Nghề nghiệp',
  ];

  /// Lấy danh sách events được lọc theo category
  List<Event> get filteredEvents {
    if (_selectedCategory == 'Tất cả') {
      return _allEvents;
    }
    return _allEvents.where((event) => event.category == _selectedCategory).toList();
  }

  /// Lấy sự kiện sắp tới
  List<Event> get upcomingEvents {
    final now = DateTime.now();
    return _allEvents.where((event) => event.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Lấy sự kiện đã qua
  List<Event> get pastEvents {
    final now = DateTime.now();
    return _allEvents.where((event) => event.date.isBefore(now)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Load tất cả events
  Future<void> loadAllEvents() async {
    _setLoading(true);
    try {
      _allEvents = await repository.getAllEvents();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _allEvents = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Load featured events
  Future<void> loadFeaturedEvents() async {
    _setLoading(true);
    try {
      _featuredEvents = await repository.getFeaturedEvents();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _featuredEvents = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Load events đã đăng ký
  Future<void> loadMyRegisteredEvents() async {
    _setLoading(true);
    try {
      _myRegisteredEvents = await repository.getMyRegisteredEvents();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _myRegisteredEvents = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Tìm kiếm events
  Future<List<Event>> searchEvents(String query) async {
    try {
      return await repository.searchEvents(query);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  /// Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Load events theo category
  Future<void> loadEventsByCategory(String category) async {
    _selectedCategory = category;
    _setLoading(true);
    try {
      _allEvents = await repository.filterEventsByCategory(category);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _allEvents = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Đăng ký sự kiện
  Future<bool> registerForEvent(String eventId) async {
    try {
      final success = await repository.registerForEvent(eventId);
      if (success) {
        await loadMyRegisteredEvents(); // Refresh danh sách đã đăng ký
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Hủy đăng ký sự kiện
  Future<bool> unregisterFromEvent(String eventId) async {
    try {
      final success = await repository.unregisterFromEvent(eventId);
      if (success) {
        await loadMyRegisteredEvents(); // Refresh danh sách đã đăng ký
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Gửi feedback
  Future<bool> submitFeedback(String eventId, double rating, String comment) async {
    try {
      return await repository.submitFeedback(eventId, rating, comment);
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Get event by ID
  Event? getEventById(String id) {
    try {
      return _allEvents.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadAllEvents(),
      loadFeaturedEvents(),
      loadMyRegisteredEvents(),
    ]);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
