import 'package:dio/dio.dart';

/// ApprovalApi để quản lý phê duyệt sự kiện (Admin only)
class ApprovalApi {
  final Dio dio;

  ApprovalApi({Dio? dio}) : dio = dio ?? Dio();

  void _dbg(String s) {
    // ignore: avoid_print
    print('[ApprovalApi] $s');
  }

  /// GET /api/approvals/pending/ - Lấy danh sách sự kiện chờ duyệt
  Future<Map<String, dynamic>> getPendingApprovals() async {
    _dbg('GET /api/approvals/pending/');
    try {
      final res = await dio.get('/api/approvals/pending/');
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

  /// POST /api/approvals/{event_id}/approve/ - Duyệt sự kiện
  Future<Map<String, dynamic>> approveEvent(String eventId, {String? comment}) async {
    _dbg('POST /api/approvals/$eventId/approve/');
    try {
      final data = comment != null ? {'comment': comment} : null;
      final res = await dio.post('/api/approvals/$eventId/approve/', data: data);
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

  /// POST /api/approvals/{event_id}/reject/ - Từ chối sự kiện
  Future<Map<String, dynamic>> rejectEvent(String eventId, {required String comment}) async {
    _dbg('POST /api/approvals/$eventId/reject/');
    try {
      final res = await dio.post('/api/approvals/$eventId/reject/', data: {'comment': comment});
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

  /// GET /api/approvals/history/ - Lịch sử phê duyệt
  Future<Map<String, dynamic>> getApprovalHistory() async {
    _dbg('GET /api/approvals/history/');
    try {
      final res = await dio.get('/api/approvals/history/');
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
