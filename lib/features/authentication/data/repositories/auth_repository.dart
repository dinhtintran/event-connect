import 'package:event_connect/features/authentication/data/api/auth_api.dart';
import 'package:event_connect/features/authentication/data/storage/token_storage.dart';

class AuthRepository {
  final AuthApi api;
  final TokenStorage _tokenStorage;

  AuthRepository({AuthApi? api, TokenStorage? tokenStorage})
      : api = api ?? AuthApi(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _tokenStorage.save(access: access, refresh: refresh);
  }

  Future<String?> getAccess() async => await _tokenStorage.readAccess();
  Future<String?> getRefresh() async => await _tokenStorage.readRefresh();

  Future<void> clearTokens() async => await _tokenStorage.clear();

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    return await api.register(body);
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> body) async {
    return await api.token(body);
  }

  Future<Map<String, dynamic>> refresh(String refresh) async {
    return await api.refresh({'refresh': refresh});
  }

  Future<Map<String, dynamic>> me(String access) async {
    return await api.me(accessToken: access);
  }

  Future<Map<String, dynamic>> logout(String access, String refresh) async {
    return await api.logout(accessToken: access, refresh: refresh);
  }
}

