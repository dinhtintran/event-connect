import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';

class EventApi {
  final Dio dio;

  EventApi({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  void _dbg(String s) {
    // ignore: avoid_print
    print('[EventApi] $s');
  }

  /// Get list of events with optional filters
  Future<Map<String, dynamic>> getEvents({
    String? status,
    String? category,
    bool? isFeatured,
    String? clubId,
    int page = 1,
    int pageSize = 10,
  }) async {
    _dbg('GET /api/event_management/events/');

    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };

    if (status != null) queryParams['status'] = status;
    if (category != null) queryParams['category'] = category;
    if (isFeatured != null) queryParams['is_featured'] = isFeatured.toString();
    if (clubId != null) queryParams['club_id'] = clubId;

    try {
      final res = await dio.get(
        '/api/event_management/events/',
        queryParameters: queryParams,
      );
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg(
          'DioException on getEvents: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception on getEvents: $e');
      return {
        'status': 0,
        'body': {'detail': e.toString()}
      };
    }
  }

  /// Get featured events
  Future<Map<String, dynamic>> getFeaturedEvents() async {
    return getEvents(isFeatured: true, status: 'approved', pageSize: 10);
  }

  /// Get upcoming events
  Future<Map<String, dynamic>> getUpcomingEvents({int page = 1}) async {
    return getEvents(status: 'approved', page: page, pageSize: 10);
  }

  /// Get event detail by ID
  Future<Map<String, dynamic>> getEventById(String id) async {
    _dbg('GET /api/event_management/events/$id/');
    try {
      final res = await dio.get('/api/event_management/events/$id/');
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg(
          'DioException on getEventById: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception on getEventById: $e');
      return {
        'status': 0,
        'body': {'detail': e.toString()}
      };
    }
  }

  /// Search events by keyword
  Future<Map<String, dynamic>> searchEvents(String keyword) async {
    _dbg('GET /api/event_management/events/?search=$keyword');
    try {
      final res = await dio.get(
        '/api/event_management/events/',
        queryParameters: {'search': keyword},
      );
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg(
          'DioException on searchEvents: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception on searchEvents: $e');
      return {
        'status': 0,
        'body': {'detail': e.toString()}
      };
    }
  }
}

