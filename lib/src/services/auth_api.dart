import 'package:dio/dio.dart';

/// AuthApi implemented using Dio. Expects a Dio instance configured with baseUrl.
class AuthApi {
  final Dio dio;

  AuthApi({Dio? dio}) : dio = dio ?? Dio();

  void _dbg(String s) {
    // Keep lightweight debug prints to help troubleshooting in dev
    // ignore: avoid_print
    print('[AuthApi] $s');
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    _dbg('POST /api/accounts/register/ payload: $body');
    try {
      final res = await dio.post('/api/accounts/register/', data: body);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException on register: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception on register: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> token(Map<String, dynamic> body) async {
    _dbg('POST /api/accounts/token/ payload: $body');
    try {
      final res = await dio.post('/api/accounts/token/', data: body);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException on token: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception on token: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> refresh(Map<String, dynamic> body) async {
    _dbg('POST /api/accounts/token/refresh/ payload: $body');
    try {
      final res = await dio.post('/api/accounts/token/refresh/', data: body);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException on refresh: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception on refresh: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> me({required String accessToken}) async {
    _dbg('GET /api/accounts/me/');
    try {
      final res = await dio.get('/api/accounts/me/');
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException on me: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception on me: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> logout({required String accessToken, required String refresh}) async {
    _dbg('POST /api/accounts/logout/ payload: {refresh: ******}');
    try {
      final res = await dio.post('/api/accounts/logout/', data: {'refresh': refresh});
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException on logout: type=${e.type} uri=${e.requestOptions.uri} status=${e.response?.statusCode} error=${e.message}');
      return {'status': e.response?.statusCode ?? 0, 'body': e.response?.data ?? {'detail': e.message}};
    } catch (e) {
      _dbg('Exception on logout: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }
}
