import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

// ─────────────────────────────────────────────
// UNIT STATUS
// ─────────────────────────────────────────────

enum UnitStatus { active, inactive, delayed }

extension UnitStatusX on UnitStatus {
  // FIX: getters de UI que los widgets esperaban en el enum.

  bool get isLive => this == UnitStatus.active;

  String get label => switch (this) {
        UnitStatus.active   => 'En ruta',
        UnitStatus.inactive => 'Inactivo',
        UnitStatus.delayed  => 'Demorado',
      };

  Color get color => switch (this) {
        UnitStatus.active   => AppColors.success,
        UnitStatus.inactive => AppColors.textSecondary,
        UnitStatus.delayed  => AppColors.warning,
      };

  Color get backgroundColor => switch (this) {
        UnitStatus.active   => AppColors.successSubtle,
        UnitStatus.inactive => AppColors.surfaceLight,
        UnitStatus.delayed  => AppColors.warningSubtle,
      };

  Color get borderColor => switch (this) {
        UnitStatus.active   => AppColors.success,
        UnitStatus.inactive => AppColors.border,
        UnitStatus.delayed  => AppColors.warning,
      };

  IconData get icon => switch (this) {
        UnitStatus.active   => Icons.radio_button_checked,
        UnitStatus.inactive => Icons.radio_button_unchecked,
        UnitStatus.delayed  => Icons.warning_amber_rounded,
      };
}

// ─────────────────────────────────────────────
// UNIT MODEL
// ─────────────────────────────────────────────

class UnitModel {
  final String id;
  final String unitNumber;
  final String driverName;
  final String? driverAvatar;
  final double driverRating;
  final double latitude;
  final double longitude;
  final double speed;
  final UnitStatus status;
  final DateTime lastUpdate;
  final String routeId;

  // FIX: heading agregado — TruckMarker lo usa para rotar el ícono
  // según la dirección de movimiento de la unidad.
  final double? heading;

  const UnitModel({
    required this.id,
    required this.unitNumber,
    required this.driverName,
    this.driverAvatar,
    required this.driverRating,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.status,
    required this.lastUpdate,
    required this.routeId,
    this.heading,
  });

  // ── Derived getters ──────────────────────────────────────────

  // FIX: driverInitials — UnitInfoCard lo usa para el avatar fallback
  // cuando no hay foto del conductor.
  String get driverInitials {
    final parts = driverName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // FIX: formattedSpeed — UnitInfoCard lo muestra en el chip de velocidad.
  String get formattedSpeed => Formatters.speed(speed);

  // FIX: lastUpdateLabel — UnitInfoCard lo usa para mostrar cuándo
  // se recibió la última posición GPS.
  String get lastUpdateLabel => Formatters.relative(lastUpdate);

  // ── Serialisation ────────────────────────────────────────────

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id:           json['id']?.toString() ?? '',
      unitNumber:   json['unitNumber'] as String? ?? '',
      driverName:   json['driverName'] as String? ?? '',
      driverAvatar: json['driverAvatar'] as String?,
      driverRating: (json['driverRating'] as num?)?.toDouble() ?? 0.0,
      latitude:     (json['latitude']  as num?)?.toDouble() ?? 0.0,
      longitude:    (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speed:        (json['speed']     as num?)?.toDouble() ?? 0.0,
      status: UnitStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? ''),
        orElse: () => UnitStatus.inactive,
      ),
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.tryParse(json['lastUpdate'] as String) ?? DateTime.now()
          : DateTime.now(),
      routeId: json['routeId']?.toString() ?? '',
      heading: (json['heading'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':           id,
        'unitNumber':   unitNumber,
        'driverName':   driverName,
        'driverAvatar': driverAvatar,
        'driverRating': driverRating,
        'latitude':     latitude,
        'longitude':    longitude,
        'speed':        speed,
        'status':       status.name,
        'lastUpdate':   lastUpdate.toIso8601String(),
        'routeId':      routeId,
        'heading':      heading,
      };

  UnitModel copyWith({
    String?     id,
    String?     unitNumber,
    String?     driverName,
    String?     driverAvatar,
    double?     driverRating,
    double?     latitude,
    double?     longitude,
    double?     speed,
    UnitStatus? status,
    DateTime?   lastUpdate,
    String?     routeId,
    double?     heading,
  }) {
    return UnitModel(
      id:           id           ?? this.id,
      unitNumber:   unitNumber   ?? this.unitNumber,
      driverName:   driverName   ?? this.driverName,
      driverAvatar: driverAvatar ?? this.driverAvatar,
      driverRating: driverRating ?? this.driverRating,
      latitude:     latitude     ?? this.latitude,
      longitude:    longitude    ?? this.longitude,
      speed:        speed        ?? this.speed,
      status:       status       ?? this.status,
      lastUpdate:   lastUpdate   ?? this.lastUpdate,
      routeId:      routeId      ?? this.routeId,
      heading:      heading      ?? this.heading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnitModel && id == other.id && status == other.status;

  @override
  int get hashCode => id.hashCode ^ status.hashCode;

  @override
  String toString() =>
      'UnitModel(id: $id, unit: #$unitNumber, status: ${status.name})';
}
