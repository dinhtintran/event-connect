import 'package:dio/dio.dart';
import 'package:event_connect/core/config/app_config.dart';
import 'package:event_connect/core/interceptors/token_interceptor.dart';
import 'package:event_connect/features/authentication/data/storage/token_storage.dart';

/// Singleton Dio provider with TokenInterceptor
/// Use this to ensure all API calls have authentication
class DioProvider {
  static Dio? _instance;
  
  /// Get shared Dio instance with TokenInterceptor
  static Dio get instance {
    if (_instance == null) {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      
      // Add token interceptor for authentication
      final tokenStorage = TokenStorage();
      dio.interceptors.add(TokenInterceptor(tokenStorage: tokenStorage));
      
      _instance = dio;
    }
    return _instance!;
  }
  
  /// Reset instance (useful for logout or testing)
  static void reset() {
    _instance = null;
  }
}
