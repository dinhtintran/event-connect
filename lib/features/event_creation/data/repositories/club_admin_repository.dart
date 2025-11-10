import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/models/notification.dart';

/// ClubAdminRepository - Quản lý logic nghiệp vụ cho Club Admin
class ClubAdminRepository {
  final ClubAdminApi api;

  ClubAdminRepository({required this.api});

  /// Helper method to parse event list from various response formats
  List<Event> _parseEventList(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('results')) {
        final List<dynamic> data = body['results'] as List<dynamic>;
        return data.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
      } else if (body.containsKey('data') && body['data'] is List<dynamic>) {
        return (body['data'] as List<dynamic>)
            .map((json) => Event.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Unexpected response format: Map without results or data key');
    } else if (body is List<dynamic>) {
      return body.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception('Invalid response format: Expected List or Map with results/data');
  }

  /// Lấy danh sách sự kiện của CLB
  Future<List<Event>> getClubEvents(
    String clubId, {
    String? status,
    String? searchQuery,
    int? page,
    int? pageSize,
  }) async {
    final result = await api.getClubEvents(
      clubId,
      status: status,
      searchQuery: searchQuery,
      page: page,
      pageSize: pageSize,
    );
    if (result['status'] == 200) {
      return _parseEventList(result['body']);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch club events');
    }
  }

  /// Lấy sự kiện gần đây của CLB (limit số lượng)
  Future<List<Event>> getRecentClubEvents(String clubId, {int limit = 5}) async {
    final result = await api.getClubEvents(clubId, pageSize: limit);
    if (result['status'] == 200) {
      final events = _parseEventList(result['body']);
      // Sort by start_at descending to get most recent first
      events.sort((a, b) => (b.startAt).compareTo(a.startAt));
      return events.take(limit).toList();
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch recent events');
    }
  }

  /// Lấy thông tin CLB
  Future<Map<String, dynamic>> getClubInfo(String clubId) async {
    final result = await api.getClubInfo(clubId);
    if (result['status'] == 200) {
      final body = result['body'];
      if (body is Map<String, dynamic>) {
        return body;
      } else if (body is List && body.isNotEmpty) {
        // Backend might return array with single club
        return body[0] as Map<String, dynamic>;
      }
      throw Exception('Invalid response format for club info: ${body.runtimeType}');
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch club info');
    }
  }

  /// Lấy thông báo
  Future<List<AppNotification>> getNotifications({bool? isRead}) async {
    final result = await api.getNotifications(isRead: isRead);
    if (result['status'] == 200) {
      final body = result['body'];
      List<dynamic> notifications = [];
      
      if (body is Map && body.containsKey('results')) {
        notifications = body['results'] as List<dynamic>;
      } else if (body is List) {
        notifications = body;
      }
      
      return notifications
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch notifications');
    }
  }

  /// Lấy số thông báo chưa đọc
  Future<int> getUnreadNotificationCount() async {
    final result = await api.getUnreadNotificationCount();
    if (result['status'] == 200) {
      final body = result['body'];
      if (body is Map && body.containsKey('unread_count')) {
        return body['unread_count'] as int? ?? 0;
      } else if (body is int) {
        return body;
      }
      return 0;
    } else {
      return 0; // Return 0 on error instead of throwing
    }
  }

  /// Lấy danh sách người tham gia sự kiện
  Future<List<Map<String, dynamic>>> getEventParticipants(String eventId, {String? status}) async {
    final result = await api.getEventParticipants(eventId, status: status);
    if (result['status'] == 200) {
      final body = result['body'];
      if (body is Map && body.containsKey('results')) {
        return (body['results'] as List<dynamic>)
            .map((json) => json as Map<String, dynamic>)
            .toList();
      } else if (body is List) {
        return body.map((json) => json as Map<String, dynamic>).toList();
      }
      return [];
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch participants');
    }
  }

  /// Cập nhật sự kiện
  Future<Event> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    final result = await api.updateEvent(eventId, eventData);
    if (result['status'] == 200) {
      return Event.fromJson(result['body'] as Map<String, dynamic>);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to update event');
    }
  }
  
  /// Tạo sự kiện mới cho CLB
  Future<Event> createEvent(String clubId, Map<String, dynamic> eventData) async {
    final result = await api.createEvent(clubId, eventData);
    if (result['status'] == 200 || result['status'] == 201) {
      return Event.fromJson(result['body'] as Map<String, dynamic>);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to create event');
    }
  }
}

