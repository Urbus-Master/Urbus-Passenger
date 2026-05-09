import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/unit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TRUCK MARKER
// ─────────────────────────────────────────────────────────────────────────────

/// Animated map marker representing the active tracked unit.
///
/// Features:
/// - Rotates to match the unit's GPS heading.
/// - Pulsing outer ring when the unit is live (status == active).
/// - Color reflects [UnitStatus] via [AppColors].
/// - Scale-bounce entrance animation on first build.
class TruckMarker extends StatefulWidget {
  final UnitModel unit;

  /// Size of the inner circle in logical pixels.
  final double size;

  const TruckMarker({
    super.key,
    required this.unit,
    this.size = 48.0,
  });

  @override
  State<TruckMarker> createState() => _TruckMarkerState();
}

class _TruckMarkerState extends State<TruckMarker>
    with TickerProviderStateMixin {
  // ── Pulse ring animation ───────────────────────────────────────
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  late final Animation<double> _pulseScale = Tween<double>(
    begin: 1.0,
    end: 1.7,
  ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

  late final Animation<double> _pulseOpacity = Tween<double>(
    begin: 0.55,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

  // ── Entrance scale-bounce ─────────────────────────────────────
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final Animation<double> _entranceScale = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(
    CurvedAnimation(parent: _entranceController, curve: Curves.elasticOut),
  );

  @override
  void initState() {
    super.initState();
    _entranceController.forward();
    if (widget.unit.status.isLive) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(TruckMarker old) {
    super.didUpdateWidget(old);
    // Start/stop pulse when live status changes.
    if (widget.unit.status.isLive && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.unit.status.isLive && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color  = widget.unit.status.color;
    final isLive = widget.unit.status.isLive;
    final size   = widget.size;

    return ScaleTransition(
      scale: _entranceScale,
      child: SizedBox(
        width:  size + 28,
        height: size + 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Pulsing ring ─────────────────────────────────────
            if (isLive)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Transform.scale(
                  scale: _pulseScale.value,
                  child: Container(
                    width:  size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: _pulseOpacity.value),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ),

            // ── White halo (shadow) ──────────────────────────────
            Container(
              width:  size + 6,
              height: size + 6,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),

            // ── Inner circle with rotated truck icon ─────────────
            Transform.rotate(
              // Heading is in degrees — Transform.rotate expects radians.
              angle: _headingRadians,
              child: Container(
                width:  size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.40),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color:  AppColors.background,
                  size:   size * 0.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// GPS heading converted to radians.
  /// Defaults to 0 (pointing up / north) when heading is unavailable.
  double get _headingRadians {
    final deg = widget.unit.heading ?? 0.0;
    return deg * (3.14159265358979 / 180.0);
  }
}
