import 'package:dio/dio.dart';

/// Admin API - Handles all admin-related API calls
class AdminApi {
  final Dio dio;

  AdminApi({required this.dio});

  void _dbg(String msg) => print('[AdminApi] $msg');

  // ==================== USER MANAGEMENT ====================

  /// GET /api/accounts/admin/users/ - Get all users
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    String? search,
    String? role,
    String? faculty,
    bool? isActive,
  }) async {
    _dbg('GET /api/accounts/admin/users/');
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null) 'role': role,
        if (faculty != null) 'faculty': faculty,
        if (isActive != null) 'is_active': isActive,
      };
      
      final res = await dio.get('/api/accounts/admin/users/', queryParameters: queryParams);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    } catch (e) {
      _dbg('Exception: $e');
      return {'status': 0, 'body': {'detail': e.toString()}};
    }
  }

  /// GET /api/accounts/admin/users/{id}/ - Get user details
  Future<Map<String, dynamic>> getUserById(String userId) async {
    _dbg('GET /api/accounts/admin/users/$userId/');
    try {
      final res = await dio.get('/api/accounts/admin/users/$userId/');
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }

  /// PATCH /api/accounts/admin/users/{id}/ - Update user
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> data) async {
    _dbg('PATCH /api/accounts/admin/users/$userId/');
    try {
      final res = await dio.patch('/api/accounts/admin/users/$userId/', data: data);
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }

  /// DELETE /api/accounts/admin/users/{id}/ - Delete user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    _dbg('DELETE /api/accounts/admin/users/$userId/');
    try {
      final res = await dio.delete('/api/accounts/admin/users/$userId/');
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data ?? {}};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }

  /// POST /api/accounts/admin/users/{id}/activate/ - Activate user
  Future<Map<String, dynamic>> activateUser(String userId) async {
    _dbg('POST /api/accounts/admin/users/$userId/activate/');
    try {
      final res = await dio.post('/api/accounts/admin/users/$userId/activate/');
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }

  /// POST /api/accounts/admin/users/{id}/deactivate/ - Deactivate user
  Future<Map<String, dynamic>> deactivateUser(String userId) async {
    _dbg('POST /api/accounts/admin/users/$userId/deactivate/');
    try {
      final res = await dio.post('/api/accounts/admin/users/$userId/deactivate/');
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }

  // ==================== EVENT MANAGEMENT ====================

  /// GET /api/admin/events/ - Get all events (including pending)
  Future<Map<String, dynamic>> getAllEvents({
    int page = 1,
    String? search,
    String? status,
    String? clubId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _dbg('GET /api/admin/events/');
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        if (clubId != null) 'club_id': clubId,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };
      
      final res = await dio.get('/api/admin/events/', queryParameters: queryParams);
      _dbg('response ${res.statusCode} ${res.requestOptions.uri}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }

  /// DELETE /api/admin/events/{id}/ - Delete event (system admin only)
  Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    _dbg('DELETE /api/admin/events/$eventId/');
    try {
      final res = await dio.delete('/api/admin/events/$eventId/');
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data ?? {}};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }

  /// POST /api/admin/events/{id}/approve/ - Approve pending event
  Future<Map<String, dynamic>> approveEvent(String eventId, {String? comment}) async {
    _dbg('POST /api/admin/events/$eventId/approve/');
    try {
      final res = await dio.post(
        '/api/admin/events/$eventId/approve/',
        data: comment != null ? {'comment': comment} : null,
      );
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }

  /// POST /api/admin/events/{id}/reject/ - Reject pending event
  Future<Map<String, dynamic>> rejectEvent(String eventId, {required String reason}) async {
    _dbg('POST /api/admin/events/$eventId/reject/');
    try {
      final res = await dio.post(
        '/api/admin/events/$eventId/reject/',
        data: {'reason': reason},
      );
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }

  // ==================== STATISTICS ====================

  /// GET /api/admin/statistics/ - Get system statistics
  Future<Map<String, dynamic>> getStatistics() async {
    _dbg('GET /api/admin/statistics/');
    try {
      final res = await dio.get('/api/admin/statistics/');
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }

  // ==================== COMPATIBILITY METHODS ====================
  // For EventManagementScreen & ApprovalScreen (legacy compatibility)

  /// GET /api/approvals/pending/ - Get pending event approvals
  Future<Map<String, dynamic>> getPendingApprovals({int page = 1}) async {
    _dbg('GET /api/approvals/pending/');
    try {
      final res = await dio.get('/api/approvals/pending/', queryParameters: {'page': page});
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'count': 0, 'results': []}
      };
    }
  }

  /// GET /api/events/?status=approved - Get approved events
  Future<Map<String, dynamic>> getApprovedEvents({int page = 1}) async {
    _dbg('GET /api/events/?status=approved');
    try {
      final res = await dio.get('/api/events/', queryParameters: {'status': 'approved', 'page': page});
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'count': 0, 'results': []}
      };
    }
  }

  /// GET /api/event-cancellation-requests/pending/ - Get pending cancellation requests
  Future<Map<String, dynamic>> getPendingCancellationRequests() async {
    _dbg('GET /api/event-cancellation-requests/pending/');
    try {
      final res = await dio.get('/api/event-cancellation-requests/pending/');
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': []
      };
    }
  }

  /// POST /api/event-cancellation-requests/{id}/review/ - Review cancellation request
  Future<Map<String, dynamic>> reviewCancellationRequest({
    required int requestId,
    required String action,
    String? adminComment,
  }) async {
    _dbg('POST /api/event-cancellation-requests/$requestId/review/');
    try {
      final body = <String, dynamic>{
        'action': action,
        if (adminComment != null && adminComment.isNotEmpty) 'admin_comment': adminComment,
      };
      final res = await dio.post('/api/event-cancellation-requests/$requestId/review/', data: body);
      _dbg('response ${res.statusCode}');
      return {'status': res.statusCode, 'body': res.data};
    } on DioException catch (e) {
      _dbg('DioException: ${e.message}');
      return {
        'status': e.response?.statusCode ?? 0,
        'body': e.response?.data ?? {'detail': e.message}
      };
    }
  }
}
