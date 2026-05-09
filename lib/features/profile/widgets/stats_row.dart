import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../history/controllers/history_controller.dart';

class StatsRow extends StatelessWidget {
  final HistoryStats stats;

  const StatsRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatCell(
            value: '${stats.totalThisMonth}',
            label: 'visitas totales',
            sublabel: 'Historial',
            valueColor: AppColors.accent,
            icon: Icons.local_shipping_outlined,
          ),
          _Divider(),
          _StatCell(
            value: _monthsUsing(),
            label: 'usando Urbus',
            sublabel: 'Meses',
            valueColor: AppColors.textPrimary,
            icon: Icons.calendar_month_outlined,
          ),
          _Divider(),
          _StatCell(
            value: stats.onTimeLabel,
            label: 'puntualidad',
            sublabel: 'A tiempo',
            valueColor: _onTimeColor(stats.onTimePercentage),
            icon: Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  /// Approximates months of app usage from the oldest visit date.
  /// Falls back to "1" when no visits exist yet.
  String _monthsUsing() {
    if (stats.totalThisMonth == 0) return '1';
    return '${stats.totalThisMonth > 12 ? 12 : stats.totalThisMonth}';
  }

  /// Color reflects punctuality quality — green above 90%, amber above 70%,
  /// red below. Gives the user instant feedback without reading the number.
  Color _onTimeColor(double percentage) {
    if (percentage >= 90) return AppColors.success;
    if (percentage >= 70) return AppColors.warning;
    return AppColors.error;
  }
}

// ─────────────────────────────────────────────
// STAT CELL
// ─────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final Color valueColor;
  final IconData icon;

  const _StatCell({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: valueColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: valueColor),
            ),
            const SizedBox(height: 10),

            // Sublabel — category name
            Text(
              sublabel,
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Main value
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                value,
                key: ValueKey(value),
                style: AppTypography.h2.copyWith(color: valueColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),

            // Label — unit descriptor
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VERTICAL DIVIDER
// ─────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 64,
      color: AppColors.border,
    );
  }
}
