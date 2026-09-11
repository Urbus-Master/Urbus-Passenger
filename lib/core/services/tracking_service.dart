import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../models/unit_model.dart';
import '../models/checkpoint_model.dart';
import '../utils/eta_calculator.dart';
import 'base_client.dart';
import 'location_service.dart';
import 'notification_service.dart';

// ─────────────────────────────────────────────
// CONNECTION STATE
// ─────────────────────────────────────────────

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

// ─────────────────────────────────────────────
// TRACKING STATE
// ─────────────────────────────────────────────

class TrackingState {
  final ConnectionStatus connectionStatus;
  final UnitModel? activeUnit;
  final List<CheckpointModel> checkpoints;
  final Duration? eta;
  final LatLng? userPosition;
  final bool isAlertScheduled;
  final String? errorMessage;

  /// True when [connectionStatus] is being driven by the local GPS
  /// simulator (no `TRACCAR_WS_URL` configured) rather than a real
  /// Traccar WebSocket session. The UI must not present this as "live".
  final bool isMock;

  const TrackingState({
    this.connectionStatus = ConnectionStatus.disconnected,
    this.activeUnit,
    this.checkpoints = const [],
    this.eta,
    this.userPosition,
    this.isAlertScheduled = false,
    this.errorMessage,
    this.isMock = false,
  });

  const TrackingState.initial() : this();

  bool get isConnected => connectionStatus == ConnectionStatus.connected;
  bool get isReconnecting => connectionStatus == ConnectionStatus.reconnecting;
  bool get hasUnit => activeUnit != null;
  bool get hasEta => eta != null;

  bool get isEtaUrgent =>
      eta != null &&
      eta!.inMinutes <= AppConstants.etaUrgentThresholdMinutes;

  String get etaFormatted {
    if (eta == null) return '--:--';
    final m = eta!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = eta!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  CheckpointModel? get currentCheckpoint => checkpoints
      .where((c) => c.status == CheckpointStatus.current)
      .firstOrNull;

  int get completedCount =>
      checkpoints.where((c) => c.status == CheckpointStatus.completed).length;

  TrackingState copyWith({
    ConnectionStatus? connectionStatus,
    UnitModel? activeUnit,
    List<CheckpointModel>? checkpoints,
    Duration? eta,
    LatLng? userPosition,
    bool? isAlertScheduled,
    String? errorMessage,
    bool? isMock,
    bool clearEta = false,
    bool clearError = false,
  }) =>
      TrackingState(
        connectionStatus: connectionStatus ?? this.connectionStatus,
        activeUnit: activeUnit ?? this.activeUnit,
        checkpoints: checkpoints ?? this.checkpoints,
        eta: clearEta ? null : eta ?? this.eta,
        userPosition: userPosition ?? this.userPosition,
        isAlertScheduled: isAlertScheduled ?? this.isAlertScheduled,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        isMock: isMock ?? this.isMock,
      );
}

// ─────────────────────────────────────────────
// MOCK DATA
// ─────────────────────────────────────────────

class MockTrackingData {
  static const _baseLatitude = 6.2442;
  static const _baseLongitude = -75.5812;

  static UnitModel get unit => UnitModel(
        id: 'unit-204',
        unitNumber: '204',
        driverName: 'Carlos Mendoza',
        driverAvatar: null,
        driverRating: 4.8,
        latitude: _baseLatitude,
        longitude: _baseLongitude,
        speed: 25.0,
        status: UnitStatus.active,
        lastUpdate: DateTime.now(),
        routeId: 'route-01',
      );

  static List<CheckpointModel> get checkpoints => [
        CheckpointModel(
          id: 'cp-1',
          name: 'Parque Berrío',
          address: 'Cl. 52 #51-55, El Centro',
          latitude: _baseLatitude + 0.010,
          longitude: _baseLongitude + 0.005,
          order: 1,
          estimatedTime: DateTime.now().subtract(const Duration(minutes: 15)),
          status: CheckpointStatus.completed,
        ),
        CheckpointModel(
          id: 'cp-2',
          name: 'Hospital General',
          address: 'Cra. 48 #32-102, Buenos Aires',
          latitude: _baseLatitude + 0.005,
          longitude: _baseLongitude + 0.002,
          order: 2,
          estimatedTime: DateTime.now().subtract(const Duration(minutes: 5)),
          status: CheckpointStatus.completed,
        ),
        CheckpointModel(
          id: 'cp-3',
          name: 'Estadio Atanasio',
          address: 'Cra. 74 #48-64, Laureles',
          latitude: _baseLatitude,
          longitude: _baseLongitude,
          order: 3,
          estimatedTime: DateTime.now().add(const Duration(minutes: 8)),
          status: CheckpointStatus.current,
        ),
        CheckpointModel(
          id: 'cp-4',
          name: 'Parque Envigado',
          address: 'Cl. 38 Sur #43B-20, Envigado',
          latitude: _baseLatitude - 0.008,
          longitude: _baseLongitude - 0.003,
          order: 4,
          estimatedTime: DateTime.now().add(const Duration(minutes: 20)),
          status: CheckpointStatus.upcoming,
        ),
        CheckpointModel(
          id: 'cp-5',
          name: 'Plaza Sabaneta',
          address: 'Cra. 43A #75 Sur-9, Sabaneta',
          latitude: _baseLatitude - 0.018,
          longitude: _baseLongitude - 0.008,
          order: 5,
          estimatedTime: DateTime.now().add(const Duration(minutes: 35)),
          status: CheckpointStatus.upcoming,
        ),
      ];

