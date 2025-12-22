import 'dart:developer' as developer;

import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';
import 'package:event_connect/features/event_creation/domain/models/club_statistics_summary.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/models/notification.dart';
import 'package:event_connect/features/event_creation/domain/models/event_cancellation_request.dart';

class ClubAssignmentException implements Exception {
  final String message;
  const ClubAssignmentException(this.message);
  @override
  String toString() => message;
}

class ClubNotAssignedException extends ClubAssignmentException {
  const ClubNotAssignedException([String message = 'Tài khoản chưa được gán vào bất kỳ CLB nào.']) : super(message);
}

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

  /// Lấy CLB mà user hiện tại đang quản lý (thông qua /api/accounts/me/club/)
  Future<Map<String, dynamic>> getCurrentClubProfile() async {
    final result = await api.getCurrentUserClub();
    final status = result['status'] as int? ?? 0;
    final body = result['body'];

    if (status == 200) {
      if (body is Map) {
        final hasClub = _parseBool(body['hasClub'] ?? body['has_club']);
        if (hasClub == false) {
          throw const ClubNotAssignedException();
        }
        final club = _extractClubFromAssignment(body);
        if (club != null) {
          return club;
        }
        throw const ClubAssignmentException('Không đọc được thông tin CLB từ phản hồi backend.');
      }
      throw const ClubAssignmentException('Định dạng phản hồi CLB không hợp lệ.');
    }

    if (status == 404) {
      throw const ClubNotAssignedException();
    }

    throw ClubAssignmentException(_extractErrorMessage(body) ?? 'Không thể lấy thông tin CLB hiện tại (mã $status).');
  }

  /// Helper để lấy ID CLB hiện tại phục vụ các màn thống kê
  Future<String> getCurrentClubId() async {
    final profile = await getCurrentClubProfile();
    final dynamic rawId = profile['id'] ?? profile['club_id'] ?? profile['pk'];
    if (rawId == null) {
      throw const ClubAssignmentException('Phản hồi CLB không chứa mã định danh.');
    }
    return rawId.toString();
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
    
    // Debug logging
    developer.log('getEventParticipants result: status=${result['status']}', name: 'ClubAdminRepository');
    developer.log('Response body type: ${result['body'].runtimeType}', name: 'ClubAdminRepository');
    if (result['status'] != 200) {
      developer.log('Error response: ${result['body']}', name: 'ClubAdminRepository');
    }
    
    if (result['status'] == 200) {
      final body = result['body'];
      if (body is Map && body.containsKey('results')) {
        final participants = (body['results'] as List<dynamic>)
            .map((json) => json as Map<String, dynamic>)
            .toList();
        developer.log('Parsed ${participants.length} participants from results', name: 'ClubAdminRepository');
        return participants;
      } else if (body is List) {
        final participants = body.map((json) => json as Map<String, dynamic>).toList();
        developer.log('Parsed ${participants.length} participants from list', name: 'ClubAdminRepository');
        return participants;
      }
      developer.log('No participants found, returning empty list', name: 'ClubAdminRepository');
      return [];
    } else {
      final errorDetail = result['body']['detail'] ?? 'Failed to fetch participants';
      developer.log('Throwing exception: $errorDetail', name: 'ClubAdminRepository');
      throw Exception(errorDetail);
    }
  }

  /// Lấy thống kê đã tổng hợp từ backend cho CLB
  Future<ClubStatisticsSummary> getClubStatistics(
    String clubId, {
    int rangeDays = 90,
    int limitFeedback = 3,
    int limitHighlights = 6,
  }) async {
    final result = await api.getClubStatistics(
      clubId,
      rangeDays: rangeDays,
      limitFeedback: limitFeedback,
      limitHighlights: limitHighlights,
    );

    if (result['status'] == 200) {
      final body = result['body'];
      if (body is Map<String, dynamic>) {
        return ClubStatisticsSummary.fromJson(body);
      }
      throw Exception('Invalid response format for club statistics');
    }

    throw Exception(_extractErrorMessage(result['body']) ?? 'Failed to fetch club statistics');
  }

  /// Lấy danh sách sự kiện thô phục vụ phân tích chi tiết
  Future<List<Event>> getClubStatisticsRawEvents(
    String clubId, {
    int rangeDays = 90,
    int? page,
    int? pageSize,
  }) async {
    final result = await api.getClubStatisticsRawEvents(
      clubId,
      rangeDays: rangeDays,
      page: page,
      pageSize: pageSize,
    );

    if (result['status'] == 200) {
      return _parseEventList(result['body']);
    }

    throw Exception(_extractErrorMessage(result['body']) ?? 'Failed to fetch raw statistics events');
  }

  /// Cập nhật sự kiện
  Future<Event> updateEvent(String eventId, dynamic eventData) async {
    final result = await api.updateEvent(eventId, eventData);
    if (result['status'] == 200) {
      return Event.fromJson(result['body'] as Map<String, dynamic>);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to update event');
    }
  }
  
  /// Xóa sự kiện (chỉ cho phép xóa sự kiện chưa được phê duyệt)
  Future<void> deleteEvent(String eventId) async {
    final result = await api.deleteEvent(eventId);
    if (result['status'] != 204 && result['status'] != 200) {
      throw Exception(result['body']['detail'] ?? result['body']['error'] ?? 'Failed to delete event');
    }
  }
  
  /// Tạo sự kiện mới cho CLB
  Future<Event> createEvent(String clubId, dynamic eventData) async {
    final result = await api.createEvent(clubId, eventData);
    if (result['status'] == 200 || result['status'] == 201) {
      return Event.fromJson(result['body'] as Map<String, dynamic>);
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to create event');
    }
  }
  
  /// Yêu cầu hủy sự kiện (chỉ cho sự kiện đã approved)
  Future<EventCancellationRequest> requestCancellation({
    required String eventId,
    required String reason,
    String? refundPolicy,
    String? alternativeAction,
  }) async {
    final result = await api.requestCancellation(
      eventId: eventId,
      reason: reason,
      refundPolicy: refundPolicy,
      alternativeAction: alternativeAction,
    );
    
    if (result['status'] == 201 || result['status'] == 200) {
      return EventCancellationRequest.fromJson(result['body'] as Map<String, dynamic>);
    } else {
      // Extract error message
      final body = result['body'];
      String errorMsg = 'Failed to request cancellation';
      
      if (body is Map) {
        if (body.containsKey('error')) {
          errorMsg = body['error'].toString();
        } else if (body.containsKey('detail')) {
          errorMsg = body['detail'].toString();
        } else if (body.containsKey('reason')) {
          // Validation error for reason field
          errorMsg = body['reason'].toString();
        }
      }
      
      throw Exception(errorMsg);
    }
  }
  
  /// Lấy danh sách yêu cầu hủy của sự kiện
  Future<List<EventCancellationRequest>> getEventCancellationRequests(String eventId) async {
    final result = await api.getEventCancellationRequests(eventId);
    
    if (result['status'] == 200) {
      final body = result['body'];
      if (body is Map && body.containsKey('results')) {
        final results = body['results'] as List;
        return results
            .map((json) => EventCancellationRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception(result['body']['detail'] ?? 'Failed to fetch cancellation requests');
    }
  }
}

String? _extractErrorMessage(dynamic body) {
  if (body is Map) {
    if (body['detail'] != null) return body['detail'].toString();
    if (body['message'] != null) return body['message'].toString();
    if (body['error'] != null) return body['error'].toString();
    if (body['error_code'] != null) return body['error_code'].toString();
  }
  if (body is String && body.isNotEmpty) {
    return body;
  }
  return null;
}

bool? _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

Map<String, dynamic>? _extractClubFromAssignment(Map body) {
  // Direct club object
  final club = body['club'];
  if (club is Map<String, dynamic>) {
    return Map<String, dynamic>.from(club);
  }
  if (club is Map) {
    return club.map((key, value) => MapEntry(key.toString(), value));
  }

  // Fallback fields
  final clubId = body['club_id'] ?? body['club'];
  final clubName = body['club_name'];
  if (clubId != null || clubName != null) {
    return {
      if (clubId != null) 'id': clubId,
      if (clubName != null) 'name': clubName,
    };
  }

  // Nested membership payloads
  final membership = body['membership'];
  if (membership is Map<String, dynamic>) {
    final nestedClub = membership['club'];
    if (nestedClub is Map<String, dynamic>) {
      return Map<String, dynamic>.from(nestedClub);
    }
    if (nestedClub is Map) {
      return nestedClub.map((key, value) => MapEntry(key.toString(), value));
    }
    final membershipClubId = membership['club_id'] ?? membership['club'];
    final membershipClubName = membership['club_name'];
    if (membershipClubId != null || membershipClubName != null) {
      return {
        if (membershipClubId != null) 'id': membershipClubId,
        if (membershipClubName != null) 'name': membershipClubName,
      };
    }
  }

  return null;
}

