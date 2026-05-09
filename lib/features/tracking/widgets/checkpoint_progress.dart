import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/models/checkpoint_model.dart';
import '../../../core/services/tracking_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHECKPOINT PROGRESS
// ─────────────────────────────────────────────────────────────────────────────

/// Vertical timeline showing all route checkpoints with their current status.
///
/// - Completed stops → filled teal circle with checkmark icon.
/// - Current stop    → larger pulsing teal circle with truck icon.
/// - Upcoming stops  → outlined grey circle with sequential order number.
///
/// Consumes [checkpointsProvider] so it only rebuilds when the list changes,
/// not on every ETA tick.
class CheckpointProgress extends ConsumerWidget {
  const CheckpointProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkpoints = ref.watch(checkpointsProvider);

    if (checkpoints.isEmpty) {
      return const _EmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(checkpoints.length, (index) {
          final checkpoint = checkpoints[index];
          final isLast = index == checkpoints.length - 1;

          return _CheckpointTile(
            checkpoint: checkpoint,
            isLast: isLast,
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHECKPOINT TILE
// ─────────────────────────────────────────────────────────────────────────────

class _CheckpointTile extends StatelessWidget {
  final CheckpointModel checkpoint;
  final bool isLast;

  const _CheckpointTile({
    required this.checkpoint,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left column: circle + connector line ─────────────
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Top connector — hidden for the first tile.
                _ConnectorSegment(
                  isVisible: checkpoint.order > 1,
                  isDone: checkpoint.status == CheckpointStatus.completed ||
                      checkpoint.status == CheckpointStatus.current,
                ),

                // Circle marker.
                _CircleMarker(checkpoint: checkpoint),

                // Bottom connector — hidden for the last tile.
                Expanded(
                  child: _ConnectorSegment(
                    isVisible: !isLast,
                    isDone: checkpoint.status == CheckpointStatus.completed,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Right column: content ────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 4),
              child: _CheckpointContent(checkpoint: checkpoint),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONNECTOR SEGMENT
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectorSegment extends StatelessWidget {
  final bool isVisible;
  final bool isDone;

  const _ConnectorSegment({
    required this.isVisible,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1, // Thinner line
      height: 12,
      child: isVisible
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.accent.withValues(alpha: 0.8)
                    : AppColors.border.withValues(alpha: 0.5),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCLE MARKER
// ─────────────────────────────────────────────────────────────────────────────

class _CircleMarker extends StatelessWidget {
  final CheckpointModel checkpoint;

  const _CircleMarker({required this.checkpoint});

  @override
  Widget build(BuildContext context) {
    if (checkpoint.status == CheckpointStatus.current) {
      return _PulsingCircle(checkpoint: checkpoint);
    }

    return _StaticCircle(checkpoint: checkpoint);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATIC CIRCLE (completed / upcoming)
// ─────────────────────────────────────────────────────────────────────────────

class _StaticCircle extends StatelessWidget {
  final CheckpointModel checkpoint;

  const _StaticCircle({required this.checkpoint});

  bool get _isCompleted => checkpoint.status == CheckpointStatus.completed;

  @override
  Widget build(BuildContext context) {
    const size = 28.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _isCompleted ? AppColors.accent : AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: _isCompleted ? AppColors.accent : AppColors.borderActive,
          width: 1.5,
        ),
        boxShadow: _isCompleted
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: Center(
        child: _isCompleted
            ? const Icon(
                Icons.check_rounded,
                color: AppColors.background,
                size: 14,
              )
            : Text(
                '${checkpoint.order}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PULSING CIRCLE (current checkpoint)
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingCircle extends StatefulWidget {
  final CheckpointModel checkpoint;

  const _PulsingCircle({required this.checkpoint});

  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.85,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _ring = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 36.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return SizedBox(
          width: size + 14,
          height: size + 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring.
              Opacity(
                opacity: (1 - _ring.value) * 0.5,
                child: Container(
                  width: size + 14 * _ring.value,
                  height: size + 14 * _ring.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Inner circle with scale.
              Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.40),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.background,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHECKPOINT CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _CheckpointContent extends StatelessWidget {
  final CheckpointModel checkpoint;

  const _CheckpointContent({required this.checkpoint});

  bool get _isCompleted => checkpoint.status == CheckpointStatus.completed;
  bool get _isCurrent => checkpoint.status == CheckpointStatus.current;
  bool get _isUpcoming => checkpoint.status == CheckpointStatus.upcoming;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isCurrent
            ? AppColors.accent.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isCurrent
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.whiteSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name row + status badge ──────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  checkpoint.name,
                  style: AppTypography.bodyBold.copyWith(
                    color: _isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration: _isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: checkpoint.status),
            ],
          ),

          const SizedBox(height: 4),

          // ── Address ─────────────────────────────────────────
          Text(
            checkpoint.address,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // ── Time row ─────────────────────────────────────────
          Row(
            children: [
              Icon(
                _isCompleted
                    ? Icons.check_circle_outline_rounded
                    : Icons.schedule_rounded,
                size: 12,
                color: _isCurrent ? AppColors.accent : AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                _isCompleted && checkpoint.actualTime != null
                    ? _formatTime(checkpoint.actualTime!)
                    : checkpoint.formattedTime,
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: _isCurrent
                      ? AppColors.accent
                      : _isCompleted
                          ? AppColors.textHint
                          : AppColors.textSecondary,
                ),
              ),

              // Delay badge — shown only when unit arrived late.
              if (_isCompleted && checkpoint.wasDelayed) ...[
                const SizedBox(width: 6),
                _DelayBadge(minutes: checkpoint.delayMinutes!),
              ],

              // ETA label for upcoming.
              if (_isUpcoming) ...[
                const Spacer(),
                Text(
                  'Estimado',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final CheckpointStatus status;

  const _StatusBadge({required this.status});

  Color get _bg => switch (status) {
        CheckpointStatus.completed => AppColors.successSubtle,
        CheckpointStatus.current => AppColors.accentMedium,
        CheckpointStatus.upcoming => AppColors.whiteSubtle,
      };

  Color get _text => switch (status) {
        CheckpointStatus.completed => AppColors.success,
        CheckpointStatus.current => AppColors.accent,
        CheckpointStatus.upcoming => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        status.label,
        style: AppTypography.bodySmall.copyWith(
          color: _text,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELAY BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _DelayBadge extends StatelessWidget {
  final int minutes;

  const _DelayBadge({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.warningSubtle,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_upward_rounded,
            size: 8,
            color: AppColors.warning,
          ),
          const SizedBox(width: 2),
          Text(
            '+${minutes}min',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.warning,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_outlined,
              size: 32,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin paradas disponibles',
              style: AppTypography.bodyBold.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'El recorrido se mostrará en cuanto\nla unidad inicie su ruta.',
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
