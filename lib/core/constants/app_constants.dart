abstract final class AppConstants {
  // ── Secure storage keys ──────────────────────────────────────
  static const String keyAuthToken    = 'auth_token';
  static const String keyUserId       = 'user_id';
  static const String keyUserEmail    = 'user_email';
  static const String keyUserName     = 'user_name';
  static const String keyUserRole     = 'user_role';
  static const String keySelectedRouteId = 'selected_route_id';

  // ── App meta ─────────────────────────────────────────────────
  static const String appName         = 'Urbus';
  static const String appVersion      = '1.0.0';
  static const String supportEmail    = 'soporte@urbus.co';

  // ── Auth validation ──────────────────────────────────────────
  static const int minPasswordLength  = 8;

  // ── ETA & tracking ───────────────────────────────────────────
  static const int etaRefreshSeconds           = 30;
  static const int etaUrgentThresholdMinutes   = 5;
  static const double defaultSpeedKmh          = 25.0;
  static const double arrivalRadiusMetres      = 50.0;
  static const double minPositionDeltaMeters   = 10.0;

  // ── WebSocket reconnect ──────────────────────────────────────
  static const int wsInitialReconnectMs = 1000;
  static const int wsMaxReconnectMs     = 30000;

  // ── Notification IDs ─────────────────────────────────────────
  static const int arrivalNotificationId      = 1;
  static const int delayNotificationId        = 2;
  static const int announcementNotificationId = 3;
  static const int visitNotificationId        = 4;

  // ── Map defaults (Medellín, Colombia) ────────────────────────
  static const double defaultLat  = 6.2442;
  static const double defaultLng  = -75.5812;
  static const double defaultZoom = 14.0;
  static const double minZoom     = 10.0;
  static const double maxZoom     = 18.0;
  static const double detailZoom  = 16.0;

  // ── Map tiles ────────────────────────────────────────────────
  static const String mapTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const List<String> mapTileSubdomains = ['a', 'b', 'c', 'd'];
  static const String mapAttribution =
      '© OpenStreetMap contributors © CARTO';

  // ── UI ───────────────────────────────────────────────────────
  static const double bottomSheetMinHeight        = 130.0;
  static const double bottomSheetMaxHeightFraction = 0.75;
  static const double cardRadius                  = 20.0;
  static const double buttonHeight                = 54.0;
  static const double minTouchTarget              = 44.0;
}
