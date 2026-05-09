import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/models/announcement_model.dart';

/// Renders a single announcement card in two visual variants:
///
/// - [isFeatured] = true  → gradient border card, pinned at top of list
/// - [isFeatured] = false → standard surface card in the regular list
///
/// Tapping expands the full body in a bottom modal sheet.
class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({
    super.key,
    required this.announcement,
    this.isFeatured = false,
  });

  final AnnouncementModel announcement;
  final bool isFeatured;

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  bool _isExpanded = false;

  AnnouncementModel get a => widget.announcement;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${a.iconType.label}: ${a.title}',
      button: true,
      child: GestureDetector(
        onTap: () => _showDetailSheet(context),
        child: widget.isFeatured ? _FeaturedCard(
          announcement: a,
          isExpanded: _isExpanded,
          onToggleExpand: _toggleExpand,
        ) : _RegularCard(
          announcement: a,
          isExpanded: _isExpanded,
          onToggleExpand: _toggleExpand,
        ),
      ),
    );
  }

  void _toggleExpand() => setState(() => _isExpanded = !_isExpanded);

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AnnouncementDetailSheet(announcement: a),
    );
  }
}

// ── Featured card ─────────────────────────────────────────────────────────────

/// Highlighted card with gradient border — used for important announcements.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.announcement,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  final AnnouncementModel announcement;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final a = announcement;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            a.iconType.color.withValues(alpha: 0.15),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: a.iconType.color.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon + label + date ────────────────────────────────
          Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: a.iconType.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  a.iconType.icon,
                  color: a.iconType.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Type label
              Expanded(
                child: Text(
                  a.iconType.label.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: a.iconType.color,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              // Date badge
              _DateBadge(date: a.relativeTime),
            ],
          ),
          const SizedBox(height: 14),

          // ── Title ────────────────────────────────────────────────────────
          Text(a.title, style: AppTypography.h3),
          const SizedBox(height: 8),

          // ── Body (collapsible) ────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              a.body,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              a.body,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),

          // ── Footer: source + expand button ───────────────────────────────
          const SizedBox(height: 12),
          Row(
            children: [
              // Source tag
              _SourceTag(source: a.source),
              const Spacer(),

              // Expand / collapse — only shown when body is long
              if (a.isLongBody)
                GestureDetector(
                  onTap: onToggleExpand,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded ? 'Ver menos' : 'Ver más',
                        style: AppTypography.buttonSmall,
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.accent,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Regular card ──────────────────────────────────────────────────────────────

/// Standard surface card — used for non-featured announcements.
class _RegularCard extends StatelessWidget {
  const _RegularCard({
    required this.announcement,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  final AnnouncementModel announcement;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final a = announcement;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row ──────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: a.iconType.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  a.iconType.icon,
                  color: a.iconType.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Title + source
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: AppTypography.bodyBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _SourceTag(source: a.source),
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          a.relativeTime,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Body (collapsible) ────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              a.body,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              a.body,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),

          // ── Expand button ─────────────────────────────────────────────────
          if (a.isLongBody) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onToggleExpand,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isExpanded ? 'Ver menos ↑' : 'Ver más ↓',
                    style: AppTypography.buttonSmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

class _AnnouncementDetailSheet extends StatelessWidget {
  const _AnnouncementDetailSheet({required this.announcement});

  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    final a = announcement;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          // Icon + meta row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: a.iconType.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  a.iconType.icon,
                  color: a.iconType.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.iconType.label.toUpperCase(),
                      style: AppTypography.label.copyWith(
                        color: a.iconType.color,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _SourceTag(source: a.source),
                        const SizedBox(width: 8),
                        Text(
                          '· ${a.relativeTime}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          Text(a.title, style: AppTypography.h2),
          const SizedBox(height: 12),

          // Full body
          Text(
            a.body,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),

          // Route tag — if linked to a specific route
          if (a.routeId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ruta ${a.routeId}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        date,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textHint,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Text(
      source,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textHint,
        fontSize: 10,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
