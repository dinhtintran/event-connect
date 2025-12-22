import 'package:flutter/foundation.dart';
import '../models/admin_user.dart';
import '../../data/repositories/admin_repository.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';

class AdminService extends ChangeNotifier {
  final AdminRepository repository;
  AdminService({required this.repository});

  // State
  List<AdminUser> _users = [];
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  List<AdminUser> get users => _users;
  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Future<void> loadUsers({int page = 1, String? search, String? role}) async {
    _setLoading(true);
    try {
      _users = await repository.getAllUsers(page: page, search: search, role: role);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _users = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEvents({int page = 1, String? status}) async {
    _setLoading(true);
    try {
      _events = await repository.getAllEvents(page: page, status: status);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _events = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> activateUser(String userId) async {
    try {
      final success = await repository.activateUser(userId);
      if (success) {
        await loadUsers();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deactivateUser(String userId) async {
    try {
      final success = await repository.deactivateUser(userId);
      if (success) await loadUsers();
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final success = await repository.deleteUser(userId);
      if (success) await loadUsers();
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Events
  Future<bool> approveEvent(String eventId, {String? comment}) async {
    try {
      final success = await repository.approveEvent(eventId, comment: comment);
      if (success) await loadEvents();
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> rejectEvent(String eventId, {required String reason}) async {
    try {
      final success = await repository.rejectEvent(eventId, reason: reason);
      if (success) await loadEvents();
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      final success = await repository.deleteEvent(eventId);
      if (success) await loadEvents();
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Compatibility methods for EventManagementScreen & ApprovalScreen
  Future<Map<String, dynamic>> fetchPendingApprovals() async {
    try {
      return await repository.fetchPendingApprovals();
    } catch (e) {
      _error = e.toString();
      return {'status': 0, 'body': {'count': 0, 'results': []}};
    }
  }

  Future<Map<String, dynamic>> fetchApprovedEvents() async {
    try {
      return await repository.fetchApprovedEvents();
    } catch (e) {
      _error = e.toString();
      return {'status': 0, 'body': {'count': 0, 'results': []}};
    }
  }

  Future<Map<String, dynamic>> fetchPendingCancellationRequests() async {
    try {
      return await repository.fetchPendingCancellationRequests();
    } catch (e) {
      _error = e.toString();
      return {'status': 0, 'body': []};
    }
  }

  Future<bool> reviewCancellationRequest({
    required int requestId,
    required String action,
    String? adminComment,
  }) async {
    try {
      return await repository.reviewCancellationRequest(
        requestId: requestId,
        action: action,
        adminComment: adminComment,
      );
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
