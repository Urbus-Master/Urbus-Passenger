abstract final class AppConstants {
  // ── Secure storage keys ──────────────────────────────────────
  static const String keyAuthToken    = 'auth_token';
  static const String keyUserId       = 'user_id';
  static const String keyUserEmail    = 'user_email';
  static const String keyUserName     = 'user_name';
  // FIX: keyUserRole agregado — auth_provider.dart lo usa para
  // persistir el rol del usuario en secure storage.
  static const String keyUserRole     = 'user_role';
  static const String keySelectedRouteId = 'selected_route_id';

  // ── App meta ─────────────────────────────────────────────────
  // FIX: appName y appVersion agregados — login_screen.dart los usa
  // para mostrar el nombre de la app y la versión en el footer.
  static const String appName         = 'Urbus';
  static const String appVersion      = '1.0.0';
  static const String supportEmail    = 'soporte@urbus.co';

  // FIX: skipAuthInterceptorKey agregado — auth_service.dart lo pasa
  // en Options.extra para que el interceptor de Dio no inyecte el token
  // en endpoints públicos como login y password reset.
  static const String skipAuthInterceptorKey = 'skipAuthInterceptor';

  // ── Auth validation ──────────────────────────────────────────
  // FIX: minPasswordLength agregado — login_screen.dart lo usa en
  // el validator del campo de contraseña.
  static const int minPasswordLength  = 8;

  // ── ETA & tracking ───────────────────────────────────────────
  static const int etaRefreshSeconds           = 30;
  static const int etaUrgentThresholdMinutes   = 5;
  // FIX: defaultSpeedKmh agregado — EtaCalculator lo usa como
  // velocidad de fallback cuando la unidad reporta speed = 0.
  static const double defaultSpeedKmh          = 25.0;
  // FIX: arrivalRadiusMetres agregado — EtaCalculator.hasArrived()
  // lo usa para determinar si la unidad ya llegó al destino.
  static const double arrivalRadiusMetres      = 50.0;
  // FIX: minPositionDeltaMeters agregado — location_service.dart y
  // tracking_service.dart lo usan para filtrar updates insignificantes.
  static const double minPositionDeltaMeters   = 10.0;

  // ── WebSocket reconnect ──────────────────────────────────────
  static const int wsInitialReconnectMs = 1000;
  static const int wsMaxReconnectMs     = 30000;

  // ── Notification IDs ─────────────────────────────────────────
  // FIX: IDs de notificación agregados — notification_service.dart
  // los usa para identificar y cancelar notificaciones por tipo.
  static const int arrivalNotificationId      = 1;
  static const int delayNotificationId        = 2;
  static const int announcementNotificationId = 3;
  static const int visitNotificationId        = 4;

  // ── Map defaults (Medellín, Colombia) ────────────────────────
  // FIX: constantes del mapa agregadas — map_widget.dart las usa para
  // la posición inicial y los límites de zoom cuando no hay GPS.
  static const double defaultLat  = 6.2442;
  static const double defaultLng  = -75.5812;
  static const double defaultZoom = 14.0;
  static const double minZoom     = 10.0;
  static const double maxZoom     = 18.0;
  // FIX: detailZoom — map_widget.dart lo usa al hacer zoom automático
  // cuando se selecciona un checkpoint específico.
  static const double detailZoom  = 16.0;

  // ── Map tiles ────────────────────────────────────────────────
  // FIX: mapTileUrl, mapTileSubdomains, mapAttribution agregados —
  // map_widget.dart los usa para configurar el TileLayer de flutter_map.
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
