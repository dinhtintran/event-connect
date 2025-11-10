import 'package:dio/dio.dart';
import 'package:event_connect/core/config/app_config.dart';

/// NotificationApi để quản lý thông báo
class NotificationApi {
  final Dio dio;

  NotificationApi({Dio? dio}) : dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  void _dbg(String s) {
    // ignore: avoid_print
    print('[NotificationApi] $s');
  }

  /// GET /api/notifications/ - Lấy danh sách thông báo
  Future<Map<String, dynamic>> getNotifications({bool? isRead}) async {
    _dbg('GET /api/notifications/');
    try {
      final queryParams = <String, dynamic>{};
      if (isRead != null) {
        queryParams['is_read'] = isRead;
      }
      final res = await dio.get('/api/notifications/', queryParameters: queryParams);
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

  /// POST /api/notifications/{id}/read/ - Đánh dấu thông báo đã đọc
  Future<Map<String, dynamic>> markAsRead(String id) async {
    _dbg('POST /api/notifications/$id/read/');
    try {
      final res = await dio.post('/api/notifications/$id/read/');
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

  /// GET /api/notifications/unread-count/ - Lấy số thông báo chưa đọc
  Future<Map<String, dynamic>> getUnreadCount() async {
    _dbg('GET /api/notifications/unread-count/');
    try {
      final res = await dio.get('/api/notifications/unread-count/');
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

  /// POST /api/notifications/mark-all-read/ - Đánh dấu tất cả thông báo đã đọc
  Future<Map<String, dynamic>> markAllAsRead() async {
    _dbg('POST /api/notifications/mark-all-read/');
    try {
      final res = await dio.post('/api/notifications/mark-all-read/');
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
