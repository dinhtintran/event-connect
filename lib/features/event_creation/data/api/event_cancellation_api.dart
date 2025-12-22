import 'package:dio/dio.dart';
import 'package:event_connect/core/api/dio_provider.dart';

/// API cho tính năng yêu cầu hủy sự kiện
class EventCancellationApi {
  final Dio dio;

  EventCancellationApi({Dio? dio}) : dio = dio ?? DioProvider.instance;

  void _dbg(String s) {
    // ignore: avoid_print
    print('[EventCancellationApi] $s');
  }

  /// POST /api/events/{event_id}/request_cancellation/ - Club Admin tạo yêu cầu hủy sự kiện
  Future<Map<String, dynamic>> requestCancellation({
    required String eventId,
    required String reason,
    String? refundPolicy,
    String? alternativeAction,
  }) async {
    _dbg('POST /api/events/$eventId/request_cancellation/');
    try {
      final data = {
        'reason': reason,
        if (refundPolicy != null && refundPolicy.isNotEmpty) 
          'refund_policy': refundPolicy,
        if (alternativeAction != null && alternativeAction.isNotEmpty) 
          'alternative_action': alternativeAction,
      };
      
      final res = await dio.post(
        '/api/events/$eventId/request_cancellation/',
        data: data,
      );
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// GET /api/events/{event_id}/cancellation_requests/ - Xem yêu cầu hủy của sự kiện
  Future<Map<String, dynamic>> getEventCancellationRequests(String eventId) async {
    _dbg('GET /api/events/$eventId/cancellation_requests/');
    try {
      final res = await dio.get('/api/events/$eventId/cancellation_requests/');
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// GET /api/event_management/event-cancellation-requests/pending/ - System Admin lấy yêu cầu pending
  Future<Map<String, dynamic>> getPendingRequests() async {
    _dbg('GET /api/event_management/event-cancellation-requests/pending/');
    try {
      final res = await dio.get('/api/event_management/event-cancellation-requests/pending/');
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// POST /api/event_management/event-cancellation-requests/{id}/review/ - System Admin xét duyệt
  Future<Map<String, dynamic>> reviewRequest({
    required int requestId,
    required String action, // 'approve' | 'reject'
    String? adminComment,
  }) async {
    _dbg('POST /api/event_management/event-cancellation-requests/$requestId/review/');
    try {
      final data = {
        'action': action,
        if (adminComment != null && adminComment.isNotEmpty) 
          'admin_comment': adminComment,
      };
      
      final res = await dio.post(
        '/api/event_management/event-cancellation-requests/$requestId/review/',
        data: data,
      );
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: type=${e.type} status=${e.response?.statusCode} error=${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }
}
