import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/unit_model.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────
// NOTIFICATION STATE
// ─────────────────────────────────────────────

class NotificationState {
  final bool isInitialised;
  final bool hasPermission;
  final bool arrivalAlertsEnabled;
  final bool delayAlertsEnabled;
  final bool announcementsEnabled;
  final String? scheduledAlertUnitNumber;

  const NotificationState({
    this.isInitialised = false,
    this.hasPermission = false,
    this.arrivalAlertsEnabled = true,
    this.delayAlertsEnabled = true,
    this.announcementsEnabled = true,
    this.scheduledAlertUnitNumber,
  });

  bool get hasScheduledAlert => scheduledAlertUnitNumber != null;

  NotificationState copyWith({
    bool? isInitialised,
    bool? hasPermission,
    bool? arrivalAlertsEnabled,
    bool? delayAlertsEnabled,
    bool? announcementsEnabled,
    String? scheduledAlertUnitNumber,
    bool clearScheduledAlert = false,
  }) =>
      NotificationState(
        isInitialised: isInitialised ?? this.isInitialised,
        hasPermission: hasPermission ?? this.hasPermission,
        arrivalAlertsEnabled: arrivalAlertsEnabled ?? this.arrivalAlertsEnabled,
        delayAlertsEnabled: delayAlertsEnabled ?? this.delayAlertsEnabled,
        announcementsEnabled: announcementsEnabled ?? this.announcementsEnabled,
        scheduledAlertUnitNumber: clearScheduledAlert
            ? null
            : scheduledAlertUnitNumber ?? this.scheduledAlertUnitNumber,
      );
}

// ─────────────────────────────────────────────
// NOTIFICATION SERVICE
// ─────────────────────────────────────────────

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  // ── Initialisation ───────────────────────────────────────────

  Future<bool> initialise() async {
    if (_initialised) return true;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final result = await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // FIX: crear canales Android en initialise() — sin esto las
    // notificaciones no aparecen en Android 8+.
    await _createChannels();

    _initialised = result ?? false;
    return _initialised;
  }

  // ── Permissions ──────────────────────────────────────────────

  // FIX: requestPermission() — action_buttons_row.dart y el notifier
  // lo llaman antes de programar alertas. El original no lo tenía.
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      return await plugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    if (Platform.isAndroid) {
      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await plugin?.requestNotificationsPermission() ?? false;
    }

    return false;
  }

  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await plugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  Future<bool> openSettings() async {
    if (Platform.isAndroid) {
      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.requestNotificationsPermission();
    }
    return false;
  }

  // ── Arrival alert ────────────────────────────────────────────

  // FIX: toggleArrivalAlert() — tracking_service.dart y action_buttons_row
  // lo llaman con esta firma exacta. El original era un stub vacío.
  Future<void> toggleArrivalAlert({
    required UnitModel unit,
    required DateTime estimatedArrival,
    int minutesBefore = 5,
  }) async {
    if (!_initialised) return;

    await cancelArrivalAlert();

    final scheduledTime = estimatedArrival.subtract(
      Duration(minutes: minutesBefore),
    );

    if (scheduledTime.isBefore(DateTime.now())) {
      await _show(
        id: AppConstants.arrivalNotificationId,
        title: '🚛 Tu unidad está llegando',
        body:
            'La Unidad #${unit.unitNumber} llegará en menos de $minutesBefore minutos.',
        channelId: 'urbus_arrival',
        channelName: 'Llegada de unidad',
      );
      return;
    }

    await _plugin.zonedSchedule(
      id: AppConstants.arrivalNotificationId,
      title: '🚛 Tu unidad está llegando',
      body: 'La Unidad #${unit.unitNumber} llegará en $minutesBefore minutos.',
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: _buildDetails(
        channelId: 'urbus_arrival',
        channelName: 'Llegada de unidad',
        importance: Importance.max,
        priority: Priority.max,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: unit.id,
    );
  }

  Future<void> cancelArrivalAlert() async {
    await _plugin.cancel(id: AppConstants.arrivalNotificationId);
  }

  // ── Delay notification ───────────────────────────────────────

  // FIX: onUnitDelayed() — tracking_service.dart lo llama cuando el
  // ETA cae bajo el umbral urgente y hay alerta programada.
  Future<void> onUnitDelayed(UnitModel unit, int delayMinutes) async {
    if (!_initialised) return;
    await _show(
      id: AppConstants.delayNotificationId,
      title: '⏱ Retraso en el servicio',
      body:
          'La Unidad #${unit.unitNumber} lleva $delayMinutes min de retraso.',
      channelId: 'urbus_delay',
      channelName: 'Retrasos',
    );
  }

  // ── Announcement notification ────────────────────────────────

  Future<void> notifyAnnouncement({
    required String title,
    required String body,
    String? announcementId,
  }) async {
    if (!_initialised) return;
    await _show(
      id: AppConstants.announcementNotificationId,
      title: '📢 $title',
      body: body,
      channelId: 'urbus_announcements',
      channelName: 'Avisos municipales',
    );
  }

  // ── Visit confirmed ──────────────────────────────────────────

  Future<void> notifyVisitConfirmed({
    required String unitNumber,
    required String checkpointName,
  }) async {
    if (!_initialised) return;
    await _show(
      id: AppConstants.visitNotificationId,
      title: 'Visita registrada ✓',
      body: 'Unidad #$unitNumber completó la parada en $checkpointName.',
      channelId: 'urbus_visits',
      channelName: 'Visitas confirmadas',
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Internal helpers ─────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    String? payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _buildDetails(
        channelId: channelId,
        channelName: channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      payload: payload,
    );
  }

  NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
    required Importance importance,
    required Priority priority,
  }) {
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      // FIX: accent color como int — AppColors.accent es Color(0xFF2F81F7).
      color: const Color(0xFF2F81F7),
      enableLights: true,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: android, iOS: ios);
  }

  Future<void> _createChannels() async {
    if (!Platform.isAndroid) return;

    final plugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final channels = [
      const AndroidNotificationChannel(
        'urbus_arrival',
        'Llegada de unidad',
        description: 'Alertas cuando tu unidad está por llegar',
        importance: Importance.max,
      ),
      const AndroidNotificationChannel(
        'urbus_delay',
        'Retrasos',
        description: 'Avisos de retrasos en el servicio',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'urbus_announcements',
        'Avisos municipales',
        description: 'Comunicados y cambios de ruta',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        'urbus_visits',
        'Visitas confirmadas',
        description: 'Confirmaciones de visitas del servicio',
        importance: Importance.low,
      ),
    ];

    for (final channel in channels) {
      await plugin?.createNotificationChannel(channel);
    }
  }
}

