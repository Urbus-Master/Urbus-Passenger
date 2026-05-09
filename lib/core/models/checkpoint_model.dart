import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../app/theme/app_colors.dart';

// ─────────────────────────────────────────────
// CHECKPOINT STATUS
// ─────────────────────────────────────────────

enum CheckpointStatus { completed, current, upcoming }

extension CheckpointStatusX on CheckpointStatus {
  // FIX: getters de UI que map_widget.dart y checkpoint_progress.dart
  // esperaban directamente del enum — no existían en el original.

  String get label => switch (this) {
        CheckpointStatus.completed => 'Completada',
        CheckpointStatus.current   => 'En curso',
        CheckpointStatus.upcoming  => 'Próxima',
      };

  Color get color => switch (this) {
        CheckpointStatus.completed => AppColors.success,
        CheckpointStatus.current   => AppColors.accent,
        CheckpointStatus.upcoming  => AppColors.textSecondary,
      };

  Color get borderColor => switch (this) {
        CheckpointStatus.completed => AppColors.success,
        CheckpointStatus.current   => AppColors.accent,
        CheckpointStatus.upcoming  => AppColors.borderActive,
      };

  // FIX: markerSize — map_widget.dart lo usa para el tamaño del pin
  // en el mapa. Current es más grande para destacar la parada activa.
  double get markerSize => switch (this) {
        CheckpointStatus.completed => 28.0,
        CheckpointStatus.current   => 36.0,
        CheckpointStatus.upcoming  => 28.0,
      };

  // FIX: isPulsing — map_widget.dart lo usa para activar la animación
  // de pulso solo en el checkpoint activo.
  bool get isPulsing => this == CheckpointStatus.current;

  IconData get icon => switch (this) {
        CheckpointStatus.completed => Icons.check_rounded,
        CheckpointStatus.current   => Icons.local_shipping_rounded,
        CheckpointStatus.upcoming  => Icons.circle_outlined,
      };
}

// ─────────────────────────────────────────────
// CHECKPOINT MODEL
// ─────────────────────────────────────────────

class CheckpointModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int order;
  final DateTime estimatedTime;
  final CheckpointStatus status;

  // FIX: actualTime — tiempo real de llegada cuando el checkpoint
  // ya fue completado. Null mientras está pendiente.
  // checkpoint_progress.dart lo usa para mostrar la hora real vs estimada.
  final DateTime? actualTime;

  // FIX: delayMinutes — minutos de retraso al completar el checkpoint.
  // checkpoint_progress.dart lo usa para el badge de retraso.
  final int? delayMinutes;

  const CheckpointModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.order,
    required this.estimatedTime,
    required this.status,
    this.actualTime,
    this.delayMinutes,
  });

  // ── Derived getters ──────────────────────────────────────────

  // FIX: latLng — map_widget.dart lo usa para construir los puntos
  // de la polyline y los marcadores sin conversión manual en cada widget.
  LatLng get latLng => LatLng(latitude, longitude);

  // FIX: formattedTime — checkpoint_progress.dart lo usa para mostrar
  // la hora estimada en el progress bar.
  String get formattedTime {
    final h = estimatedTime.hour % 12 == 0 ? 12 : estimatedTime.hour % 12;
    final m = estimatedTime.minute.toString().padLeft(2, '0');
    final period = estimatedTime.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  // FIX: wasDelayed — checkpoint_progress.dart lo usa para mostrar
  // el badge de retraso solo cuando el checkpoint fue completado tarde.
  bool get wasDelayed =>
      status == CheckpointStatus.completed &&
      delayMinutes != null &&
      delayMinutes! > 0;

  // ── Serialisation ────────────────────────────────────────────

  factory CheckpointModel.fromJson(Map<String, dynamic> json) {
    return CheckpointModel(
      id:      json['id']?.toString() ?? '',
      name:    (json['name']    as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      latitude:  (json['latitude']  as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      order:   (json['order'] as int?) ?? 0,
      estimatedTime: DateTime.tryParse(
              json['estimatedTime']?.toString() ?? '') ??
          DateTime.now(),
      status: CheckpointStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? ''),
        orElse: () => CheckpointStatus.upcoming,
      ),
      actualTime: json['actualTime'] != null
          ? DateTime.tryParse(json['actualTime'].toString())
          : null,
      delayMinutes: json['delayMinutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':            id,
        'name':          name,
        'address':       address,
        'latitude':      latitude,
        'longitude':     longitude,
        'order':         order,
        'estimatedTime': estimatedTime.toIso8601String(),
        'status':        status.name,
        if (actualTime    != null) 'actualTime':    actualTime!.toIso8601String(),
        if (delayMinutes  != null) 'delayMinutes':  delayMinutes,
      };

  CheckpointModel copyWith({
    String?           id,
    String?           name,
    String?           address,
    double?           latitude,
    double?           longitude,
    int?              order,
    DateTime?         estimatedTime,
    CheckpointStatus? status,
    DateTime?         actualTime,
    int?              delayMinutes,
  }) {
    return CheckpointModel(
      id:            id            ?? this.id,
      name:          name          ?? this.name,
      address:       address       ?? this.address,
      latitude:      latitude      ?? this.latitude,
      longitude:     longitude     ?? this.longitude,
      order:         order         ?? this.order,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      status:        status        ?? this.status,
      actualTime:    actualTime    ?? this.actualTime,
      delayMinutes:  delayMinutes  ?? this.delayMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckpointModel && id == other.id && status == other.status;

  @override
  int get hashCode => id.hashCode ^ status.hashCode;

  @override
  String toString() =>
      'CheckpointModel(id: $id, name: $name, status: ${status.name})';
}
