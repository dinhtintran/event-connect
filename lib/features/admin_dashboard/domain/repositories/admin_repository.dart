import 'package:event_connect/core/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Repository for Admin Dashboard API calls
class AdminRepository {
  final _storage = const FlutterSecureStorage();
  /// Get admin dashboard statistics
  /// Returns: {'status': int, 'body': Map<String, dynamic>}
  Future<Map<String, dynamic>> getStats({String period = 'month'}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}api/admin/stats/?period=$period');
      final token = await _getToken();
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      return {
        'status': response.statusCode,
        'body': response.statusCode == 200 
            ? json.decode(response.body) 
            : {},
      };
    } catch (e) {
      return {'status': 0, 'body': {}};
    }
  }
  
  /// Get recent activities
  /// Returns: {'status': int, 'body': {'count': int, 'results': List}}
  Future<Map<String, dynamic>> getActivities({int page = 1, int limit = 20}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}api/admin/activities/?page=$page&limit=$limit');
      final token = await _getToken();
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      return {
        'status': response.statusCode,
        'body': response.statusCode == 200 
            ? json.decode(response.body) 
            : {'count': 0, 'results': []},
      };
    } catch (e) {
      return {'status': 0, 'body': {'count': 0, 'results': []}};
    }
  }
  
  /// Get pending events for approval
  /// Returns: {'status': int, 'body': {'count': int, 'results': List}}
  Future<Map<String, dynamic>> getPendingApprovals({int page = 1}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}api/approvals/pending/?page=$page');
      final token = await _getToken();
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      return {
        'status': response.statusCode,
        'body': response.statusCode == 200 
            ? json.decode(response.body) 
            : {'count': 0, 'results': []},
      };
    } catch (e) {
      return {'status': 0, 'body': {'count': 0, 'results': []}};
    }
  }
  
  /// Approve an event
  /// Returns: {'status': int, 'body': Map<String, dynamic>}
  Future<Map<String, dynamic>> approveEvent(String eventId, {String? comments}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}api/approvals/$eventId/approve/');
      final token = await _getToken();
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'comments': comments ?? ''}),
      );
      
      return {
        'status': response.statusCode,
        'body': response.statusCode == 200 
            ? json.decode(response.body) 
            : {},
      };
    } catch (e) {
      return {'status': 0, 'body': {}};
    }
  }
  
  /// Reject an event
  /// Returns: {'status': int, 'body': Map<String, dynamic>}
  Future<Map<String, dynamic>> rejectEvent(String eventId, {required String reason}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}api/approvals/$eventId/reject/');
      final token = await _getToken();
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );
      
      return {
        'status': response.statusCode,
        'body': response.statusCode == 200 
            ? json.decode(response.body) 
            : {},
      };
    } catch (e) {
      return {'status': 0, 'body': {}};
    }
  }
  
  /// Get users list (admin only)
  /// Returns: {'status': int, 'body': {'count': int, 'results': List}}
  Future<Map<String, dynamic>> getUsers({
    String? role,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      if (role != null) queryParams['role'] = role;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      
      final uri = Uri.parse('${AppConfig.apiBaseUrl}api/admin/users/').replace(queryParameters: queryParams);
      final token = await _getToken();
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      return {
        'status': response.statusCode,
        'body': response.statusCode == 200 
            ? json.decode(response.body) 
            : {'count': 0, 'results': []},
      };
    } catch (e) {
      return {'status': 0, 'body': {'count': 0, 'results': []}};
    }
  }
  
  /// Helper method to get access token from secure storage
  Future<String?> _getToken() async {
    try {
      // Use the same key as TokenStorage: 'auth_access'
      return await _storage.read(key: 'auth_access');
    } catch (e) {
      return null;
    }
  }
}

