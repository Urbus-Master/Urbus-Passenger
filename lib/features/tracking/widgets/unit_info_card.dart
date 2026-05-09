import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/models/unit_model.dart';
import '../../../core/services/tracking_service.dart';
import '../../../core/utils/formatters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNIT INFO CARD
// ─────────────────────────────────────────────────────────────────────────────

/// Card showing driver avatar, name, rating, unit number, speed and status.
///
/// Consumed inside [BottomSheetCard] under the "Conductor" section.
/// Consumes [activeUnitProvider] — rebuilds only when the unit changes,
/// not on every ETA tick.
class UnitInfoCard extends ConsumerWidget {
  const UnitInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(activeUnitProvider);

    if (unit == null) return const _UnitSkeleton();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _CardContent(unit: unit),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  final UnitModel unit;

  const _CardContent({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.whiteSubtle),
        boxShadow: AppColors.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Avatar + name + status ───────────────────────
          Row(
            children: [
              _DriverAvatar(unit: unit),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.driverName,
                      style: AppTypography.h4.copyWith(letterSpacing: 0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _RatingRow(rating: unit.driverRating),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              _StatusChip(unit: unit),
            ],
          ),

          const SizedBox(height: 20),
          const _Hairline(),
          const SizedBox(height: 20),

          // ── Row 2: Stats Grid ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCell(
                icon: Icons.local_shipping_rounded,
                label: 'UNIDAD',
                value: unit.unitNumber,
              ),
              _StatCell(
                icon: Icons.speed_rounded,
                label: 'VELOCIDAD',
                value: unit.formattedSpeed,
              ),
              _StatCell(
                icon: Icons.history_rounded,
                label: 'ESTADO',
                value: 'En ruta',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRIVER AVATAR
// ─────────────────────────────────────────────────────────────────────────────

class _DriverAvatar extends StatelessWidget {
  final UnitModel unit;

  const _DriverAvatar({required this.unit});

  @override
  Widget build(BuildContext context) {
    const size = 52.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Photo or initials fallback.
        Container(
          width:  size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderActive, width: 1.5),
          ),
          child: unit.driverAvatar != null
              ? ClipOval(
                  child: Image.network(
                    unit.driverAvatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _InitialsFallback(unit: unit),
                  ),
                )
              : _InitialsFallback(unit: unit),
        ),

        // Live dot badge.
        if (unit.status.isLive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width:  14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceLight, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INITIALS FALLBACK
// ─────────────────────────────────────────────────────────────────────────────

class _InitialsFallback extends StatelessWidget {
  final UnitModel unit;

  const _InitialsFallback({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        unit.driverInitials,
        style: AppTypography.h4.copyWith(
          color: AppColors.accent,
          height: 1.0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RATING ROW
// ─────────────────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final double rating;

  const _RatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_rounded,
          size: 14,
          color: AppColors.warning,
        ),
        const SizedBox(width: 3),
        Text(
          Formatters.rating(rating),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '/ 5.0',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final UnitModel unit;

  const _StatusChip({required this.unit});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: unit.status.backgroundColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: unit.status.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(unit.status.icon, size: 11, color: unit.status.color),
          const SizedBox(width: 4),
          Text(
            unit.status.label,
            style: AppTypography.bodySmall.copyWith(
              color: unit.status.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CELL
// ─────────────────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.label.copyWith(fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.bodyBold.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HAIRLINE DIVIDER
// ─────────────────────────────────────────────────────────────────────────────

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.border);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON (loading state)
// ─────────────────────────────────────────────────────────────────────────────

class _UnitSkeleton extends StatefulWidget {
  const _UnitSkeleton();

  @override
  State<_UnitSkeleton> createState() => _UnitSkeletonState();
}

class _UnitSkeletonState extends State<_UnitSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.3,
    end: 0.7,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar skeleton.
                  _SkeletonBox(width: 52, height: 52, radius: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: 120, height: 14, radius: 6),
                        const SizedBox(height: 8),
                        _SkeletonBox(width: 70, height: 10, radius: 4),
                      ],
                    ),
                  ),
                  _SkeletonBox(width: 72, height: 26, radius: 50),
                ],
              ),
              const SizedBox(height: 14),
              _SkeletonBox(width: double.infinity, height: 1, radius: 0),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SkeletonBox(width: 50, height: 9, radius: 4),
                          const SizedBox(height: 5),
                          _SkeletonBox(width: 60, height: 13, radius: 4),
                        ],
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmer,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
