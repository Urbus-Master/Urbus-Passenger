import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
// FIX: AlertModel, AlertsNotifier, alertsProvider y AlertItem
// viven todos en alert_item.dart — un solo import reemplaza los dos anteriores.
import '../widgets/alert_item.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/success_overlay.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: el provider retorna List<AlertModel> directamente, no un estado rico.
    final alerts = ref.watch(alertsProvider);
    final notifier = ref.read(alertsProvider.notifier);
    final unreadCount = ref.watch(unreadAlertsCountProvider);

    // FIX: las preferencias de notificación viven en notificationProvider,
    // no en alertsProvider. Se leen desde ahí.
    final notifState = ref.watch(notificationProvider);
    final notifNotifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── App bar ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alertas', style: AppTypography.h2),
                          if (unreadCount > 0)
                            Text(
                              '$unreadCount sin leer',
                              style: AppTypography.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    if (alerts.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          notifier.markAllAsRead();
                          SuccessOverlay.show(
                            context,
                            title: '¡Todo limpio!',
                            subtitle: 'Has leído todas tus alertas',
                          );
                        },
                        child: Text(
                          'Limpiar todo',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Notification config card ─────────────────────
            SliverToBoxAdapter(
              child: _ConfigCard(
                // FIX: los toggles leen desde notificationProvider,
                // no desde alertsProvider que ya no tiene estos campos.
                arrivalEnabled: notifState.arrivalAlertsEnabled,
                delayEnabled: notifState.delayAlertsEnabled,
                announcementsEnabled: notifState.announcementsEnabled,
                onArrivalChanged: notifNotifier.setArrivalAlerts,
                onDelayChanged: notifNotifier.setDelayAlerts,
                onAnnouncementsChanged: notifNotifier.setAnnouncements,
              ),
            ),

            // ── Section title + count badge ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    Text('Recientes', style: AppTypography.h3),
                    const Spacer(),
                    if (alerts.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          Formatters.badgeCount(alerts.length),
                          style: AppTypography.label.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────
            if (_isLoading)
              const _ShimmerList()
            else if (alerts.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => AlertItem(
                    alert: alerts[index],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NOTIFICATION CONFIG CARD
// ─────────────────────────────────────────────

class _ConfigCard extends StatelessWidget {
  final bool arrivalEnabled;
  final bool delayEnabled;
  final bool announcementsEnabled;
  final ValueChanged<bool> onArrivalChanged;
  final ValueChanged<bool> onDelayChanged;
  final ValueChanged<bool> onAnnouncementsChanged;

  const _ConfigCard({
    required this.arrivalEnabled,
    required this.delayEnabled,
    required this.announcementsEnabled,
    required this.onArrivalChanged,
    required this.onDelayChanged,
    required this.onAnnouncementsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.whiteSubtle),
        boxShadow: AppColors.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text('Configuración', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: 16),
          _SwitchRow(
            icon: Icons.notifications_active_rounded,
            iconColor: AppColors.accent,
            title: 'Llegada próxima',
            subtitle: 'Alerta a los 5 minutos',
            value: arrivalEnabled,
            onChanged: onArrivalChanged,
          ),
          const SizedBox(height: 12),
          _SwitchRow(
            icon: Icons.timer_rounded,
            iconColor: AppColors.warning,
            title: 'Retrasos',
            subtitle: 'Aviso de demoras',
            value: delayEnabled,
            onChanged: onDelayChanged,
          ),
          const SizedBox(height: 12),
          _SwitchRow(
            icon: Icons.campaign_rounded,
            iconColor: AppColors.success,
            title: 'Comunicados',
            subtitle: 'Avisos municipales',
            value: announcementsEnabled,
            onChanged: onAnnouncementsChanged,
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.accent,
          activeTrackColor: AppColors.accent.withValues(alpha: 0.2),
          inactiveThumbColor: AppColors.textHint,
          inactiveTrackColor: AppColors.border,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 32,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin alertas',
              style: AppTypography.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las notificaciones de tu servicio\naparecerán aquí',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return const SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            _SkeletonItem(),
            SizedBox(height: 12),
            _SkeletonItem(),
            SizedBox(height: 12),
            _SkeletonItem(),
          ],
        ),
      ),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.whiteSubtle),
      ),
      child: Row(
        children: [
          const Skeleton(height: 44, width: 44, borderRadius: 14),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 16, width: 120),
                const SizedBox(height: 8),
                const Skeleton(height: 12, width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
