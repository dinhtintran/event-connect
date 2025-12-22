import 'package:event_connect/features/event_management/data/api/event_api.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';

/// EventRepository - Quản lý logic nghiệp vụ và chuyển đổi dữ liệu
class EventRepository {
  final EventApi api;

  EventRepository({required this.api});

  /// Helper method to parse event list from various response formats
  List<Event> _parseEventList(dynamic body) {
    // Handle paginated response (Django REST framework with 'results' key)
    if (body is Map<String, dynamic>) {
      if (body.containsKey('results')) {
        final List<dynamic> data = body['results'] as List<dynamic>;
        return data.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
      }
      // Handle wrapped response with 'data' key
      else if (body.containsKey('data') && body['data'] is List<dynamic>) {
        return (body['data'] as List<dynamic>)
            .map((json) => Event.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Unexpected response format: Map without results or data key');
    }
    // Handle direct array response
    else if (body is List<dynamic>) {
      return body.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
    }
    
    throw Exception('Invalid response format: Expected List or Map with results/data');
  }

  /// Lấy tất cả sự kiện
  Future<List<Event>> getAllEvents() async {
    final result = await api.getAllEvents();
    if (result['status'] == 200) {
      return _parseEventList(result['body']);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch events');
    }
  }

  /// Lấy chi tiết sự kiện
  Future<Event> getEventById(String id) async {
    final result = await api.getEventById(id);
    if (result['status'] == 200) {
      return Event.fromJson(result['body'] as Map<String, dynamic>);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch event');
    }
  }

  /// Lấy sự kiện nổi bật
  Future<List<Event>> getFeaturedEvents() async {
    final result = await api.getFeaturedEvents();
    if (result['status'] == 200) {
      return _parseEventList(result['body']);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch featured events');
    }
  }

  /// Tìm kiếm sự kiện
  Future<List<Event>> searchEvents(String query) async {
    final result = await api.searchEvents(query);
    if (result['status'] == 200) {
      return _parseEventList(result['body']);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to search events');
    }
  }

  /// Lọc sự kiện theo danh mục
  Future<List<Event>> filterEventsByCategory(String category) async {
    if (category == 'Tất cả') {
      return getAllEvents();
    }
    
    final result = await api.getEventsByCategory(category);
    if (result['status'] == 200) {
      return _parseEventList(result['body']);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to filter events');
    }
  }

  /// Đăng ký sự kiện
  Future<bool> registerForEvent(String eventId) async {
    final result = await api.registerForEvent(eventId);
    return result['status'] == 200 || result['status'] == 201;
  }

  /// Hủy đăng ký sự kiện
  Future<bool> unregisterFromEvent(String eventId) async {
    final result = await api.unregisterFromEvent(eventId);
    // Treat 404 as success - event doesn't exist or user not registered = same outcome
    return result['status'] == 200 || result['status'] == 204 || result['status'] == 404;
  }

  /// Lấy danh sách sự kiện đã đăng ký
  Future<List<Event>> getMyRegisteredEvents() async {
    final result = await api.getMyRegisteredEvents();
    if (result['status'] == 200) {
      // Parse registrations response - extract event objects from nested structure
      final body = result['body'];
      if (body is Map<String, dynamic> && body.containsKey('results')) {
        final List<dynamic> registrations = body['results'] as List<dynamic>;
        // Extract event objects from registration objects
        return registrations
            .map((registration) {
              // Registration structure: { id: 14, event: {...}, user: {...}, ... }
              // We need the nested 'event' object, NOT the registration ID!
              final eventData = registration['event'];
              if (eventData == null) {
                print('⚠️ Warning: Registration without event data: ${registration['id']}');
                return null;
              }
              return Event.fromJson(eventData as Map<String, dynamic>);
            })
            .whereType<Event>() // Filter out nulls
            .toList();
      }
      return _parseEventList(body);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch registered events');
    }
  }

  /// Gửi feedback
  Future<bool> submitFeedback(String eventId, double rating, String comment) async {
    final result = await api.submitFeedback(eventId, {
      'rating': rating,
      'comment': comment,
    });
    return result['status'] == 200 || result['status'] == 201;
  }

  /// Lấy danh sách feedback của sự kiện
  Future<List<dynamic>> getEventFeedbacks(String eventId) async {
    final result = await api.getEventFeedbacks(eventId);
    if (result['status'] == 200) {
      return result['body'] as List<dynamic>;
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch feedbacks');
    }
  }

  // ==================== SAVED EVENTS METHODS ====================

  /// Lấy danh sách sự kiện đã lưu
  Future<List<Event>> getSavedEvents({int page = 1}) async {
    final result = await api.getSavedEvents(page: page);
    if (result['status'] == 200) {
      // Parse saved events response - extract event objects from nested structure
      final body = result['body'];
      if (body is Map<String, dynamic> && body.containsKey('results')) {
        final List<dynamic> savedEvents = body['results'] as List<dynamic>;
        // Extract event objects from saved event objects
        return savedEvents
            .map((savedEvent) {
              // Check if savedEvent has nested 'event' object
              if (savedEvent is Map<String, dynamic>) {
                final eventData = savedEvent['event'];
                
                // Format 1: { id: 123, event: {...}, saved_at: "..." }
                if (eventData != null && eventData is Map<String, dynamic>) {
                  final event = Event.fromJson(eventData);
                  // Create new Event with isSaved=true and savedAt timestamp
                  return Event(
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
                    isSaved: true,  // Mark as saved
                    savedAt: DateTime.tryParse(savedEvent['saved_at'] ?? ''),
                    status: event.status,
                    riskLevel: event.riskLevel,
                    createdAt: event.createdAt,
                    updatedAt: event.updatedAt,
                    createdBy: event.createdBy,
                  );
                }
                
                // Format 2: Direct event object with saved metadata mixed in
                // { id: 7, title: "...", saved_at: "...", ... }
                else if (savedEvent.containsKey('title') || savedEvent.containsKey('name')) {
                  final event = Event.fromJson(savedEvent);
                  // Override isSaved and savedAt
                  return Event(
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
                    isSaved: true,  // Mark as saved
                    savedAt: DateTime.tryParse(savedEvent['saved_at'] ?? ''),
                    status: event.status,
                    riskLevel: event.riskLevel,
                    createdAt: event.createdAt,
                    updatedAt: event.updatedAt,
                    createdBy: event.createdBy,
                  );
                }
              }
              
              print('⚠️ Warning: SavedEvent without valid event data: $savedEvent');
              return null;
            })
            .whereType<Event>() // Filter out nulls
            .toList();
      }
      return _parseEventList(body);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to get saved events');
    }
  }

  /// Lưu sự kiện
  Future<bool> saveEvent(String eventId) async {
    final result = await api.saveEvent(eventId);
    return result['status'] == 201 || result['status'] == 200;
  }

  /// Bỏ lưu sự kiện
  Future<bool> unsaveEvent(String eventId) async {
    final result = await api.unsaveEvent(eventId);
    return result['status'] == 200 || result['status'] == 204;
  }

  /// Toggle save/unsave
  Future<bool> toggleSaveEvent(String eventId, bool currentlySaved) async {
    if (currentlySaved) {
      return await unsaveEvent(eventId);
    } else {
      return await saveEvent(eventId);
    }
  }
}
