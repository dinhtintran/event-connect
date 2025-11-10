import 'package:dio/dio.dart';

/// EventApi để gọi các endpoint liên quan đến Event
class EventApi {
  final Dio dio;

  EventApi({Dio? dio}) : dio = dio ?? Dio();

  void _dbg(String s) {
    // ignore: avoid_print
    print('[EventApi] $s');
  }

  /// GET /api/events/ - Lấy danh sách tất cả sự kiện
  Future<Map<String, dynamic>> getAllEvents() async {
    _dbg('GET /api/events/');
    try {
      final res = await dio.get('/api/events/');
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

  /// GET /api/events/{id}/ - Lấy chi tiết một sự kiện
  Future<Map<String, dynamic>> getEventById(String id) async {
    _dbg('GET /api/events/$id/');
    try {
      final res = await dio.get('/api/events/$id/');
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

  /// GET /api/events/featured/ - Lấy danh sách sự kiện nổi bật
  Future<Map<String, dynamic>> getFeaturedEvents() async {
    _dbg('GET /api/events/featured/');
    try {
      final res = await dio.get('/api/events/featured/');
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

  /// GET /api/events/search/?q={query} - Tìm kiếm sự kiện
  Future<Map<String, dynamic>> searchEvents(String query) async {
    _dbg('GET /api/events/search/?q=$query');
    try {
      final res = await dio.get('/api/events/search/', queryParameters: {'q': query});
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

  /// GET /api/events/?category={category} - Lọc sự kiện theo danh mục
  Future<Map<String, dynamic>> filterEventsByCategory(String category) async {
    _dbg('GET /api/events/?category=$category');
    try {
      final res = await dio.get('/api/events/', queryParameters: {'category': category});
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

  /// POST /api/events/{id}/register/ - Đăng ký tham gia sự kiện
  Future<Map<String, dynamic>> registerForEvent(String eventId) async {
    _dbg('POST /api/events/$eventId/register/');
    try {
      final res = await dio.post('/api/events/$eventId/register/');
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

  /// POST /api/events/{id}/unregister/ - Hủy đăng ký sự kiện
  Future<Map<String, dynamic>> unregisterFromEvent(String eventId) async {
    _dbg('POST /api/events/$eventId/unregister/');
    try {
      final res = await dio.post('/api/events/$eventId/unregister/');
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

  /// GET /api/registrations/my-events/ - Lấy danh sách sự kiện đã đăng ký
  Future<Map<String, dynamic>> getMyRegisteredEvents() async {
    _dbg('GET /api/registrations/my-events/');
    try {
      final res = await dio.get('/api/registrations/my-events/');
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

  /// POST /api/events/{id}/feedback/ - Gửi feedback cho sự kiện
  Future<Map<String, dynamic>> submitFeedback(String eventId, Map<String, dynamic> feedbackData) async {
    _dbg('POST /api/events/$eventId/feedback/');
    try {
      final res = await dio.post('/api/events/$eventId/feedback/', data: feedbackData);
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

  /// GET /api/events/{id}/feedbacks/ - Lấy danh sách feedback của sự kiện
  Future<Map<String, dynamic>> getEventFeedbacks(String eventId) async {
    _dbg('GET /api/events/$eventId/feedbacks/');
    try {
      final res = await dio.get('/api/events/$eventId/feedbacks/');
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
