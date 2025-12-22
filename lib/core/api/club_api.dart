import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:event_connect/core/api/dio_provider.dart';

/// ClubApi để quản lý CLB
class ClubApi {
  final Dio dio;

  ClubApi({Dio? dio}) : dio = dio ?? DioProvider.instance;

  void _dbg(String s) {
    // ignore: avoid_print
    print('[ClubApi] $s');
  }

  /// GET /api/clubs/clubs/ - Lấy danh sách tất cả CLB
  Future<Map<String, dynamic>> getAllClubs({String? status, String? faculty}) async {
    _dbg('GET /api/clubs/clubs/');
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (faculty != null) queryParams['faculty'] = faculty;
      
      final res = await dio.get('/api/clubs/clubs/', queryParameters: queryParams);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// GET /api/clubs/clubs/{id}/ - Lấy chi tiết một CLB
  Future<Map<String, dynamic>> getClubById(String id) async {
    _dbg('GET /api/clubs/clubs/$id/');
    try {
      final res = await dio.get('/api/clubs/clubs/$id/');
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      _dbg('response.data type: ${res.data.runtimeType}');
      
      // Handle String response (need to parse JSON manually)
      dynamic body = res.data;
      if (body is String) {
        _dbg('WARNING: Response is String, parsing JSON manually');
        try {
          body = jsonDecode(body);
        } catch (e) {
          _dbg('Failed to parse JSON: $e');
        }
      }
      
      return {'status': res.statusCode, 'body': body};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// GET /api/accounts/me/club/ - Lấy CLB gắn với user hiện tại
  Future<Map<String, dynamic>> getCurrentUserClub() async {
    _dbg('GET /api/accounts/me/club/');
    try {
      final res = await dio.get('/api/accounts/me/club/');
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      dynamic body = res.data;
      if (body is String) {
        _dbg('WARNING: Response is String, parsing JSON manually');
        try {
          body = jsonDecode(body);
        } catch (e) {
          _dbg('Failed to parse JSON: $e');
        }
      }
      return {'status': res.statusCode, 'body': body};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// POST /api/clubs/clubs/ - Tạo CLB mới (System Admin only)
  Future<Map<String, dynamic>> createClub(Map<String, dynamic> clubData) async {
    _dbg('POST /api/clubs/clubs/');
    try {
      final res = await dio.post('/api/clubs/clubs/', data: clubData);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// PUT /api/clubs/clubs/{id}/ - Cập nhật CLB
  Future<Map<String, dynamic>> updateClub(String id, Map<String, dynamic> clubData) async {
    _dbg('PUT /api/clubs/clubs/$id/');
    try {
      final res = await dio.put('/api/clubs/clubs/$id/', data: clubData);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// POST /api/clubs/clubs/{club_id}/events/ - Tạo sự kiện cho CLB (Club Admin)
  Future<Map<String, dynamic>> createEvent(String clubId, Map<String, dynamic> eventData) async {
    _dbg('POST /api/clubs/clubs/$clubId/events/');
    try {
      final res = await dio.post('/api/clubs/clubs/$clubId/events/', data: eventData);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// GET /api/clubs/clubs/{club_id}/events/ - Lấy danh sách sự kiện của CLB
  Future<Map<String, dynamic>> getClubEvents(String clubId) async {
    _dbg('GET /api/clubs/clubs/$clubId/events/');
    try {
      final res = await dio.get('/api/clubs/clubs/$clubId/events/');
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// GET /api/clubs/clubs/{club_id}/statistics/ - Lấy thống kê đã tổng hợp của CLB
  Future<Map<String, dynamic>> getClubStatistics(
    String clubId, {
    int? rangeDays,
    int? limitFeedback,
    int? limitHighlights,
  }) async {
    _dbg('GET /api/clubs/clubs/$clubId/statistics/');
    try {
      final queryParams = <String, dynamic>{};
      if (rangeDays != null) queryParams['range_days'] = rangeDays;
      if (limitFeedback != null) queryParams['limit_feedback'] = limitFeedback;
      if (limitHighlights != null) queryParams['limit_highlights'] = limitHighlights;

      final res = await dio.get('/api/clubs/clubs/$clubId/statistics/', queryParameters: queryParams);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// GET /api/clubs/clubs/{club_id}/statistics/raw-events/ - Lấy danh sách sự kiện thô phục vụ phân tích
  Future<Map<String, dynamic>> getClubStatisticsRawEvents(
    String clubId, {
    int? rangeDays,
    int? page,
    int? pageSize,
  }) async {
    _dbg('GET /api/clubs/clubs/$clubId/statistics/raw-events/');
    try {
      final queryParams = <String, dynamic>{};
      if (rangeDays != null) queryParams['range_days'] = rangeDays;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final res = await dio.get('/api/clubs/clubs/$clubId/statistics/raw-events/', queryParameters: queryParams);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }
}
