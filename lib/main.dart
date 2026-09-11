import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'core/services/base_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run all async boot tasks in parallel — faster cold start.
  // initCookieJar() is started eagerly here and awaited after the rest
  // so it still runs concurrently despite returning a different type.
  final cookieJarFuture = initCookieJar();
  await Future.wait([
    _loadEnv(),
    _initLocale(),
    _configureSystemUI(),
  ]);
  final cookieJar = await cookieJarFuture;

  // Notifications need the plugin singleton ready before runApp.
  final notificationService = NotificationService();
  try {
    await notificationService.initialise();
  } catch (e) {
    debugPrint('[Urbus] Failed to initialise notifications: $e');
  }

  // Capture the notification that launched the app (if any).
  NotificationAppLaunchDetails? launchDetails;
  try {
    launchDetails = await FlutterLocalNotificationsPlugin()
        .getNotificationAppLaunchDetails();
  } catch (e) {
    debugPrint('[Urbus] Failed to get launch details: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        // Inject the already-initialised service so providers
        // don't create a second instance.
        notificationServiceProvider.overrideWithValue(notificationService),
        // The Traccar session cookie — persisted to disk so login
        // survives app restarts.
        cookieJarProvider.overrideWithValue(cookieJar),
      ],
      observers: [
        // Logs every provider state change in debug builds.
        if (const bool.fromEnvironment('dart.vm.product') == false)
          _RiverpodLogger(),
      ],
      child: UrbusApp(notificationLaunchDetails: launchDetails),
    ),
  );
}

// ── Boot helpers ─────────────────────────────────────────────

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing in CI or production builds — non-fatal.
    // ApiConstants falls back to compile-time defaults.
    debugPrint('[Urbus] .env not found — using default config.');
  }
}

Future<void> _initLocale() =>
    initializeDateFormatting('es', null);

Future<void> _configureSystemUI() async {
  // Portrait-only — the tracking map and bottom sheet are
  // designed for vertical screens.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent bars so the deep-navy background bleeds edge-to-edge.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark, // iOS
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Enable edge-to-edge rendering on Android 15+.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

// ── Riverpod logger (debug only) ─────────────────────────────

base class _RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    debugPrint(
      '[Riverpod] ${context.provider.name ?? context.provider.runtimeType} '
      '$previousValue → $newValue',
    );
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[Riverpod] ERROR ${context.provider.name ?? context.provider.runtimeType}: $error');
  }
}
