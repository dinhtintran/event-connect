import 'package:dio/dio.dart';
import 'package:event_connect/core/api/dio_provider.dart';

/// AdminApi để quản lý các tính năng admin
class AdminApi {
  final Dio dio;

  AdminApi({Dio? dio}) : dio = dio ?? DioProvider.instance;

  void _dbg(String s) {
    // ignore: avoid_print
    print('[AdminApi] $s');
  }

  /// GET /api/notifications/admin/stats/ - Lấy thống kê tổng quan
  Future<Map<String, dynamic>> getStats({String period = 'month'}) async {
    _dbg('GET /api/notifications/admin/stats/?period=$period');
    try {
      final res = await dio.get('/api/notifications/admin/stats/', queryParameters: {'period': period});
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

  /// GET /api/notifications/admin/activities/ - Lấy danh sách hoạt động gần đây
  Future<Map<String, dynamic>> getActivities({int page = 1, int limit = 20}) async {
    _dbg('GET /api/notifications/admin/activities/?page=$page&limit=$limit');
    try {
      final res = await dio.get('/api/notifications/admin/activities/', queryParameters: {
        'page': page,
        'limit': limit,
      });
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

  /// GET /api/notifications/admin/users/ - Quản lý người dùng
  Future<Map<String, dynamic>> getUsers({
    String? role,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    _dbg('GET /api/notifications/admin/users/');
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (role != null) queryParams['role'] = role;
      if (search != null) queryParams['search'] = search;

      final res = await dio.get('/api/notifications/admin/users/', queryParameters: queryParams);
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

  /// PUT /api/notifications/admin/users/{id}/ - Cập nhật quyền user
  Future<Map<String, dynamic>> updateUserRole(String userId, String role) async {
    _dbg('PUT /api/notifications/admin/users/$userId/');
    try {
      final res = await dio.put('/api/notifications/admin/users/$userId/', data: {'role': role});
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

  /// DELETE /api/notifications/admin/users/{id}/ - Xóa user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    _dbg('DELETE /api/notifications/admin/users/$userId/');
    try {
      final res = await dio.delete('/api/notifications/admin/users/$userId/');
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
