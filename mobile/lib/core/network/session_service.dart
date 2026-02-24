import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_error.dart';
import 'backend_gateway.dart';

class SessionAuthException implements Exception {
  const SessionAuthException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'SessionAuthException($code): $message';
}

class SessionService {
  SessionService(this._gateway, this._tokens, this._dio);

  final BackendGateway _gateway;
  final SecureTokenStorage _tokens;
  final Dio _dio;

  bool _ready = false;

  Future<void> ensureReady({required String localeCode}) async {
    _dio.options.headers['Accept-Language'] =
        localeCode == 'ne' ? 'ne-NP' : 'en-US';

    final access = await _tokens.getAccessToken();
    if (access == null || access.isEmpty) {
      throw const SessionAuthException(
        code: 'UNAUTHENTICATED',
        message: 'Please sign in again.',
      );
    }

    _dio.options.headers['Authorization'] = 'Bearer $access';
    if (_ready) return;

    try {
      await _gateway.ensureStore(
        name: 'SME Store',
        localeCode: localeCode,
        currency: AppConfig.defaultCurrency,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await _tryRefreshTokens();
        if (!refreshed) {
          throw const SessionAuthException(
            code: 'UNAUTHENTICATED',
            message: 'Please sign in again.',
          );
        }
        await _gateway.ensureStore(
          name: 'SME Store',
          localeCode: localeCode,
          currency: AppConfig.defaultCurrency,
        );
      } else {
        // Keep app usable offline when backend is unavailable.
      }
    }

    _ready = true;
  }

  Future<void> login({
    required String phone,
    required String password,
    required String localeCode,
  }) async {
    final auth = await _gateway.login(phone: phone, password: password);
    await _applyAuth(auth, localeCode: localeCode);
  }

  Future<void> signup({
    required String businessName,
    required String phone,
    required String password,
    required String localeCode,
  }) async {
    try {
      final auth = await _gateway.register(
        phone: phone,
        password: password,
        businessName: businessName,
        localeDefault: localeCode,
        currency: AppConfig.defaultCurrency,
      );
      await _applyAuth(
        auth,
        localeCode: localeCode,
        businessName: businessName,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 409) rethrow;
      final auth = await _gateway.login(phone: phone, password: password);
      await _applyAuth(
        auth,
        localeCode: localeCode,
        businessName: businessName,
      );
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await _tokens.getRefreshToken();
      if (refresh != null && refresh.isNotEmpty) {
        await _gateway.logout(refreshToken: refresh);
      }
    } on DioException {
      // Logout should still clear local auth state if backend is unavailable.
    }
    _ready = false;
    _dio.options.headers.remove('Authorization');
    await _tokens.clear();
  }

  Future<String?> fetchCurrentUserRole({required String localeCode}) async {
    try {
      await ensureReady(localeCode: localeCode);
      final profile = await _gateway.getAuthMe();
      final role = profile['role']?.toString().trim().toLowerCase();
      if (role == null || role.isEmpty) return 'owner';
      return role;
    } on DioException {
      return null;
    } on SessionAuthException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyAuth(
    Map<String, dynamic> auth, {
    required String localeCode,
    String? businessName,
  }) async {
    final access = auth['access_token'] as String;
    final refresh = auth['refresh_token'] as String;
    await _tokens.saveTokens(access: access, refresh: refresh);
    _dio.options.headers['Authorization'] = 'Bearer $access';
    _ready = false;
    if (businessName != null && businessName.trim().isNotEmpty) {
      await _gateway.ensureStore(
        name: businessName.trim(),
        localeCode: localeCode,
        currency: AppConfig.defaultCurrency,
      );
      _ready = true;
      return;
    }
    await ensureReady(localeCode: localeCode);
  }

  Future<bool> _tryRefreshTokens() async {
    try {
      final refresh = await _tokens.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        _dio.options.headers.remove('Authorization');
        await _tokens.clear();
        _ready = false;
        throw const SessionAuthException(
          code: 'UNAUTHENTICATED',
          message: 'Please sign in again.',
        );
      }
      final auth = await _gateway.refresh(refreshToken: refresh);
      final access = auth['access_token'] as String?;
      final nextRefresh = auth['refresh_token'] as String?;
      if (access == null || access.isEmpty || nextRefresh == null || nextRefresh.isEmpty) {
        return false;
      }
      await _tokens.saveTokens(access: access, refresh: nextRefresh);
      _dio.options.headers['Authorization'] = 'Bearer $access';
      _ready = false;
      return true;
    } on DioException catch (e) {
      final apiError = ApiError.fromDio(e);
      _dio.options.headers.remove('Authorization');
      await _tokens.clear();
      _ready = false;
      if (apiError.statusCode == 401 || apiError.statusCode == 403) {
        final code = (apiError.code ?? 'UNAUTHENTICATED').toUpperCase();
        if (code == 'TOKEN_REVOKED' ||
            code == 'INVALID_TOKEN' ||
            code == 'INVALID_TOKEN_TYPE' ||
            code == 'USER_NOT_FOUND' ||
            code == 'UNAUTHENTICATED') {
          throw SessionAuthException(
            code: code,
            message: 'Session expired. Please sign in again.',
          );
        }
      }
      return false;
    }
  }
}