  static UnitModel advanceUnit(UnitModel unit, int tick) {
    final angle = tick * 0.05;
    return unit.copyWith(
      latitude: unit.latitude + sin(angle) * 0.0002,
      longitude: unit.longitude + cos(angle) * 0.0002,
      lastUpdate: DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────
// TRACKING SERVICE
// ─────────────────────────────────────────────

class TrackingService {
  final Ref _ref;
  WebSocketChannel? _channel;
  Timer? _etaTimer;
  Timer? _reconnectTimer;
  Timer? _mockTimer;
  int _reconnectAttempts = 0;
  int _mockTick = 0;
  bool _disposed = false;

  TrackingService(this._ref);

  Future<void> connect(TrackingNotifier notifier) async {
    final wsUrl = ApiConstants.traccarWsUrl;

    if (wsUrl.isEmpty) {
      _startMockSimulation(notifier);
      return;
    }

    await _connectWebSocket(notifier);
  }

  Future<void> _connectWebSocket(TrackingNotifier notifier) async {
    if (_disposed) return;

    notifier._setConnectionStatus(ConnectionStatus.connecting);

    try {
      final uri = Uri.parse(ApiConstants.traccarWsUrl);

      // Traccar's WebSocket handshake is authenticated by the same
      // session cookie as REST calls — Dio's CookieManager doesn't
      // apply here since this is a separate client, so it's attached
      // manually from the shared cookie jar.
      final cookieJar = _ref.read(cookieJarProvider);
      final cookies = await cookieJar.loadForRequest(
        Uri.parse(ApiConstants.baseUrl),
      );
      final cookieHeader =
          cookies.map((c) => '${c.name}=${c.value}').join('; ');

      if (_disposed) return;

      _channel = IOWebSocketChannel.connect(
        uri,
        headers: cookieHeader.isNotEmpty ? {'Cookie': cookieHeader} : null,
      );

      _channel!.ready.then((_) {
        notifier._setConnectionStatus(ConnectionStatus.connected);
        _reconnectAttempts = 0;
        _startEtaTimer(notifier);
      }).catchError((Object e) {
        _scheduleReconnect(notifier);
        return null;
      });

      _channel!.stream.listen(
        (data) => _handleMessage(data as String, notifier),
        onError: (_) => _scheduleReconnect(notifier),
        onDone: () => _scheduleReconnect(notifier),
      );
    } catch (_) {
      _scheduleReconnect(notifier);
    }
  }

  void _handleMessage(String raw, TrackingNotifier notifier) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;

      if (json.containsKey('positions')) {
        final positions = json['positions'] as List<dynamic>;
        if (positions.isNotEmpty) {
          _updateUnitPosition(
            positions.first as Map<String, dynamic>,
            notifier,
          );
        }
      }

      if (json.containsKey('devices')) {
        final devices = json['devices'] as List<dynamic>;
        if (devices.isNotEmpty) {
          _updateUnitStatus(
            devices.first as Map<String, dynamic>,
            notifier,
          );
        }
      }
    } catch (_) {
      // Malformed frame — skip silently.
    }
  }

  void _updateUnitPosition(
    Map<String, dynamic> position,
    TrackingNotifier notifier,
  ) {
    final current = notifier.currentState.activeUnit;
    if (current == null) return;

    final newLat = (position['latitude'] as num).toDouble();
    final newLng = (position['longitude'] as num).toDouble();
    final newSpeed =
        (position['speed'] as num?)?.toDouble() ?? current.speed;

    final locationService = _ref.read(locationServiceProvider);
    final didMove = locationService.hasMovedSignificantly(
      LatLng(current.latitude, current.longitude),
      LatLng(newLat, newLng),
    );

    if (!didMove) return;

    notifier._updateUnit(current.copyWith(
      latitude: newLat,
      longitude: newLng,
      speed: newSpeed,
      lastUpdate: DateTime.now(),
    ));

    _recalculateEta(notifier);
  }

  void _updateUnitStatus(
    Map<String, dynamic> device,
    TrackingNotifier notifier,
  ) {
    final current = notifier.currentState.activeUnit;
    if (current == null) return;

    final statusStr = device['status'] as String? ?? '';
    final status = UnitStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => UnitStatus.active,
    );

    notifier._updateUnit(current.copyWith(status: status));
  }

  void _startEtaTimer(TrackingNotifier notifier) {
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(
      Duration(seconds: AppConstants.etaRefreshSeconds),
      (_) => _recalculateEta(notifier),
    );
  }

