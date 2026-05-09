import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/tracking_service.dart';
import '../../../core/models/unit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ETA DISPLAY — PUBLIC API
// ─────────────────────────────────────────────────────────────────────────────

/// Displays the estimated time of arrival in two visual variants:
///
/// - [EtaDisplay.hero]    — large countdown for the expanded bottom sheet.
/// - [EtaDisplay.compact] — small inline countdown for the collapsed header.
///
/// Both variants respond to [trackingProvider] and [isEtaUrgentProvider]
/// so they animate automatically when the ETA changes or becomes urgent.
class EtaDisplay extends ConsumerWidget {
  const EtaDisplay._({
    required _EtaVariant variant,
    super.key,
  }) : _variant = variant;

  /// Large hero ETA — for the expanded bottom-sheet section.
  const EtaDisplay.hero({Key? key})
      : this._(variant: _EtaVariant.hero, key: key);

  /// Compact inline ETA — for the collapsed header strip.
  const EtaDisplay.compact({Key? key})
      : this._(variant: _EtaVariant.compact, key: key);

  final _EtaVariant _variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingProvider);
    final etaFormatted = ref.watch(etaFormattedProvider);
    final isUrgent = ref.watch(isEtaUrgentProvider);
    final hasUnit = state.hasUnit;

    return switch (_variant) {
      _EtaVariant.hero => _HeroEta(
          etaFormatted: etaFormatted,
          isUrgent: isUrgent,
          hasUnit: hasUnit,
          state: state,
        ),
      _EtaVariant.compact => _CompactEta(
          etaFormatted: etaFormatted,
          isUrgent: isUrgent,
          hasUnit: hasUnit,
        ),
    };
  }
}

enum _EtaVariant { hero, compact }

// ─────────────────────────────────────────────────────────────────────────────
// HERO ETA  (expanded bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroEta extends StatelessWidget {
  final String etaFormatted;
  final bool isUrgent;
  final bool hasUnit;
  final TrackingState state;

  const _HeroEta({
    required this.etaFormatted,
    required this.isUrgent,
    required this.hasUnit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Countdown column ──────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  'LLEGA EN',
                  style: AppTypography.label.copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 6),

                // Animated digit swap.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _GlowDigits(
                    key: ValueKey(etaFormatted),
                    value: etaFormatted,
                    isUrgent: isUrgent,
                  ),
                ),

                const SizedBox(height: 2),
                Text(
                  'minutos',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                // Distance sub-label when available.
                if (state.eta != null) ...[
                  const SizedBox(height: 6),
                  _DistanceLabel(eta: state.eta!),
                ],
              ],
            ),
          ),

          // ── Right side: status chip ───────────────────────────
          if (state.activeUnit != null)
            _UnitStatusChip(unit: state.activeUnit!)
          else
            _SearchingChip(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT ETA  (collapsed header)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactEta extends StatelessWidget {
  final String etaFormatted;
  final bool isUrgent;
  final bool hasUnit;

  const _CompactEta({
    required this.etaFormatted,
    required this.isUrgent,
    required this.hasUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Clock icon
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: isUrgent ? AppColors.accent : AppColors.textSecondary,
        ),
        const SizedBox(width: 5),

        // Animated countdown.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: Text(
            key: ValueKey(etaFormatted),
            etaFormatted,
            style: AppTypography.etaSmall.copyWith(
              color: isUrgent
                  ? AppColors.accent
                  : AppColors.accent.withValues(alpha: 0.85),
            ),
          ),
        ),

        const SizedBox(width: 4),
        Text(
          'min',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        // Urgent badge.
        if (isUrgent) ...[
          const SizedBox(width: 8),
          _UrgentBadge(),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOW DIGITS  (hero countdown with optional glow)
// ─────────────────────────────────────────────────────────────────────────────

class _GlowDigits extends StatelessWidget {
  final String value;
  final bool isUrgent;

  const _GlowDigits({super.key, required this.value, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ]
            : [],
      ),
      child: Text(
        value,
        style: AppTypography.eta.copyWith(
          color:
              isUrgent ? AppColors.accent : AppColors.accent.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DISTANCE LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _DistanceLabel extends StatelessWidget {
  final Duration eta;

  const _DistanceLabel({required this.eta});

  @override
  Widget build(BuildContext context) {
    // Derive a rough distance estimate from ETA using 25 km/h default speed.
    // The actual value comes from EtaResult but Duration is stored in state.
    final distanceMetres = (eta.inSeconds / 3600) * 25 * 1000;
    final label = distanceMetres >= 1000
        ? '${(distanceMetres / 1000).toStringAsFixed(1)} km restantes'
        : '${distanceMetres.round()} m restantes';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.straighten_rounded,
          size: 12,
          color: AppColors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textHint,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIT STATUS CHIP  (shown beside hero ETA)
// ─────────────────────────────────────────────────────────────────────────────

class _UnitStatusChip extends StatelessWidget {
  final UnitModel unit;

  const _UnitStatusChip({required this.unit});

  @override
  Widget build(BuildContext context) {
    final isOnTime = unit.status == UnitStatus.active;

    final bgColor = isOnTime
        ? AppColors.successSubtle
        : AppColors.warningSubtle;
    final borderColor = isOnTime ? AppColors.success : AppColors.warning;
    final textColor = isOnTime ? AppColors.success : AppColors.warning;

    final label = isOnTime ? 'A tiempo' : 'Demorado';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot
          _PulsingDot(color: borderColor, pulse: isOnTime),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCHING CHIP  (shown when no unit is active yet)
// ─────────────────────────────────────────────────────────────────────────────

class _SearchingChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Buscando...',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// URGENT BADGE  (compact variant)
// ─────────────────────────────────────────────────────────────────────────────

class _UrgentBadge extends StatefulWidget {
  @override
  State<_UrgentBadge> createState() => _UrgentBadgeState();
}

class _UrgentBadgeState extends State<_UrgentBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.5,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.accentMedium,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flash_on_rounded,
              size: 10,
              color: AppColors.accent,
            ),
            const SizedBox(width: 3),
            Text(
              '¡Cerca!',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PULSING DOT  (reused in status chip)
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool pulse;

  const _PulsingDot({required this.color, required this.pulse});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.4,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        boxShadow: widget.pulse
            ? [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
    );

    if (!widget.pulse) return dot;
    return FadeTransition(opacity: _opacity, child: dot);
  }
}
