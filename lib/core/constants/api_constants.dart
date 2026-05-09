import 'package:flutter_dotenv/flutter_dotenv.dart';

/// All network-level constants pointing to the Traccar backend.
///
/// URLs are loaded from the .env file at runtime so the same build
/// can point to dev / staging / production without recompilation.
///
/// .env format:
/// ```
/// TRACCAR_BASE_URL=https://tu-servidor.com
/// TRACCAR_WS_URL=wss://tu-servidor.com
/// ```
abstract final class ApiConstants {
  // ── Base URLs (from .env) ────────────────────────────────────

  static String get baseUrl =>
      dotenv.env['TRACCAR_BASE_URL'] ?? 'http://localhost:8082';

  // FIX: renombrado wsUrl → traccarWsUrl para coincidir con las
  // referencias en tracking_service.dart que usaban traccarWsUrl.
  static String get traccarWsUrl =>
      dotenv.env['TRACCAR_WS_URL'] ?? '';

  /// Cuando está vacío, los servicios usan mock data automáticamente.
  static bool get hasBackend =>
      (dotenv.env['TRACCAR_BASE_URL'] ?? '').isNotEmpty;

  // ── Timeouts ─────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout    = Duration(seconds: 15);

  static const Duration wsReconnectInitial = Duration(seconds: 2);
  static const Duration wsReconnectMax     = Duration(seconds: 30);

  // ── Auth endpoints ───────────────────────────────────────────
  static const String session = '/session';

  // FIX: agregados los endpoints que usan auth_service.dart.
  // loginEndpoint y logoutEndpoint referencian /session de Traccar.
  // Traccar usa POST /session para login y DELETE /session para logout.
  static const String loginEndpoint        = '/session';
  static const String logoutEndpoint       = '/session';
  static const String validateTokenEndpoint = '/session';
  // FIX: passwordResetEndpoint no existe en Traccar nativo —
  // apunta a un endpoint custom del backend Urbus.
  static const String passwordResetEndpoint = '/users/password-reset';

  // ── Device endpoints ─────────────────────────────────────────
  static const String devices = '/devices';
  static String deviceById(int id) => '/devices/$id';

  // ── Position endpoints ───────────────────────────────────────
  static const String positions = '/positions';

  // ── Geofence endpoints ───────────────────────────────────────
  static const String geofences = '/geofences';
  static String geofenceById(int id) => '/geofences/$id';

  // ── Report endpoints ─────────────────────────────────────────
  static const String reportsRoute   = '/reports/route';
  static const String reportsSummary = '/reports/summary';
  static const String reportsStops   = '/reports/stops';
  static const String reportsEvents  = '/reports/events';

  // FIX: visitsEndpoint agregado — history_controller.dart lo
  // referenciaba pero no existía. Apunta a los stops de Traccar
  // que el backend Urbus enriquece como historial de visitas.
  static const String visitsEndpoint = '/reports/stops';

  // ── Notification endpoints ───────────────────────────────────
  static const String notifications = '/notifications';

  // ── User endpoints ───────────────────────────────────────────
  static const String me = '/users/me';
  static String userById(int id) => '/users/$id';

  // ── WebSocket event types ────────────────────────────────────
  static const String wsEventPositions = 'positions';
  static const String wsEventDevices   = 'devices';
  static const String wsEventEvents    = 'events';

  // ── Query parameter keys ─────────────────────────────────────
  static const String paramDeviceId = 'deviceId';
  static const String paramFrom     = 'from';
  static const String paramTo       = 'to';
  static const String paramAll      = 'all';

  // ── Pagination ───────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize     = 100;

  // ── Headers ──────────────────────────────────────────────────
  static const String authorizationHeader = 'Authorization';
  static const String cookieHeader        = 'Cookie';
  static const String contentTypeJson     = 'application/json';
  static const String contentTypeForm     = 'application/x-www-form-urlencoded';
}