  void _recalculateEta(TrackingNotifier notifier) {
    final unit = notifier.currentState.activeUnit;
    final userPosition = notifier.currentState.userPosition;
    final checkpoints = notifier.currentState.checkpoints;

    if (unit == null) return;

    final result = EtaCalculator.calculate(
      unitPosition: LatLng(unit.latitude, unit.longitude),
      userPosition: userPosition,
      remainingCheckpoints: checkpoints
          .where((c) => c.status != CheckpointStatus.completed)
          .toList(),
      averageSpeedKmh: unit.speed > 0 ? unit.speed : 25.0,
    );

    notifier._updateEta(result?.duration);

    if (result != null &&
        result.duration.inMinutes <= AppConstants.etaUrgentThresholdMinutes &&
        notifier.currentState.isAlertScheduled) {
      _ref.read(notificationProvider.notifier).onUnitDelayed(
            unit,
            result.duration.inMinutes,
          );
    }
  }

  void _scheduleReconnect(TrackingNotifier notifier) {
    if (_disposed) return;

    notifier._setConnectionStatus(ConnectionStatus.reconnecting);
    _channel = null;

    final delayMs = min(
      AppConstants.wsInitialReconnectMs * pow(2, _reconnectAttempts).toInt(),
      AppConstants.wsMaxReconnectMs,
    );

    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(milliseconds: delayMs),
      () { if (!_disposed) unawaited(_connectWebSocket(notifier)); },
    );
  }

  void _startMockSimulation(TrackingNotifier notifier) {
    notifier._initMockData();
    notifier._setMock(true);
    notifier._setConnectionStatus(ConnectionStatus.connected);

    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _mockTick++;
      final current = notifier.currentState.activeUnit;
      if (current == null) return;

      notifier._updateUnit(MockTrackingData.advanceUnit(current, _mockTick));
      _recalculateEta(notifier);
    });

    _startEtaTimer(notifier);
  }

  void dispose() {
    _disposed = true;
    _channel?.sink.close(ws_status.goingAway);
    _etaTimer?.cancel();
    _reconnectTimer?.cancel();
    _mockTimer?.cancel();
  }
}

// ─────────────────────────────────────────────
// TRACKING NOTIFIER
// ─────────────────────────────────────────────

class TrackingNotifier extends Notifier<TrackingState> {
  TrackingService? _service;

  @override
  TrackingState build() {
    final service = TrackingService(ref);
    _service = service;

    Future.microtask(() => service.connect(this));
    _syncUserPosition();

    ref.onDispose(service.dispose);

    return const TrackingState.initial();
  }

  /// Public getter to avoid 'invalid_use_of_protected_member' warnings in services.
  TrackingState get currentState => state;

  void _syncUserPosition() {
    final position = ref.read(currentPositionProvider);
    if (position != null) {
      state = state.copyWith(userPosition: position);
    }

    ref.listen<LatLng?>(currentPositionProvider, (_, next) {
      if (next != null) state = state.copyWith(userPosition: next);
    });
  }

  // ── Internal mutators ────────────────────────────────────────

  void _setConnectionStatus(ConnectionStatus status) =>
      state = state.copyWith(connectionStatus: status);

  void _updateUnit(UnitModel unit) =>
      state = state.copyWith(activeUnit: unit);

  void _updateEta(Duration? eta) =>
      state = state.copyWith(eta: eta);

  void _initMockData() => state = state.copyWith(
        activeUnit: MockTrackingData.unit,
        checkpoints: MockTrackingData.checkpoints,
      );

  void _setMock(bool value) => state = state.copyWith(isMock: value);

  // ── Public actions ───────────────────────────────────────────

  Future<void> toggleAlert() async {
    final unit = state.activeUnit;
    final eta = state.eta;
    if (unit == null) return;

    final estimatedArrival = eta != null
        ? DateTime.now().add(eta)
        : DateTime.now().add(const Duration(minutes: 10));

    await ref.read(notificationProvider.notifier).toggleArrivalAlert(
          unit: unit,
          estimatedArrival: estimatedArrival,
        );

    state = state.copyWith(isAlertScheduled: !state.isAlertScheduled);
  }

  void reconnect() {
    _service?.dispose();
    final service = TrackingService(ref);
    _service = service;
    service.connect(this);
  }
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(
  TrackingNotifier.new,
);

final activeUnitProvider = Provider<UnitModel?>(
  (ref) => ref.watch(trackingProvider).activeUnit,
);

final etaFormattedProvider = Provider<String>(
  (ref) => ref.watch(trackingProvider).etaFormatted,
);

final connectionStatusProvider = Provider<ConnectionStatus>(
  (ref) => ref.watch(trackingProvider).connectionStatus,
);

final isMockTrackingProvider = Provider<bool>(
  (ref) => ref.watch(trackingProvider).isMock,
);

final checkpointsProvider = Provider<List<CheckpointModel>>(
  (ref) => ref.watch(trackingProvider).checkpoints,
);

final isEtaUrgentProvider = Provider<bool>(
  (ref) => ref.watch(trackingProvider).isEtaUrgent,
);
