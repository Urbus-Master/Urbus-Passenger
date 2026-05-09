import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/history_controller.dart';
import '../widgets/visit_card.dart';
import '../../../shared/widgets/skeleton.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Triggers pagination when the user reaches 80% of the list.
  void _onScroll() {
    final threshold = _scrollController.position.maxScrollExtent * 0.8;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(historyControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyControllerProvider);
    final stats = ref.watch(historyStatsProvider);
    final filteredVisits = ref.watch(filteredVisitsProvider);
    final activeFilter = ref.watch(activeHistoryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text('Historial de visitas', style: AppTypography.h2),
              ),
            ),

            // ── Stats card ────────────────────────────────────
            SliverToBoxAdapter(
              child: _StatsCard(stats: stats),
            ),

            // ── Filter chips ──────────────────────────────────
            SliverToBoxAdapter(
              child: _FilterChips(activeFilter: activeFilter),
            ),

            // ── Section title ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    Text('Visitas recientes', style: AppTypography.h3),
                    const Spacer(),
                    if (filteredVisits.isNotEmpty)
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
                          Formatters.badgeCount(filteredVisits.length),
                          style: AppTypography.label.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────
            if (state.isLoading)
              _ShimmerList()
            else if (state.hasError && filteredVisits.isEmpty)
              SliverFillRemaining(
                child: _ErrorState(
                  message: state.errorMessage!,
                  onRetry: () =>
                      ref.read(historyControllerProvider.notifier).loadInitial(),
                ),
              )
            else if (state.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(activeFilter: activeFilter),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverList.separated(
                  itemCount: filteredVisits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => VisitCard(
                    visit: filteredVisits[index],
                  ),
                ),
              ),

              // ── Load more indicator ───────────────────────
              SliverToBoxAdapter(
                child: _LoadMoreIndicator(
                  isLoading: state.isLoadingMore,
                  hasReachedEnd: state.hasReachedEnd,
                  itemCount: filteredVisits.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATS CARD
// ─────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final HistoryStats stats;

  const _StatsCard({required this.stats});

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
      child: Row(
        children: [
          _StatBlock(
            value: '${stats.totalThisMonth}',
            label: 'Visitas',
            sublabel: 'Este mes',
            valueColor: AppColors.accent,
            icon: Icons.calendar_today_rounded,
          ),
          _VerticalDivider(),
          _StatBlock(
            value: stats.avgWaitLabel,
            label: 'Minutos',
            sublabel: 'Espera prom.',
            valueColor: AppColors.textPrimary,
            icon: Icons.timer_rounded,
          ),
          _VerticalDivider(),
          _StatBlock(
            value: stats.onTimeLabel,
            label: 'Puntualidad',
            sublabel: 'A tiempo',
            valueColor: AppColors.success,
            icon: Icons.verified_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final Color valueColor;
  final IconData icon;

  const _StatBlock({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h2.copyWith(color: valueColor, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: AppTypography.label.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─────────────────────────────────────────────
// FILTER CHIPS
// ─────────────────────────────────────────────

class _FilterChips extends ConsumerWidget {
  final HistoryFilter activeFilter;

  const _FilterChips({required this.activeFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        physics: const BouncingScrollPhysics(),
        children: HistoryFilter.values.map((filter) {
          final isActive = filter == activeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => ref
                  .read(historyControllerProvider.notifier)
                  .applyFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? AppColors.accent : AppColors.border,
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    filter.label,
                    style: AppTypography.buttonSmall.copyWith(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LOAD MORE INDICATOR
// ─────────────────────────────────────────────

class _LoadMoreIndicator extends StatelessWidget {
  final bool isLoading;
  final bool hasReachedEnd;
  final int itemCount;

  const _LoadMoreIndicator({
    required this.isLoading,
    required this.hasReachedEnd,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ),
      );
    }

    if (hasReachedEnd && itemCount > 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
        child: Center(
          child: Text(
            '— Fin del historial —',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}

// ─────────────────────────────────────────────
// SHIMMER LOADING
// ─────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.whiteSubtle),
      ),
      child: Row(
        children: [
          const Skeleton(height: 54, width: 54, borderRadius: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 18, width: 80),
                const SizedBox(height: 8),
                const Skeleton(height: 14, width: 150),
                const SizedBox(height: 6),
                const Skeleton(height: 14, width: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final HistoryFilter activeFilter;

  const _EmptyState({required this.activeFilter});

  String get _message => switch (activeFilter) {
        HistoryFilter.all => 'Las visitas del servicio\naparecerán aquí',
        HistoryFilter.thisMonth => 'No hay visitas este mes',
        HistoryFilter.lastMonth => 'No hay visitas el mes anterior',
        HistoryFilter.onTime => 'No hay visitas a tiempo registradas',
        HistoryFilter.delayed => 'No hay visitas con retraso registradas',
      };

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
              child: Icon(
                Icons.storage_rounded,
                size: 32,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin visitas registradas',
              style: AppTypography.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _message,
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

// ─────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