// ─────────────────────────────────────────────
// NOTIFICATION NOTIFIER
// ─────────────────────────────────────────────

class NotificationNotifier extends Notifier<NotificationState> {
  // FIX: cambiado de StateNotifier a Notifier para ser consistente
  // con el resto del proyecto que usa Notifier + NotifierProvider.
  late final NotificationService _service;

  @override
  NotificationState build() {
    _service = ref.read(notificationServiceProvider);
    return const NotificationState();
  }

  // ── Init & permissions ───────────────────────────────────────

  Future<void> initialise() async {
    final initialised = await _service.initialise();
    final permission = await _service.hasPermission();
    state = state.copyWith(
      isInitialised: initialised,
      hasPermission: permission,
    );
  }

  // FIX: requestPermission() — action_buttons_row.dart lo llama
  // cuando el usuario toca "Alertarme" sin permiso concedido.
  Future<void> requestPermission() async {
    final granted = await _service.requestPermission();
    state = state.copyWith(hasPermission: granted);
  }

  // ── Arrival alert toggle ─────────────────────────────────────

  // FIX: toggleArrivalAlert() — tracking_service.dart y
  // action_buttons_row.dart lo llaman con esta firma.
  Future<void> toggleArrivalAlert({
    required UnitModel unit,
    required DateTime estimatedArrival,
  }) async {
    if (!state.hasPermission) {
      await requestPermission();
      if (!state.hasPermission) return;
    }

    if (state.hasScheduledAlert) {
      await _service.cancelArrivalAlert();
      state = state.copyWith(clearScheduledAlert: true);
    } else {
      await _service.toggleArrivalAlert(
        unit: unit,
        estimatedArrival: estimatedArrival,
        minutesBefore: AppConstants.etaUrgentThresholdMinutes,
      );
      state = state.copyWith(scheduledAlertUnitNumber: unit.unitNumber);
    }
  }

  // ── Delay alert ──────────────────────────────────────────────

  // FIX: onUnitDelayed() — tracking_service.dart lo llama directamente
  // en el notifier. Delega al service si las alertas están habilitadas.
  Future<void> onUnitDelayed(UnitModel unit, int delayMinutes) async {
    if (!state.delayAlertsEnabled || !state.hasPermission) return;
    await _service.onUnitDelayed(unit, delayMinutes);
  }

  // ── Visit & announcement ─────────────────────────────────────

  Future<void> onVisitConfirmed(String unitNumber, String checkpoint) async {
    if (!state.hasPermission) return;
    await _service.notifyVisitConfirmed(
      unitNumber: unitNumber,
      checkpointName: checkpoint,
    );
  }

  Future<void> onAnnouncement(
      String title, String body, String id) async {
    if (!state.announcementsEnabled || !state.hasPermission) return;
    await _service.notifyAnnouncement(
      title: title,
      body: body,
      announcementId: id,
    );
  }

  // ── Preference toggles ───────────────────────────────────────

  void setArrivalAlerts(bool enabled) =>
      state = state.copyWith(arrivalAlertsEnabled: enabled);

  void setDelayAlerts(bool enabled) =>
      state = state.copyWith(delayAlertsEnabled: enabled);

  void setAnnouncements(bool enabled) =>
      state = state.copyWith(announcementsEnabled: enabled);
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService(),
);

// FIX: cambiado de StateNotifierProvider a NotifierProvider — consistente
// con el resto del proyecto. StateNotifier está siendo deprecado en Riverpod.
final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

/// True si hay una alerta de llegada programada actualmente.
final hasScheduledAlertProvider = Provider<bool>(
  (ref) => ref.watch(notificationProvider).hasScheduledAlert,
);

/// True si el usuario concedió permiso de notificaciones.
final notificationPermissionProvider = Provider<bool>(
  (ref) => ref.watch(notificationProvider).hasPermission,
);
