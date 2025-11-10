import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';

class NotificationApi {
  final Dio dio;

  NotificationApi({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  void _dbg(String s) {
    // ignore: avoid_print
    print('[NotificationApi] $s');
  }

  /// Get user's notifications
  Future<Map<String, dynamic>> getNotifications({
    required String accessToken,
    bool? isRead,
    int page = 1,
  }) async {
    _dbg('GET /api/notifications/notifications/');
    
    final queryParams = <String, dynamic>{
      'page': page,
    };
    
    if (isRead != null) queryParams['is_read'] = isRead.toString();
    
    try {
      final res = await dio.get(
        '/api/notifications/notifications/',
        queryParameters: queryParams,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg(
          'DioException on getNotifications: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception on getNotifications: $e');
      return {
        'status': 0,
        'body': {'detail': e.toString()}
      };
    }
  }

  /// Get unread count
  Future<Map<String, dynamic>> getUnreadCount({
    required String accessToken,
  }) async {
    _dbg('GET /api/notifications/notifications/unread_count/');
    
    try {
      final res = await dio.get(
        '/api/notifications/notifications/unread_count/',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg(
          'DioException on getUnreadCount: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception on getUnreadCount: $e');
      return {
        'status': 0,
        'body': {'detail': e.toString()}
      };
    }
  }

  /// Mark notification as read
  Future<Map<String, dynamic>> markAsRead({
    required String accessToken,
    required String notificationId,
  }) async {
    _dbg('POST /api/notifications/notifications/$notificationId/read/');
    
    try {
      final res = await dio.post(
        '/api/notifications/notifications/$notificationId/read/',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg(
          'DioException on markAsRead: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception on markAsRead: $e');
      return {
        'status': 0,
        'body': {'detail': e.toString()}
      };
    }
  }

  /// Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead({
    required String accessToken,
  }) async {
    _dbg('POST /api/notifications/notifications/mark_all_read/');
    
    try {
      final res = await dio.post(
        '/api/notifications/notifications/mark_all_read/',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg(
          'DioException on markAllAsRead: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception on markAllAsRead: $e');
      return {
        'status': 0,
        'body': {'detail': e.toString()}
      };
    }
  }
}

