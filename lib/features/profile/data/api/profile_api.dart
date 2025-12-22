import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';

class ProfileApi {
  final Dio dio;

  ProfileApi({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  void _dbg(String s) {
    // ignore: avoid_print
    print('[ProfileApi] $s');
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile({required String accessToken}) async {
    _dbg('GET /api/accounts/me/');
    try {
      final res = await dio.get(
        '/api/accounts/me/',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg(
          'DioException on getProfile: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception on getProfile: $e');
      return {
        'status': 0,
        'body': {'detail': e.toString()}
      };
    }
  }

  /// Logout user
  Future<Map<String, dynamic>> logout({
    required String accessToken,
    required String refreshToken,
  }) async {
    _dbg('POST /api/accounts/logout/');
    try {
      final res = await dio.post(
        '/api/accounts/logout/',
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg(
          'DioException on logout: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception on logout: $e');
      return {
        'status': 0,
        'body': {'detail': e.toString()}
      };
    }
  }
}

