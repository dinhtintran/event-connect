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
  List<Event> _savedEvents = [];  // NEW: Saved events
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'Tất cả';
  
  // Debounce: Track ongoing save/unsave operations
  final Set<String> _ongoingSaveOperations = {};

  // Getters
  List<Event> get allEvents => _allEvents;
  List<Event> get featuredEvents => _featuredEvents;
  List<Event> get myRegisteredEvents => _myRegisteredEvents;
  List<Event> get savedEvents => _savedEvents;  // NEW: Saved events getter
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

  /// Lấy sự kiện sắp tới (chưa bắt đầu)
  List<Event> get upcomingEvents {
    final now = DateTime.now();
    return _allEvents.where((event) => event.startAt.isAfter(now)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  /// Lấy sự kiện đã qua (đã kết thúc)
  List<Event> get pastEvents {
    final now = DateTime.now();
    return _allEvents.where((event) {
      final eventEndTime = event.endAt ?? event.startAt.add(const Duration(hours: 2));
      return eventEndTime.isBefore(now);
    }).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
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
        await loadMyRegisteredEvents(); // Refresh danh sách đã đăng ký (notifyListeners được gọi trong _setLoading)
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
      print('🔴 [EventService] Unregistering from event: $eventId');
      print('🔴 [EventService] Before unregister - registered events count: ${_myRegisteredEvents.length}');
      
      final success = await repository.unregisterFromEvent(eventId);
      
      if (success) {
        print('✅ [EventService] Unregister API success');
        
        // WORKAROUND: Remove event from local list immediately
        // This handles backend bug where deleted events still appear in my-events list
        _myRegisteredEvents.removeWhere((event) => event.id == eventId);
        print('✅ [EventService] Removed event from local list - new count: ${_myRegisteredEvents.length}');
        
        // Still reload from backend to sync with server state
        await loadMyRegisteredEvents();
        print('✅ [EventService] After backend reload - count: ${_myRegisteredEvents.length}');
        
        // Force UI update
        notifyListeners();
      } else {
        print('❌ [EventService] Unregister API failed');
      }
      
      return success;
    } catch (e) {
      _error = e.toString();
      print('❌ [EventService] Error unregistering: $e');
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

  // ==================== SAVED EVENTS METHODS ====================

  /// Load saved events
  Future<void> loadSavedEvents() async {
    _setLoading(true);
    try {
      _savedEvents = await repository.getSavedEvents();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _savedEvents = [];
      print('Error loading saved events: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save event
  Future<bool> saveEvent(String eventId) async {
    try {
      final success = await repository.saveEvent(eventId);
      if (success) {
        // Reload saved events list
        await loadSavedEvents();
        // Update the event in other lists
        _updateEventSavedStatus(eventId, true);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      print('Error saving event: $e');
      return false;
    }
  }

  /// Unsave event
  Future<bool> unsaveEvent(String eventId) async {
    try {
      final success = await repository.unsaveEvent(eventId);
      if (success) {
        // Reload saved events list
        await loadSavedEvents();
        // Update the event in other lists
        _updateEventSavedStatus(eventId, false);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      print('Error unsaving event: $e');
      return false;
    }
  }

  /// Toggle save/unsave with debounce protection
  Future<bool> toggleSaveEvent(Event event) async {
    // Prevent duplicate operations on same event
    if (_ongoingSaveOperations.contains(event.id)) {
      print('⚠️ [EventService] Save operation already in progress for event ${event.id}');
      return false;
    }
    
    _ongoingSaveOperations.add(event.id);
    
    try {
      final result = event.isSaved 
          ? await unsaveEvent(event.id)
          : await saveEvent(event.id);
      return result;
    } finally {
      _ongoingSaveOperations.remove(event.id);
    }
  }

  /// Helper: Update saved status in all event lists
  void _updateEventSavedStatus(String eventId, bool isSaved) {
    // Update in all events
    for (var i = 0; i < _allEvents.length; i++) {
      if (_allEvents[i].id == eventId) {
        final event = _allEvents[i];
        _allEvents[i] = Event(
          id: event.id,
          title: event.title,
          imageUrl: event.imageUrl,
          date: event.date,
          location: event.location,
          category: event.category,
          isFeatured: event.isFeatured,
          clubName: event.clubName,
          clubId: event.clubId,
          description: event.description,
          locationDetail: event.locationDetail,
          startAt: event.startAt,
          endAt: event.endAt,
          posterUrl: event.posterUrl,
          capacity: event.capacity,
          participantCount: event.participantCount,
          registrationCount: event.registrationCount,
          checkedInCount: event.checkedInCount,
          attendedCount: event.attendedCount,
          totalParticipants: event.totalParticipants,
          isSaved: isSaved,  // Update saved status
          savedAt: isSaved ? DateTime.now() : null,
          status: event.status,
          riskLevel: event.riskLevel,
          createdAt: event.createdAt,
          updatedAt: event.updatedAt,
          createdBy: event.createdBy,
        );
      }
    }
    
    // Update in featured events
    for (var i = 0; i < _featuredEvents.length; i++) {
      if (_featuredEvents[i].id == eventId) {
        final event = _featuredEvents[i];
        _featuredEvents[i] = Event(
          id: event.id,
          title: event.title,
          imageUrl: event.imageUrl,
          date: event.date,
          location: event.location,
          category: event.category,
          isFeatured: event.isFeatured,
          clubName: event.clubName,
          clubId: event.clubId,
          description: event.description,
          locationDetail: event.locationDetail,
          startAt: event.startAt,
          endAt: event.endAt,
          posterUrl: event.posterUrl,
          capacity: event.capacity,
          participantCount: event.participantCount,
          registrationCount: event.registrationCount,
          checkedInCount: event.checkedInCount,
          attendedCount: event.attendedCount,
          totalParticipants: event.totalParticipants,
          isSaved: isSaved,  // Update saved status
          savedAt: isSaved ? DateTime.now() : null,
          status: event.status,
          riskLevel: event.riskLevel,
          createdAt: event.createdAt,
          updatedAt: event.updatedAt,
          createdBy: event.createdBy,
        );
      }
    }
  }
}
