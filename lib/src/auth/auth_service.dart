import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_repository.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// AuthService that uses AuthRepository to call real API and persist tokens.
class AuthService extends ChangeNotifier {
  final AuthRepository _repo;
  User? _user;
  String? _access;

  AuthService({AuthRepository? repository}) : _repo = repository ?? AuthRepository() {
    // attempt to initialize stored tokens/user on creation
    init();
  }

  User? get user => _user;

  bool get isAuthenticated => _access != null && _user != null;

  /// Initialize from stored tokens (optional call at app start)
  Future<void> init() async {
    final access = await _repo.getAccess();
    final refresh = await _repo.getRefresh();
    if (access != null) {
      _access = access;
      // check expiry
      if (JwtDecoder.isExpired(access)) {
        // try refresh
        final refreshed = await refreshAccess();
        if (!refreshed) {
          await _repo.clearTokens();
          _access = null;
          _user = null;
          notifyListeners();
          return;
        }
      }
      try {
        final me = await _repo.me(access);
        if (me['status'] == 200 && me['body']['ok'] == true) {
          _user = User.fromJson(me['body']['user']);
          notifyListeners();
          return;
        }
      } catch (_) {}
      // if access invalid, try refresh
      if (refresh != null) {
        final r = await _repo.refresh(refresh);
        if (r['status'] == 200 && r['body']['access'] != null) {
          _access = r['body']['access'];
          await _repo.saveTokens(access: _access!, refresh: refresh);
          final me = await _repo.me(_access!);
          if (me['status'] == 200 && me['body']['ok'] == true) {
            _user = User.fromJson(me['body']['user']);
            notifyListeners();
            return;
          }
        }
      }
    }
    // not authenticated
    await _repo.clearTokens();
    _access = null;
    _user = null;
    notifyListeners();
  }

  /// Login using username (or email) and password
  Future<bool> loginWithCredentials({required String username, required String password}) async {
    final resp = await _repo.login({'username': username, 'password': password});
    if (resp['status'] == 200 && resp['body']['access'] != null && resp['body']['refresh'] != null) {
      final access = resp['body']['access'] as String;
      final refresh = resp['body']['refresh'] as String;
      await _repo.saveTokens(access: access, refresh: refresh);
      _access = access;
      // fetch user
      final me = await _repo.me(access);
      if (me['status'] == 200 && me['body']['ok'] == true) {
        _user = User.fromJson(me['body']['user']);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Detailed login that returns backend response for field-level errors
  Future<Map<String, dynamic>> loginDetailed({required String username, required String password}) async {
    final resp = await _repo.login({'username': username, 'password': password});
    if (resp['status'] == 200 && resp['body']['access'] != null && resp['body']['refresh'] != null) {
      final access = resp['body']['access'] as String;
      final refresh = resp['body']['refresh'] as String;
      await _repo.saveTokens(access: access, refresh: refresh);
      _access = access;
      final me = await _repo.me(access);
      if (me['status'] == 200 && me['body']['ok'] == true) {
        _user = User.fromJson(me['body']['user']);
        notifyListeners();
      }
    }
    return resp;
  }

  // Backwards-compatible wrapper used by existing UI (role, email, password)
  Future<bool> loginWithRole({required String role, required String email, required String password}) async {
    return await loginWithCredentials(username: email, password: password);
  }

  // Legacy-compatible method signature used by UI: login(role:, email:, password:)
  Future<bool> login({required String role, required String email, required String password}) async {
    return await loginWithRole(role: role, email: email, password: password);
  }

  /// Register new account and store tokens
  Future<bool> registerWithPayload({required Map<String, dynamic> payload}) async {
    final resp = await _repo.register(payload);
    if (resp['status'] == 201 && resp['body']['access'] != null && resp['body']['refresh'] != null) {
      final access = resp['body']['access'] as String;
      final refresh = resp['body']['refresh'] as String;
      await _repo.saveTokens(access: access, refresh: refresh);
      _access = access;
      final userJson = resp['body']['user'] as Map<String, dynamic>;
      _user = User.fromJson(userJson);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Detailed register returning raw backend response so UI can show validation errors
  Future<Map<String, dynamic>> registerDetailed({required Map<String, dynamic> payload}) async {
    final resp = await _repo.register(payload);
    if (resp['status'] == 201 && resp['body']['access'] != null && resp['body']['refresh'] != null) {
      final access = resp['body']['access'] as String;
      final refresh = resp['body']['refresh'] as String;
      await _repo.saveTokens(access: access, refresh: refresh);
      _access = access;
      final userJson = resp['body']['user'] as Map<String, dynamic>;
      _user = User.fromJson(userJson);
      notifyListeners();
    }
    return resp;
  }

  // Backwards-compatible wrapper matching previous UI signature
  Future<bool> registerWithRole({required String role, required String name, required String email, required String password}) async {
    final map = <String, dynamic>{
      'username': email,
      'password': password,
      'email': email,
      'role': role,
      'display_name': name,
    };
    // role-specific fields may be added by caller in UI if available
    return await registerWithPayload(payload: map);
  }

  // Legacy-compatible method signature used by UI: register(role:, name:, email:, password:)
  Future<bool> register({required String role, required String name, required String email, required String password}) async {
    return await registerWithRole(role: role, name: name, email: email, password: password);
  }

  /// Try to refresh access token using stored refresh token
  Future<bool> refreshAccess() async {
    final refresh = await _repo.getRefresh();
    if (refresh == null) return false;
    final r = await _repo.refresh(refresh);
    if (r['status'] == 200 && r['body']['access'] != null) {
      final access = r['body']['access'] as String;
      _access = access;
      await _repo.saveTokens(access: access, refresh: refresh);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Logout: optional blacklist refresh and clear local tokens
  Future<bool> logout() async {
    final access = await _repo.getAccess();
    final refresh = await _repo.getRefresh();
    if (access != null && refresh != null) {
      final res = await _repo.logout(access, refresh);
      // even if blacklist fails, continue to clear local tokens
      await _repo.clearTokens();
      _access = null;
      _user = null;
      notifyListeners();
      return res['status'] == 200;
    }
    await _repo.clearTokens();
    _access = null;
    _user = null;
    notifyListeners();
    return true;
  }
}
