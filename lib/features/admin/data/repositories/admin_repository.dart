import '../api/admin_api.dart';
import '../../domain/models/admin_user.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';

/// AdminRepository - thin wrapper over AdminApi to return domain models
class AdminRepository {
  final AdminApi api;
  AdminRepository({required this.api});

  Future<List<AdminUser>> getAllUsers({int page = 1, String? search, String? role, String? faculty, bool? isActive}) async {
    final res = await api.getAllUsers(page: page, search: search, role: role, faculty: faculty, isActive: isActive);
    if (res['status'] == 200) {
      final body = res['body'];
      if (body is Map<String, dynamic> && body.containsKey('results')) {
        final List<dynamic> items = body['results'] as List<dynamic>;
        return items.map((j) => AdminUser.fromJson(j as Map<String, dynamic>)).toList();
      }
      // fallback if API returns list directly
      if (body is List) {
        return body.map((j) => AdminUser.fromJson(j as Map<String, dynamic>)).toList();
      }
      return [];
    }
    throw Exception(res['body']?['detail'] ?? 'Failed to fetch users');
  }

  Future<AdminUser> getUserById(String userId) async {
    final res = await api.getUserById(userId);
    if (res['status'] == 200) {
      return AdminUser.fromJson(res['body'] as Map<String, dynamic>);
    }
    throw Exception(res['body']?['detail'] ?? 'Failed to fetch user');
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    final res = await api.updateUser(userId, data);
    return res['status'] == 200 || res['status'] == 204;
  }

  Future<bool> deleteUser(String userId) async {
    final res = await api.deleteUser(userId);
    return res['status'] == 200 || res['status'] == 204;
  }

  Future<bool> activateUser(String userId) async {
    final res = await api.activateUser(userId);
    return res['status'] == 200 || res['status'] == 204;
  }

  Future<bool> deactivateUser(String userId) async {
    final res = await api.deactivateUser(userId);
    return res['status'] == 200 || res['status'] == 204;
  }

  // Events
  Future<List<Event>> getAllEvents({int page = 1, String? search, String? status, String? clubId}) async {
    final res = await api.getAllEvents(page: page, search: search, status: status, clubId: clubId);
    if (res['status'] == 200) {
      final body = res['body'];
      if (body is Map<String, dynamic> && body.containsKey('results')) {
        final List<dynamic> items = body['results'] as List<dynamic>;
        return items.map((j) => Event.fromJson(j as Map<String, dynamic>)).toList();
      }
      if (body is List) {
        return body.map((j) => Event.fromJson(j as Map<String, dynamic>)).toList();
      }
      return [];
    }
    throw Exception(res['body']?['detail'] ?? 'Failed to fetch events');
  }

  Future<bool> approveEvent(String eventId, {String? comment}) async {
    final res = await api.approveEvent(eventId, comment: comment);
    return res['status'] == 200 || res['status'] == 204;
  }

  Future<bool> rejectEvent(String eventId, {required String reason}) async {
    final res = await api.rejectEvent(eventId, reason: reason);
    return res['status'] == 200 || res['status'] == 204;
  }

  Future<bool> deleteEvent(String eventId) async {
    final res = await api.deleteEvent(eventId);
    return res['status'] == 200 || res['status'] == 204;
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final res = await api.getStatistics();
    return res;
  }

  // Compatibility methods for EventManagementScreen & ApprovalScreen
  Future<Map<String, dynamic>> fetchPendingApprovals() async {
    return await api.getPendingApprovals();
  }

  Future<Map<String, dynamic>> fetchApprovedEvents() async {
    return await api.getApprovedEvents();
  }

  Future<Map<String, dynamic>> fetchPendingCancellationRequests() async {
    return await api.getPendingCancellationRequests();
  }

  Future<bool> reviewCancellationRequest({
    required int requestId,
    required String action,
    String? adminComment,
  }) async {
    final res = await api.reviewCancellationRequest(
      requestId: requestId,
      action: action,
      adminComment: adminComment,
    );
    return res['status'] == 200 || res['status'] == 204;
  }
}
