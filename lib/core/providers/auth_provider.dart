import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

// ── Auth status ───────────────────────────────────────────────────────────────

enum AuthStatus { unknown, loading, authenticated, unauthenticated }

// ── Auth state ────────────────────────────────────────────────────────────────

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        user = null,
        errorMessage = null;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        errorMessage = null;

  const AuthState.unauthenticated({String? error})
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = error;

  const AuthState.authenticated(this.user)
      : status = AuthStatus.authenticated,
        errorMessage = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isUnknown => status == AuthStatus.unknown;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      status.hashCode ^ user.hashCode ^ errorMessage.hashCode;

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.email})';
}

// ── Session storage ───────────────────────────────────────────────────────────

class _SessionStorage {
  final _storage = const FlutterSecureStorage();

  Future<void> save({
    required String userId,
    required String email,
    required String name,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.keyUserId,    value: userId),
      _storage.write(key: AppConstants.keyUserEmail, value: email),
      _storage.write(key: AppConstants.keyUserName,  value: name),
    ]);
  }

  Future<Map<String, String?>> read() async {
    return await _storage.readAll();
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

// ── Auth notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  final _session = _SessionStorage();

  @override
  AuthState build() {
    // Restaurar sesión de forma asíncrona pero sin bloquear el build síncrono.
    Future.microtask(() => restoreSession());
    return const AuthState.unknown();
  }

  Future<void> restoreSession() async {
    final data = await _session.read();
    final userId = data[AppConstants.keyUserId];

    if (userId != null) {
      state = AuthState.authenticated(UserModel(
        id: int.parse(userId),
        email: data[AppConstants.keyUserEmail] ?? '',
        name: data[AppConstants.keyUserName] ?? '',
        isActive: true,
        createdAt: DateTime.now(),
      ));
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  /// Public getter to avoid 'invalid_use_of_protected_member' warnings in services.
  AuthState get currentState => state;
  bool get isAuthenticated => state.isAuthenticated;

  Future<void> login({required UserModel user}) async {
    state = const AuthState.loading();
    try {
      await _session.save(
        userId: user.id.toString(),
        email: user.email,
        name: user.name,
      );
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> logout() async {
    await _session.clear();
    state = const AuthState.unauthenticated();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
