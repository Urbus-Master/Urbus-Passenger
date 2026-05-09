import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

// FIX: corregido import — era 'package:tu_app/...' (placeholder),
// debe ser path relativo correcto dentro del proyecto Urbus.

enum AnnouncementIconType {
  info,
  warning,
  success,
  alert,
  schedule;

  static AnnouncementIconType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'warning'  => AnnouncementIconType.warning,
      'success'  => AnnouncementIconType.success,
      'alert'    => AnnouncementIconType.alert,
      'schedule' => AnnouncementIconType.schedule,
      _          => AnnouncementIconType.info,
    };
  }

  String toJson() => name;

  IconData get icon => switch (this) {
        AnnouncementIconType.warning  => Icons.warning_amber_rounded,
        AnnouncementIconType.success  => Icons.check_circle_outline_rounded,
        AnnouncementIconType.alert    => Icons.error_outline_rounded,
        AnnouncementIconType.schedule => Icons.schedule_rounded,
        AnnouncementIconType.info     => Icons.info_outline_rounded,
      };

  Color get color => switch (this) {
        AnnouncementIconType.warning  => AppColors.warning,
        AnnouncementIconType.success  => AppColors.success,
        AnnouncementIconType.alert    => AppColors.error,
        AnnouncementIconType.schedule => AppColors.info,
        AnnouncementIconType.info     => AppColors.accent,
      };

  Color get backgroundColor => switch (this) {
        AnnouncementIconType.warning  => AppColors.warningSubtle,
        AnnouncementIconType.success  => AppColors.successSubtle,
        AnnouncementIconType.alert    => AppColors.errorSubtle,
        AnnouncementIconType.schedule => AppColors.infoSubtle,
        AnnouncementIconType.info     => AppColors.accentSubtle,
      };

  String get label => switch (this) {
        AnnouncementIconType.warning  => 'Interrupción',
        AnnouncementIconType.success  => 'Servicio restaurado',
        AnnouncementIconType.alert    => 'Alerta crítica',
        AnnouncementIconType.schedule => 'Cambio de horario',
        AnnouncementIconType.info     => 'Información',
      };
}

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.source,
    required this.date,
    required this.isImportant,
    required this.iconType,
    this.isRead = false,
    this.expiresAt,
    this.routeId,
  });

  final int id;
  final String title;
  final String body;
  final String source;
  final DateTime date;
  final bool isImportant;
  final AnnouncementIconType iconType;
  final bool isRead;
  final DateTime? expiresAt;
  final String? routeId;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isActive => !isExpired;

  String get relativeTime {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1)  return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1)    return 'Ayer';
    if (diff.inDays < 7)     return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }

  // FIX: isLongBody — announcement_banner.dart lo usa para mostrar
  // el botón "Ver más" cuando el cuerpo supera los 180 caracteres.
  bool get isLongBody => body.length > 180;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title:       (json['title']  as String?) ?? '',
      body:        (json['body']   as String?) ?? '',
      source:      (json['source'] as String?) ?? '',
      date: DateTime.tryParse(
              json['date']?.toString() ?? '') ?? DateTime.now(),
      isImportant: (json['isImportant'] as bool?) ?? false,
      iconType: AnnouncementIconType.fromString(
          json['iconType'] as String?),
      isRead:   (json['isRead'] as bool?) ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      routeId: json['routeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':          id,
        'title':       title,
        'body':        body,
        'source':      source,
        'date':        date.toIso8601String(),
        'isImportant': isImportant,
        'iconType':    iconType.toJson(),
        'isRead':      isRead,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        if (routeId   != null) 'routeId':   routeId,
      };

  AnnouncementModel copyWith({
    int?                  id,
    String?               title,
    String?               body,
    String?               source,
    DateTime?             date,
    bool?                 isImportant,
    AnnouncementIconType? iconType,
    bool?                 isRead,
    DateTime?             expiresAt,
    String?               routeId,
  }) {
    return AnnouncementModel(
      id:          id          ?? this.id,
      title:       title       ?? this.title,
      body:        body        ?? this.body,
      source:      source      ?? this.source,
      date:        date        ?? this.date,
      isImportant: isImportant ?? this.isImportant,
      iconType:    iconType    ?? this.iconType,
      isRead:      isRead      ?? this.isRead,
      expiresAt:   expiresAt   ?? this.expiresAt,
      routeId:     routeId     ?? this.routeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AnnouncementModel(id: $id, title: $title, '
      'important: $isImportant, read: $isRead)';
}
