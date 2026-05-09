import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

enum AlertType { arrival, delay, announcement }

class AlertModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final AlertType type;
  final bool isRead;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  AlertModel copyWith({bool? isRead}) {
    return AlertModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}

class AlertItem extends StatelessWidget {
  final AlertModel alert;
  const AlertItem({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final iconData = switch (alert.type) {
      AlertType.arrival => Icons.notifications_active_rounded,
      AlertType.delay => Icons.timer_rounded,
      AlertType.announcement => Icons.campaign_rounded,
    };

    final color = switch (alert.type) {
      AlertType.arrival => AppColors.accent,
      AlertType.delay => AppColors.warning,
      AlertType.announcement => AppColors.success,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: alert.isRead ? Colors.transparent : AppColors.accent.withValues(alpha: 0.2),
        ),
        boxShadow: AppColors.shadowLow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      alert.title,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: alert.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlertsNotifier extends Notifier<List<AlertModel>> {
  @override
  List<AlertModel> build() {
    return [
      AlertModel(
        id: '1',
        title: '¡Ya casi llega!',
        message: 'La unidad 405 está a menos de 5 minutos de tu ubicación.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: AlertType.arrival,
        isRead: false,
      ),
      AlertModel(
        id: '2',
        title: 'Servicio demorado',
        message: 'La ruta Centro-Sur presenta un retraso de 10 minutos por tráfico.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: AlertType.delay,
        isRead: true,
      ),
      AlertModel(
        id: '3',
        title: 'Cambio de parada',
        message: 'La parada de la Calle 50 ha sido movida temporalmente 100m al norte.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: AlertType.announcement,
        isRead: true,
      ),
    ];
  }

  void markAllAsRead() {
    state = state.map((a) => a.copyWith(isRead: true)).toList();
  }
}

final alertsProvider = NotifierProvider<AlertsNotifier, List<AlertModel>>(AlertsNotifier.new);

final unreadAlertsCountProvider = Provider<int>((ref) {
  return ref.watch(alertsProvider).where((a) => !a.isRead).length;
});
