import 'package:dio/dio.dart';
import 'package:event_connect/core/api/club_api.dart';
import 'package:event_connect/core/api/notification_api.dart';
import 'package:event_connect/features/event_management/data/api/event_api.dart';

/// ClubAdminApi - API client cho các tính năng của Club Admin
class ClubAdminApi {
  final ClubApi clubApi;
  final EventApi eventApi;
  final NotificationApi notificationApi;

  ClubAdminApi({
    ClubApi? clubApi,
    EventApi? eventApi,
    NotificationApi? notificationApi,
    Dio? dio,
  })  : clubApi = clubApi ?? ClubApi(dio: dio),
        eventApi = eventApi ?? EventApi(dio: dio),
        notificationApi = notificationApi ?? NotificationApi(dio: dio);

  void _dbg(String s) {
    // ignore: avoid_print
    print('[ClubAdminApi] $s');
  }

  /// Lấy danh sách sự kiện của CLB với filter
  Future<Map<String, dynamic>> getClubEvents(
    String clubId, {
    String? status,
    String? searchQuery,
    int? page,
    int? pageSize,
  }) async {
    _dbg('getClubEvents: clubId=$clubId, status=$status, search=$searchQuery');
    try {
      // Nếu có search query, dùng search endpoint
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchResult = await eventApi.searchEvents(searchQuery);
        if (searchResult['status'] == 200) {
          // Filter results by club_id
          final allResults = searchResult['body'];
          List<dynamic> filtered = [];
          if (allResults is Map && allResults.containsKey('results')) {
            filtered = (allResults['results'] as List)
                .where((e) => e['club']?.toString() == clubId || 
                             e['club_id']?.toString() == clubId)
                .toList();
          } else if (allResults is List) {
            filtered = allResults
                .where((e) => e['club']?.toString() == clubId || 
                             e['club_id']?.toString() == clubId)
                .toList();
          }
          return {'status': 200, 'body': {'results': filtered, 'count': filtered.length}};
        }
      }
      
      // Dùng filter by club_id
      return await eventApi.getEventsByClub(
        clubId,
        status: status,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      _dbg('Exception in getClubEvents: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// Lấy thông tin CLB
  Future<Map<String, dynamic>> getClubInfo(String clubId) async {
    _dbg('getClubInfo: clubId=$clubId');
    return await clubApi.getClubById(clubId);
  }

  /// Lấy thông báo của user
  Future<Map<String, dynamic>> getNotifications({bool? isRead}) async {
    _dbg('getNotifications: isRead=$isRead');
    return await notificationApi.getNotifications(isRead: isRead);
  }

  /// Lấy số thông báo chưa đọc
  Future<Map<String, dynamic>> getUnreadNotificationCount() async {
    _dbg('getUnreadNotificationCount');
    return await notificationApi.getUnreadCount();
  }

  /// Lấy danh sách người tham gia sự kiện
  Future<Map<String, dynamic>> getEventParticipants(String eventId, {String? status}) async {
    _dbg('getEventParticipants: eventId=$eventId, status=$status');
    return await eventApi.getEventParticipants(eventId, status: status);
  }

  /// Cập nhật sự kiện
  Future<Map<String, dynamic>> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    _dbg('updateEvent: eventId=$eventId');
    return await eventApi.updateEvent(eventId, eventData);
  }
  
  /// Tạo sự kiện mới cho CLB
  Future<Map<String, dynamic>> createEvent(String clubId, Map<String, dynamic> eventData) async {
    _dbg('createEvent: clubId=$clubId');
    return await clubApi.createEvent(clubId, eventData);
  }
}

