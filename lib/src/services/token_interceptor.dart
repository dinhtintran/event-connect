import 'dart:async';

import 'package:dio/dio.dart';

import 'token_storage.dart';
import '../config.dart';

/// Interceptor that attaches Authorization header and attempts refresh on 401.
class TokenInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio _dioNoAuth;

  // A lock / queue to ensure only one refresh runs at a time
  Completer<void>? _refreshCompleter;

  TokenInterceptor({required this.tokenStorage}) : _dioNoAuth = Dio(BaseOptions(baseUrl: apiBaseUrl));

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final access = await tokenStorage.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
    } catch (_) {}
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    // Only attempt refresh on 401 responses (and when original request was not a refresh request)
    if (response != null && response.statusCode == 401 && !err.requestOptions.path.contains('/token/refresh')) {
      try {
        // If a refresh is already running, wait for it
        if (_refreshCompleter != null) {
            await _refreshCompleter!.future;
          } else {
          _refreshCompleter = Completer<void>();
          final refresh = await tokenStorage.readRefresh();
          if (refresh == null) {
            _refreshCompleter!.complete();
            _refreshCompleter = null;
            return handler.next(err);
          }

          try {
            final r = await _dioNoAuth.post('/api/accounts/token/refresh/', data: {'refresh': refresh});
            if (r.statusCode == 200 && r.data != null && r.data['access'] != null) {
              final newAccess = r.data['access'] as String;
              await tokenStorage.save(access: newAccess, refresh: refresh);
            } else {
              // refresh failed
              await tokenStorage.clear();
            }
          } catch (_) {
            await tokenStorage.clear();
          }

          _refreshCompleter!.complete();
          _refreshCompleter = null;
        }

        // retry original request with new access token
        final newAccess = await tokenStorage.readAccess();
        if (newAccess != null) {
      final clone = await _dioNoAuth.request(err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: Options(method: err.requestOptions.method, headers: {...err.requestOptions.headers, 'Authorization': 'Bearer $newAccess'}));
          return handler.resolve(clone);
        }
      } catch (_) {
        // fallthrough
      }
    }
    handler.next(err);
  }
}
