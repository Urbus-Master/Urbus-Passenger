import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/models/checkpoint_model.dart';
import '../../../core/models/unit_model.dart';
import '../../../core/services/tracking_service.dart';
import '../../../core/utils/formatters.dart';
import 'action_buttons_row.dart';
import 'checkpoint_progress.dart';
import 'unit_info_card.dart';

class BottomSheetCard extends ConsumerWidget {
  final PanelController panelController;

  const BottomSheetCard({
    super.key,
    required this.panelController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Space for the collapsed header — panel content starts below.
        const SizedBox(height: 130),

        // Scrollable expanded content.
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section 1 — ETA Hero ─────────────────────
                const _EtaHeroSection(),

                const _Divider(),

                // ── Section 2 — Checkpoint progress ──────────
                const _SectionTitle(title: 'Recorrido'),
                const CheckpointProgress(),

                const _Divider(),

                // ── Section 3 — Driver card ───────────────────
                const _SectionTitle(title: 'Conductor'),
                const UnitInfoCard(),

                const _Divider(),

                // ── Section 4 — Action buttons ────────────────
                const _SectionTitle(title: 'Acciones'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ActionButtonsRow(),
                ),

                const _Divider(),

                // ── Section 5 — Connection status ─────────────
                const _ConnectionStatus(),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// ETA HERO SECTION
// ─────────────────────────────────────────────

class _EtaHeroSection extends ConsumerWidget {
  const _EtaHeroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etaFormatted = ref.watch(etaFormattedProvider);
    final isUrgent = ref.watch(isEtaUrgentProvider);
    final activeUnit = ref.watch(activeUnitProvider);
    final checkpoints = ref.watch(checkpointsProvider);
    final currentCheckpoint = checkpoints
        .where((c) => c.status == CheckpointStatus.current)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ETA countdown ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LLEGA EN',
                  style: AppTypography.label.copyWith(
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),

                // Animated number swap on ETA change.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _EtaNumber(
                    key: ValueKey(etaFormatted),
                    value: etaFormatted,
                    isUrgent: isUrgent,
                  ),
                ),
                const SizedBox(height: 2),
                Text('minutos', style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                )),
              ],
            ),
          ),

          // ── Status chip ─────────────────────────────────────
          if (activeUnit != null)
            _StatusChip(unit: activeUnit, currentCheckpoint: currentCheckpoint),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ETA NUMBER
// ─────────────────────────────────────────────

class _EtaNumber extends StatelessWidget {
  final String value;
  final bool isUrgent;

  const _EtaNumber({
    super.key,
    required this.value,
    required this.isUrgent,
  });

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
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Text(
        value,
        style: AppTypography.eta.copyWith(
          // Pulse the color slightly when urgent.
          color: isUrgent
              ? AppColors.accent
              : AppColors.accent.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final UnitModel unit;
  final CheckpointModel? currentCheckpoint;

  const _StatusChip({required this.unit, this.currentCheckpoint});

  bool get _isOnTime => unit.status == UnitStatus.active;

  /// Minutes past the current checkpoint's estimated arrival time —
  /// derived from live data instead of a fixed placeholder.
  int get _delayMinutes {
    if (unit.status != UnitStatus.delayed || currentCheckpoint == null) {
      return 0;
    }
    final diff = DateTime.now().difference(currentCheckpoint!.estimatedTime);
    return diff.inMinutes > 0 ? diff.inMinutes : 0;
  }

  Color get _bg => _isOnTime
      ? AppColors.success.withValues(alpha: 0.10)
      : AppColors.warning.withValues(alpha: 0.10);

  Color get _border => _isOnTime ? AppColors.success : AppColors.warning;
  Color get _text => _isOnTime ? AppColors.success : AppColors.warning;

  String get _label => _isOnTime
      ? 'A tiempo'
      : Formatters.delay(_delayMinutes);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _text,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: AppTypography.bodySmall.copyWith(
              color: _text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CONNECTION STATUS
// ─────────────────────────────────────────────

class _ConnectionStatus extends ConsumerWidget {
  const _ConnectionStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider);
    final isConnected = status == ConnectionStatus.connected;
    final isReconnecting = status == ConnectionStatus.reconnecting;

    final color = isConnected
        ? AppColors.success
        : isReconnecting
            ? AppColors.warning
            : AppColors.error;

    final label = isConnected
        ? 'Conectado en tiempo real'
        : isReconnecting
            ? 'Reconectando...'
            : 'Sin conexión';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot for connected state.
          _PulsingDot(color: color, pulse: isConnected),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: color),
          ),
          if (isReconnecting) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(AppColors.warning),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PULSING DOT
// ─────────────────────────────────────────────

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
    if (!widget.pulse) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(title, style: AppTypography.h3),
    );
  }
}

// ─────────────────────────────────────────────
// DIVIDER
// ─────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      color: AppColors.border,
    );
  }
}
