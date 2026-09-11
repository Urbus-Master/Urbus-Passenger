import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../constants/api_constants.dart';
import '../providers/auth_provider.dart';
import 'base_client.dart';

// ── Exceptions ────────────────────────────────────────────────────────────────

/// Typed auth exceptions — never expose raw Dio errors to the UI.
class AuthException implements Exception {
  const AuthException(this.message, this.type);

  final String message;
  final AuthExceptionType type;

  @override
  String toString() => message;
}

enum AuthExceptionType {
  invalidCredentials,
  accountDisabled,
  networkError,
  serverError,
  sessionExpired,
  unknown,
}

// ── Auth service ──────────────────────────────────────────────────────────────

/// Handles all authentication operations against the Traccar backend.
///
/// Traccar authentication:
/// - Login  → POST /api/session with form-encoded email + password
/// - Auth   → HTTP Basic Auth header (base64 encoded credentials)
/// - Session → Traccar returns a Set-Cookie that must be sent on all requests
/// - Logout → DELETE /api/session
///
/// There are no JWT tokens in Traccar — session is cookie-based.
class AuthService {
  AuthService({required Dio dio, required AuthNotifier authNotifier})
      : _dio = dio,
        _authNotifier = authNotifier;

  final Dio _dio;
  final AuthNotifier _authNotifier;

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Authenticates against Traccar POST /api/session.
  ///
  /// Traccar expects form-encoded body:
  /// `email=user@example.com&password=secret`
  ///
  /// On success: persists session via [AuthNotifier.login] and returns user.
  /// On failure: throws typed [AuthException] — never a raw DioException.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // Traccar /api/session requires Basic Auth header.
      final credentials = base64Encode(utf8.encode('$email:$password'));

      final response = await _dio.post(
        ApiConstants.session,
        data: 'email=${Uri.encodeComponent(email)}'
            '&password=${Uri.encodeComponent(password)}',
        options: Options(
          contentType: ApiConstants.contentTypeForm,
          headers: {
            ApiConstants.authorizationHeader: 'Basic $credentials',
          },
        ),
      );

      // Parse Traccar session response into UserModel.
      final user = UserModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Persist session data and flip auth state.
      await _authNotifier.login(user: user);

      return user;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (_) {
      throw const AuthException(
        'Error inesperado. Intenta de nuevo.',
        AuthExceptionType.unknown,
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// Invalidates the Traccar session server-side (DELETE /api/session),
  /// then clears local session regardless of server response.
  Future<void> logout() async {
    try {
      await _dio.delete(ApiConstants.session);
    } catch (_) {
      // Server-side logout failure is non-critical —
      // local session is always cleared.
    } finally {
      await _authNotifier.logout();
    }
  }

  // ── Password reset ────────────────────────────────────────────────────────

  /// Sends a password reset email via Traccar (mocked/stubbed).
  Future<void> requestPasswordReset(String email) async {
    // Traccar doesn't have a standard public password reset API out-of-the-box
    // in all versions, so we mock it for now.
    await Future.delayed(const Duration(seconds: 1));
  }

  // ── Session restore ───────────────────────────────────────────────────────

  /// Called from SplashScreen on app launch.
  /// Restores cached session, then validates it against Traccar.
  Future<bool> restoreSession() async {
    await _authNotifier.restoreSession();

    if (!_authNotifier.isAuthenticated) return false;

    // Validate session is still active server-side.
    try {
      await _validateSession();
      return true;
    } on AuthException catch (e) {
      if (e.type == AuthExceptionType.sessionExpired ||
          e.type == AuthExceptionType.invalidCredentials) {
        await _authNotifier.logout();
        return false;
      }
      // Network/server errors — keep local session alive.
      // User will see errors when fetching live data.
      return _authNotifier.isAuthenticated;
    }
  }

  // ── Session validation ────────────────────────────────────────────────────

  /// Validates the current session against Traccar GET /api/session.
  /// Returns the current user if the session is valid.
  Future<UserModel> _validateSession() async {
    try {
      final response = await _dio.get(ApiConstants.session);
      return UserModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── Current session ───────────────────────────────────────────────────────

  /// Fetches the current authenticated user from Traccar.
  /// Used to refresh user data after profile updates.
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.session);
      return UserModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  /// Converts raw Dio errors into typed, Spanish-language auth exceptions.
  AuthException _mapDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout   ||
      DioExceptionType.sendTimeout      =>
        const AuthException(
          'Tiempo de conexión agotado. Verifica tu red.',
          AuthExceptionType.networkError,
        ),
      DioExceptionType.connectionError =>
        const AuthException(
          'Sin conexión a internet.',
          AuthExceptionType.networkError,
        ),
      DioExceptionType.badResponse =>
        _mapStatusCode(e.response?.statusCode, e.response?.data),
      _ =>
        const AuthException(
          'Error inesperado. Intenta de nuevo.',
          AuthExceptionType.unknown,
        ),
    };
  }

  AuthException _mapStatusCode(int? statusCode, dynamic data) {
    final serverMessage =
        data is Map ? data['message'] as String? : null;

    return switch (statusCode) {
      400 => AuthException(
          serverMessage ?? 'Datos incorrectos. Revisa tus credenciales.',
          AuthExceptionType.invalidCredentials,
        ),
      401 => const AuthException(
          'Correo o contraseña incorrectos.',
          AuthExceptionType.invalidCredentials,
        ),
      403 => const AuthException(
          'Tu cuenta está desactivada. Contacta al administrador.',
          AuthExceptionType.accountDisabled,
        ),
      419 || 440 => const AuthException(
          'Sesión expirada. Inicia sesión nuevamente.',
          AuthExceptionType.sessionExpired,
        ),
      _ when (statusCode ?? 0) >= 500 => const AuthException(
          'Error del servidor. Intenta más tarde.',
          AuthExceptionType.serverError,
        ),
      _ => AuthException(
          serverMessage ?? 'Error inesperado.',
          AuthExceptionType.unknown,
        ),
    };
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Auth service provider — depends on Dio and AuthNotifier.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    dio:          ref.watch(dioProvider),
    authNotifier: ref.read(authProvider.notifier),
  );
});
