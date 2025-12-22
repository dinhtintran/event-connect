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
      final uri = _buildUri('api/notifications/admin/stats/', queryParameters: {'period': period});
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
      final uri = _buildUri('api/notifications/admin/activities/', queryParameters: {
        'page': page,
        'limit': limit,
      });
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
      final uri = _buildUri('api/event_management/approvals/pending/', queryParameters: {'page': page});
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
      final uri = _buildUri('api/event_management/approvals/$eventId/approve/');
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
      final uri = _buildUri('api/event_management/approvals/$eventId/reject/');
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
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      
      if (role != null) queryParams['role'] = role;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      
      final uri = _buildUri('api/notifications/admin/users/', queryParameters: queryParams);
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
  
  Uri _buildUri(String path, {Map<String, dynamic>? queryParameters}) {
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl
        : '${AppConfig.apiBaseUrl}/';
    final uri = Uri.parse(base).resolve(path);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final normalized = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value == null) return;
      normalized[key] = value.toString();
    });

    return uri.replace(queryParameters: normalized);
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

