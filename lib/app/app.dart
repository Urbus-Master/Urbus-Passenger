import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import '../shared/widgets/connectivity_banner.dart';

/// Root application widget.
///
/// [UrbusApp] es [ConsumerWidget] para leer [routerProvider] del
/// contenedor Riverpod sin reconstruirse innecesariamente.
class UrbusApp extends ConsumerWidget {
  final NotificationAppLaunchDetails? notificationLaunchDetails;

  const UrbusApp({super.key, this.notificationLaunchDetails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // ── Identity ─────────────────────────────────────────
      title: 'Urbus',
      debugShowCheckedModeBanner: false,

      // ── Theme ────────────────────────────────────────────
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,

      // ── Routing ──────────────────────────────────────────
      routerConfig: router,

      // ── Localisation ─────────────────────────────────────
      locale: const Locale('es', 'CO'),
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Global builder ───────────────────────────────────
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        final clampedScale = mediaQuery.textScaler
            .scale(1.0)
            .clamp(0.85, 1.2);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(clampedScale),
          ),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const ConnectivityBanner(),
            ],
          ),
        );
      },
    );
  }
}
