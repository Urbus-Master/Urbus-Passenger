import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/auth_provider.dart';

// ─────────────────────────────────────────────
// AUTH CONTROLLER STATE
// ─────────────────────────────────────────────

/// UI-scoped state for the login screen.
/// Intentionally minimal — the source of truth for auth lives
/// in [authProvider]. This state only drives form feedback.
class AuthControllerState {
  final bool isLoading;
  final bool isPasswordResetSent;
  final String? errorMessage;

  const AuthControllerState({
    this.isLoading = false,
    this.isPasswordResetSent = false,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;

  AuthControllerState copyWith({
    bool? isLoading,
    bool? isPasswordResetSent,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AuthControllerState(
        isLoading: isLoading ?? this.isLoading,
        isPasswordResetSent: isPasswordResetSent ?? this.isPasswordResetSent,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}

// ─────────────────────────────────────────────
// AUTH CONTROLLER
// ─────────────────────────────────────────────

/// Manages authentication operations for the login screen.
///
/// Delegates all persistence and session logic to [AuthService] and
/// [AuthNotifier] — this controller only handles UI-level state
/// (loading spinner, error messages, password reset confirmation).
///
/// Route redirection after login is handled by GoRouter's redirect
/// listening to [isAuthenticatedProvider] — not from here.
class AuthController extends Notifier<AuthControllerState> {
  late final AuthService _authService;

  @override
  AuthControllerState build() {
    _authService = ref.read(authServiceProvider);
    return const AuthControllerState();
  }

  // ── Login ────────────────────────────────────────────────────

  /// Authenticates with [email] and [password] via [AuthService].
  ///
  /// On success: [authProvider] flips to authenticated and GoRouter
  /// redirects automatically — no manual navigation needed here.
  /// On failure: stores a typed, Spanish error message for the UI.
  Future<void> login(String email, String password) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.login(
        email: email,
        password: password,
      );
      // Success — authProvider now holds the session.
      // GoRouter redirect fires automatically.
      // We still reset loading in case the widget is still mounted.
      state = const AuthControllerState();
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado. Intenta de nuevo.',
      );
    }
  }

  // ── Logout ───────────────────────────────────────────────────

  /// Signs the user out. Clears credentials via [AuthService].
  /// GoRouter redirect handles navigation back to /login.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.logout();
    } finally {
      // Always reset — authProvider handles the unauthenticated state.
      state = const AuthControllerState();
    }
  }

  // ── Password reset ───────────────────────────────────────────

  /// Sends a password reset email and surfaces confirmation to the UI.
  Future<void> requestPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Ingresa tu correo para recuperar la contraseña.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.requestPasswordReset(email.trim());
      state = state.copyWith(
        isLoading: false,
        isPasswordResetSent: true,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo enviar el correo. Intenta de nuevo.',
      );
    }
  }

  // ── Error / state management ─────────────────────────────────

  /// Clears the displayed error — called when the user starts typing again.
  void clearError() => state = state.copyWith(clearError: true);

  /// Resets the password reset confirmation flag.
  /// Called when the user dismisses the success message.
  void clearPasswordResetConfirmation() =>
      state = state.copyWith(isPasswordResetSent: false);
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

/// UI state for the login screen — loading, errors, reset confirmation.
final authControllerProvider =
    NotifierProvider<AuthController, AuthControllerState>(
  AuthController.new,
);

/// Narrow provider — loading state only.
/// The submit button watches this without rebuilding on error changes.
final authLoadingProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider).isLoading,
);

/// Narrow provider — error message only.
/// The error banner rebuilds only when the message changes.
final authErrorProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider).errorMessage,
);
