import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/models/visit_model.dart';
import '../../../core/utils/formatters.dart';

class VisitCard extends StatelessWidget {
  final VisitModel visit;
  final VoidCallback? onTap;

  const VisitCard({
    super.key,
    required this.visit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Visita del ${Formatters.fullDate(visit.arrivedAt)}, '
          '${Formatters.unitLabel(visit.unitNumber)}, '
          '${visit.wasOnTime ? 'a tiempo' : 'con retraso de ${visit.delayMinutes} minutos'}',
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.accent.withValues(alpha: 0.06),
          highlightColor: AppColors.accent.withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.whiteSubtle),
              boxShadow: AppColors.shadowLow,
            ),
            child: Row(
              children: [
                // ── Left — date icon + info ──────────────────
                _DateBadge(date: visit.arrivedAt),
                const SizedBox(width: 16),

                // ── Center — main info ───────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time
                      Text(
                        visit.time,
                        style: AppTypography.h3.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 6),

                      // Unit number
                      Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Formatters.unitLabel(visit.unitNumber),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Checkpoint name
                      Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              visit.checkpointName,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // ── Right — status badge + chevron ───────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(
                      wasOnTime: visit.wasOnTime,
                      delayMinutes: visit.delayMinutes,
                    ),
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DATE BADGE
// ─────────────────────────────────────────────

class _DateBadge extends StatelessWidget {
  final DateTime date;

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Formatters.weekdayShort(date).toUpperCase(),
            style: AppTypography.label.copyWith(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: AppTypography.h3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.shortDate(date).split(' ').last.toUpperCase(),
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool wasOnTime;
  final int delayMinutes;

  const _StatusBadge({
    required this.wasOnTime,
    required this.delayMinutes,
  });

  Color get _bg => wasOnTime
      ? AppColors.success.withValues(alpha: 0.10)
      : AppColors.warning.withValues(alpha: 0.10);

  Color get _border =>
      wasOnTime ? AppColors.success : AppColors.warning;

  Color get _text =>
      wasOnTime ? AppColors.success : AppColors.warning;

  String get _label => Formatters.delay(delayMinutes);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _border, width: 1),
      ),
      child: Text(
        _label,
        style: AppTypography.bodySmall.copyWith(
          color: _text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
