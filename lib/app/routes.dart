import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/auth_provider.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/tracking/screens/tracking_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/alerts/screens/alerts_screen.dart';
import '../features/announcements/screens/announcements_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

// ── Route name constants ──────────────────────────────────────

abstract final class AppRoutes {
  static const String splash        = 'splash';
  static const String login         = 'login';
  static const String home          = 'home';
  static const String history       = 'history';
  static const String alerts        = 'alerts';
  static const String announcements = 'announcements';
  static const String profile       = 'profile';
}

// ── Route paths ───────────────────────────────────────────────

abstract final class AppPaths {
  static const String splash        = '/splash';
  static const String login         = '/login';
  static const String home          = '/home';
  static const String history       = '/history';
  static const String alerts        = '/alerts';
  static const String announcements = '/announcements';
  static const String profile       = '/profile';
}

// ── Transition durations ──────────────────────────────────────

abstract final class _Durations {
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration premium = Duration(milliseconds: 350);
}

// ── Router provider ───────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  // FIX: _AuthRouterNotifier ahora escucha `isAuthenticatedProvider`
  // (Provider<bool>) en lugar de `authProvider` (Provider<AuthState>).
  // El redirect necesita un bool, no el AuthState completo.
  final authNotifier = _AuthRouterNotifier(ref);

  return GoRouter(
    initialLocation: AppPaths.home,
    refreshListenable: authNotifier,
    debugLogDiagnostics: true,

    redirect: (BuildContext context, GoRouterState state) {
      // FIX: lee `isAuthenticatedProvider` en lugar de `authProvider`.
      // authProvider ahora retorna AuthState, no bool.
      // isAuthenticatedProvider es el narrow provider bool que creamos.
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      // FIX: también ignorar redirect mientras el estado es `unknown`
      // (app recién abierta, sesión aún no verificada desde splash).
      final authStatus = ref.read(authProvider).status;
      if (authStatus == AuthStatus.unknown ||
          authStatus == AuthStatus.loading) {
        return null;
      }

      final location = state.matchedLocation;
      final isLogin = location == AppPaths.login;
      final isProfile = location == AppPaths.profile;
      final isAlerts = location == AppPaths.alerts;

      // Si no está autenticado e intenta entrar a zonas privadas, redirigir a login.
      if (!isAuthenticated && (isProfile || isAlerts)) {
        return AppPaths.login;
      }

      // Si ya está autenticado y está en la pantalla de login, mandarlo al home.
      if (isAuthenticated && isLogin) {
        return AppPaths.home;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppPaths.splash,
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: AppPaths.login,
        name: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: _Durations.fast,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      GoRoute(
        path: AppPaths.home,
        name: AppRoutes.home,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: _Durations.fast,
          child: const TrackingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      GoRoute(
        path: AppPaths.history,
        name: AppRoutes.history,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: _Durations.premium,
          child: const HistoryScreen(),
          transitionsBuilder: _premiumTransition,
        ),
      ),

      GoRoute(
        path: AppPaths.alerts,
        name: AppRoutes.alerts,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: _Durations.premium,
          child: const AlertsScreen(),
          transitionsBuilder: _premiumTransition,
        ),
      ),

      GoRoute(
        path: AppPaths.announcements,
        name: AppRoutes.announcements,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: _Durations.premium,
          child: const AnnouncementsScreen(),
          transitionsBuilder: _premiumTransition,
        ),
      ),

      GoRoute(
        path: AppPaths.profile,
        name: AppRoutes.profile,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: _Durations.premium,
          child: const ProfileScreen(),
          transitionsBuilder: _premiumTransition,
        ),
      ),
    ],

    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
  );
});

// FIX: exponer el router como provider accesible desde widgets
// que necesiten navegar sin BuildContext (ej: auth interceptor).
final appRouterProvider = Provider<GoRouter>(
  (ref) => ref.watch(routerProvider),
);

// ── Transition builders ───────────────────────────────────────

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
    child: child,
  );
}

Widget _premiumTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    ),
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.98, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.01),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

// ── Auth router notifier ──────────────────────────────────────

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    // FIX: escucha `isAuthenticatedProvider` (bool) en lugar de
    // `authProvider` (AuthState). El router solo necesita saber si
    // está autenticado o no — no el estado completo.
    // También escucha `authProvider` para reaccionar al cambio de
    // `unknown → unauthenticated` después del splash.
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        // Notifica solo en cambios relevantes para el router:
        // cambio de autenticación o salida del estado unknown/loading.
        final authChanged = previous?.isAuthenticated != next.isAuthenticated;
        final resolvedFromUnknown = previous?.isUnknown == true &&
            next.status != AuthStatus.unknown &&
            next.status != AuthStatus.loading;

        if (authChanged || resolvedFromUnknown) notifyListeners();
      },
    );
  }
}

// ── 404 Error screen ──────────────────────────────────────────

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 64,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 24),
              Text(
                'Ruta no encontrada',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'La pantalla que buscas no existe.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.goNamed(AppRoutes.home),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

