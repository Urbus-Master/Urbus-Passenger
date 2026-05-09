import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/tracking_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/formatters.dart';

class ActionButtonsRow extends ConsumerWidget {
  const ActionButtonsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(trackingProvider);
    final isAlertScheduled = ref.watch(hasScheduledAlertProvider);
    final activeUnit = ref.watch(activeUnitProvider);

    return Row(
      children: [
        // ── Alert me ────────────────────────────────────────
        _ActionButton(
          icon: isAlertScheduled
              ? Icons.notifications_active
              : Icons.notifications_outlined,
          label: isAlertScheduled ? 'Alertado' : 'Alertarme',
          isActive: isAlertScheduled,
          onTap: activeUnit != null
              ? () => _handleAlert(context, ref, trackingState)
              : null,
        ),

        const SizedBox(width: 8),

        // ── Share ────────────────────────────────────────────
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Compartir',
          onTap: activeUnit != null
              ? () => _handleShare(context, ref)
              : null,
        ),

        const SizedBox(width: 8),

        // ── My route ─────────────────────────────────────────
        _ActionButton(
          icon: Icons.route_outlined,
          label: 'Mi ruta',
          onTap: () => Navigator.of(context).pushNamed('/history'),
        ),
      ],
    );
  }

  // ── Handlers ─────────────────────────────────────────────────

  Future<void> _handleAlert(
    BuildContext context,
    WidgetRef ref,
    TrackingState trackingState,
  ) async {
    // Haptic feedback on toggle.
    HapticFeedback.lightImpact();

    final hasPermission = ref.read(notificationPermissionProvider);

    if (!hasPermission) {
      _showPermissionSheet(context, ref);
      return;
    }

    await ref.read(trackingProvider.notifier).toggleAlert();

    if (context.mounted) {
      final isNowActive = ref.read(hasScheduledAlertProvider);
      _showFeedbackSnackbar(
        context,
        isNowActive
            ? '🔔 Te avisaremos cuando la unidad esté cerca'
            : '🔕 Alerta cancelada',
        isNowActive ? AppColors.success : AppColors.textSecondary,
      );
    }
  }

  Future<void> _handleShare(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    final unit = ref.read(activeUnitProvider);
    final eta = ref.read(etaFormattedProvider);

    if (unit == null) return;

    final text = '📍 Estoy siguiendo mi servicio con Urbus\n'
        '${Formatters.unitLabel(unit.unitNumber)} — '
        'Conductor: ${unit.driverName}\n'
        '⏱ Tiempo estimado de llegada: $eta min\n'
        'Descarga Urbus para rastrear tu servicio en tiempo real.';

    // Share via platform share sheet.
    // Uses Clipboard as fallback when share_plus is not available.
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        _showFeedbackSnackbar(
          context,
          'Información copiada al portapapeles',
          AppColors.accent,
        );
      }
    } catch (_) {
      if (context.mounted) {
        _showFeedbackSnackbar(
          context,
          'No se pudo compartir. Intenta de nuevo.',
          AppColors.error,
        );
      }
    }
  }

  // ── Permission bottom sheet ───────────────────────────────────

  void _showPermissionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _PermissionSheet(
        onAllow: () async {
          Navigator.pop(context);
          await ref
              .read(notificationProvider.notifier)
              .requestPermission();
          // Retry alert toggle after permission granted.
          if (context.mounted) {
            await ref.read(trackingProvider.notifier).toggleAlert();
          }
        },
      ),
    );
  }

  // ── Snackbar helper ───────────────────────────────────────────

  void _showFeedbackSnackbar(
    BuildContext context,
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTypography.bodySmall),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }
}

// ─────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.93,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return Expanded(
      child: Semantics(
        button: true,
        label: widget.label,
        enabled: !isDisabled,
        child: ScaleTransition(
          scale: _scaleController,
          child: GestureDetector(
            onTap: isDisabled ? null : widget.onTap,
            onTapDown: isDisabled
                ? null
                : (_) => _scaleController.reverse(),
            onTapUp: isDisabled
                ? null
                : (_) => _scaleController.forward(),
            onTapCancel: isDisabled
                ? null
                : () => _scaleController.forward(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? AppColors.accent.withValues(alpha: 0.08)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isActive
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : AppColors.border,
                  width: 1,
                ),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isDisabled ? 0.4 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon badge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.isActive
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.accent.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 18,
                        color: widget.isActive
                            ? AppColors.accent
                            : AppColors.accent.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Label
                    Text(
                      widget.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: widget.isActive
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontWeight: widget.isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PERMISSION BOTTOM SHEET
// ─────────────────────────────────────────────

class _PermissionSheet extends StatelessWidget {
  final VoidCallback onAllow;

  const _PermissionSheet({required this.onAllow});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bell icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: AppColors.accent,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Activa las notificaciones',
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Para avisarte cuando tu unidad esté\na punto de llegar necesitamos\ntu permiso de notificaciones.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Allow button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onAllow,
              child: const Text('Permitir notificaciones'),
            ),
          ),
          const SizedBox(height: 12),

          // Dismiss
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ahora no',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
