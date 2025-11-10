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
    
    final result = await api.filterEventsByCategory(category);
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
    return result['status'] == 200 || result['status'] == 204;
  }

  /// Lấy danh sách sự kiện đã đăng ký
  Future<List<Event>> getMyRegisteredEvents() async {
    final result = await api.getMyRegisteredEvents();
    if (result['status'] == 200) {
      return _parseEventList(result['body']);
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
}
