import 'package:flutter/foundation.dart';
import 'package:event_connect/features/admin_dashboard/domain/repositories/admin_repository.dart';
import 'package:event_connect/features/admin_dashboard/domain/models/admin_stats.dart';

/// Service for Admin Dashboard operations
/// Manages admin-related data and state
class AdminService extends ChangeNotifier {
  final AdminRepository _repo;
  
  AdminStats? _stats;
  bool _isLoading = false;
  String? _error;
  
  AdminService({AdminRepository? repository}) 
      : _repo = repository ?? AdminRepository();
  
  AdminStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Fetch admin dashboard statistics
  Future<bool> fetchStats({String period = 'month'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _repo.getStats(period: period);
      
      if (response['status'] == 200) {
        final body = response['body'] as Map<String, dynamic>;
        _stats = AdminStats.fromJson(body);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to fetch statistics';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Fetch recent activities
  Future<Map<String, dynamic>> fetchActivities({int page = 1, int limit = 20}) async {
    return await _repo.getActivities(page: page, limit: limit);
  }
  
  /// Fetch pending approvals
  Future<Map<String, dynamic>> fetchPendingApprovals({int page = 1}) async {
    return await _repo.getPendingApprovals(page: page);
  }
  
  /// Approve an event
  Future<bool> approveEvent(String eventId, {String? comments}) async {
    final response = await _repo.approveEvent(eventId, comments: comments);
    return response['status'] == 200;
  }
  
  /// Reject an event
  Future<bool> rejectEvent(String eventId, {required String reason}) async {
    final response = await _repo.rejectEvent(eventId, reason: reason);
    return response['status'] == 200;
  }
  
  /// Fetch users list
  Future<Map<String, dynamic>> fetchUsers({
    String? role,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _repo.getUsers(
      role: role,
      search: search,
      page: page,
      pageSize: pageSize,
    );
  }
  
  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

