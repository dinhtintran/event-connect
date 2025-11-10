import 'package:dio/dio.dart';
import 'package:event_connect/core/config/app_config.dart';

/// AdminApi để quản lý các tính năng admin
class AdminApi {
  final Dio dio;

  AdminApi({Dio? dio}) : dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  void _dbg(String s) {
    // ignore: avoid_print
    print('[AdminApi] $s');
  }

  /// GET /api/admin/stats/ - Lấy thống kê tổng quan
  Future<Map<String, dynamic>> getStats({String period = 'month'}) async {
    _dbg('GET /api/admin/stats/?period=$period');
    try {
      final res = await dio.get('/api/admin/stats/', queryParameters: {'period': period});
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

  /// GET /api/admin/activities/ - Lấy danh sách hoạt động gần đây
  Future<Map<String, dynamic>> getActivities({int page = 1, int limit = 20}) async {
    _dbg('GET /api/admin/activities/?page=$page&limit=$limit');
    try {
      final res = await dio.get('/api/admin/activities/', queryParameters: {
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

  /// GET /api/admin/users/ - Quản lý người dùng
  Future<Map<String, dynamic>> getUsers({
    String? role,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    _dbg('GET /api/admin/users/');
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (role != null) queryParams['role'] = role;
      if (search != null) queryParams['search'] = search;

      final res = await dio.get('/api/admin/users/', queryParameters: queryParams);
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

  /// PUT /api/admin/users/{id}/ - Cập nhật quyền user
  Future<Map<String, dynamic>> updateUserRole(String userId, String role) async {
    _dbg('PUT /api/admin/users/$userId/');
    try {
      final res = await dio.put('/api/admin/users/$userId/', data: {'role': role});
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

  /// DELETE /api/admin/users/{id}/ - Xóa user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    _dbg('DELETE /api/admin/users/$userId/');
    try {
      final res = await dio.delete('/api/admin/users/$userId/');
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
