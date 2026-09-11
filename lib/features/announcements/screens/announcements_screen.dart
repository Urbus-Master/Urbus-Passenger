import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/announcement_model.dart';
import '../../../../core/services/base_client.dart';
import '../widgets/announcement_banner.dart';
import '../../../../shared/widgets/skeleton.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _mockAnnouncements = [
  AnnouncementModel(
    id: 1,
    title: 'Modificación temporal de la Ruta 4',
    body: 'Debido a obras de infraestructura en la Calle 50 con Carrera 43, '
        'la Ruta 4 operará por vías alternas esta semana. '
        'El recorrido tomará aproximadamente 8 minutos adicionales. '
        'Agradecemos tu comprensión.',
    source: 'Alcaldía de Medellín',
    date: DateTime.now().subtract(const Duration(hours: 2)),
    isImportant: true,
    iconType: AnnouncementIconType.warning,
  ),
  AnnouncementModel(
    id: 2,
    title: 'Servicio especial Día sin Carro',
    body: 'El próximo jueves con motivo del Día sin Carro, '
        'el servicio de recolección operará con horario extendido '
        'desde las 5:00 AM hasta las 10:00 PM en todas las rutas.',
    source: 'Empresas Varias de Medellín',
    date: DateTime.now().subtract(const Duration(hours: 6)),
    isImportant: true,
    iconType: AnnouncementIconType.schedule,
  ),
  AnnouncementModel(
    id: 3,
    title: 'Ruta 2 restaurada con normalidad',
    body: 'Informamos que la Ruta 2 retomó su recorrido habitual '
        'luego de la emergencia vial del martes. '
        'El servicio opera con total normalidad.',
    source: 'Urbus',
    date: DateTime.now().subtract(const Duration(days: 1)),
    isImportant: false,
    iconType: AnnouncementIconType.success,
  ),
  AnnouncementModel(
    id: 4,
    title: 'Mantenimiento programado de unidades',
    body: 'Los días sábados entre 6:00 AM y 8:00 AM las unidades '
        'de la Ruta 1 estarán en mantenimiento preventivo. '
        'Durante este período el servicio operará con frecuencia reducida.',
    source: 'Empresas Varias de Medellín',
    date: DateTime.now().subtract(const Duration(days: 2)),
    isImportant: false,
    iconType: AnnouncementIconType.info,
  ),
  AnnouncementModel(
    id: 5,
    title: 'Nueva parada en el barrio Laureles',
    body: 'A partir del 1 de mayo se habilitará una nueva parada '
        'en la Circular 76 con Carrera 80. '
        'Esta parada beneficiará a más de 500 usuarios del sector.',
    source: 'Alcaldía de Medellín',
    date: DateTime.now().subtract(const Duration(days: 3)),
    isImportant: false,
    iconType: AnnouncementIconType.info,
  ),
  AnnouncementModel(
    id: 6,
    title: 'Alerta: Paro de transporte',
    body: 'Se informa a los ciudadanos que mañana podría presentarse '
        'una interrupción en el servicio de recolección debido a '
        'un cese de actividades programado. Manténgase informado.',
    source: 'Alcaldía de Medellín',
    date: DateTime.now().subtract(const Duration(days: 4)),
    isImportant: false,
    iconType: AnnouncementIconType.alert,
  ),
];

// State
enum _FilterType { all, important, info, warning }

class _AnnouncementsState {
  const _AnnouncementsState({
    this.announcements = const [],
    this.filter = _FilterType.all,
    this.isLoading = false,
    this.error,
    this.isMockData = false,
  });

  final List<AnnouncementModel> announcements;
  final _FilterType filter;
  final bool isLoading;
  final String? error;

  /// True when [announcements] came from local fallback data instead of
  /// the backend — surfaced to the UI instead of presented as real.
  final bool isMockData;

  List<AnnouncementModel> get filtered => switch (filter) {
    _FilterType.all       => announcements.where((a) => a.isActive).toList(),
    _FilterType.important => announcements.where((a) => a.isImportant && a.isActive).toList(),
    _FilterType.info      => announcements.where((a) =>
        a.iconType == AnnouncementIconType.info ||
        a.iconType == AnnouncementIconType.success).toList(),
    _FilterType.warning   => announcements.where((a) =>
        a.iconType == AnnouncementIconType.warning ||
        a.iconType == AnnouncementIconType.alert).toList(),
  };

  _AnnouncementsState copyWith({
    List<AnnouncementModel>? announcements,
    _FilterType? filter,
    bool? isLoading,
    String? error,
    bool? isMockData,
  }) => _AnnouncementsState(
    announcements: announcements ?? this.announcements,
    filter:        filter        ?? this.filter,
    isLoading:     isLoading     ?? this.isLoading,
    error:         error,
    isMockData:    isMockData    ?? this.isMockData,
  );
}

class _AnnouncementsNotifier extends Notifier<_AnnouncementsState> {
  late final Dio _dio;

  @override
  _AnnouncementsState build() {
    _dio = ref.read(dioProvider);
    _load();
    return const _AnnouncementsState();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _dio.get(ApiConstants.notifications);
      final data = response.data as List<dynamic>;
      final announcements = data
          .map((json) =>
              AnnouncementModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        announcements: announcements,
        isLoading: false,
        isMockData: false,
      );
    } catch (_) {
      state = state.copyWith(
        announcements: _mockAnnouncements,
        isLoading: false,
        isMockData: true,
      );
    }
  }

  void setFilter(_FilterType filter) =>
      state = state.copyWith(filter: filter);

  Future<void> refresh() => _load();
}

final _announcementsProvider = NotifierProvider<
    _AnnouncementsNotifier, _AnnouncementsState>(
  _AnnouncementsNotifier.new,
);

// ── Screen ────────────────────────────────────────────────────────────────────

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_announcementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              onRefresh: () =>
                  ref.read(_announcementsProvider.notifier).refresh(),
            ),
            _FilterRow(
              selected: state.filter,
              onSelected: (f) =>
                  ref.read(_announcementsProvider.notifier).setFilter(f),
            ),
            Expanded(
              child: _Body(
                state: state,
                onRefresh: () =>
                    ref.read(_announcementsProvider.notifier).refresh(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Avisos', style: AppTypography.h1),
              Text(
                'Información municipal',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          Semantics(
            label: 'Actualizar avisos',
            button: true,
            child: IconButton(
              onPressed: onRefresh,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Actualizar',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.onSelected,
  });

  final _FilterType selected;
  final ValueChanged<_FilterType> onSelected;

  static const _filters = [
    (_FilterType.all,       'Todos',      null),
    (_FilterType.important, 'Importantes', Icons.push_pin_rounded),
    (_FilterType.warning,   'Alertas',     Icons.warning_amber_rounded),
    (_FilterType.info,      'Info',        Icons.info_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (type, label, icon) = _filters[i];
          final isSelected = selected == type;

          return Semantics(
            label: label,
            selected: isSelected,
            button: true,
            child: GestureDetector(
              onTap: () => onSelected(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentMedium
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.onRefresh});

  final _AnnouncementsState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const _LoadingState();
    if (state.error != null) return _ErrorState(message: state.error!);
    if (state.filtered.isEmpty) return const _EmptyState();

    final featured = state.filtered
        .where((a) => a.isImportant)
        .toList();
    final regular = state.filtered
        .where((a) => !a.isImportant)
        .toList();

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (state.isMockData) ...[
            const _DemoModeBanner(),
            const SizedBox(height: 12),
          ],
          // Featured section
          if (featured.isNotEmpty) ...[
            _SectionTitle(
              title: 'DESTACADOS',
              count: featured.length,
            ),
            const SizedBox(height: 12),
            ...featured.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnnouncementBanner(
                  announcement: a,
                  isFeatured: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Regular section
          if (regular.isNotEmpty) ...[
            _SectionTitle(
              title: 'RECIENTES',
              count: regular.length,
            ),
            const SizedBox(height: 12),
            ...regular.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnnouncementBanner(
                  announcement: a,
                  isFeatured: false,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Demo mode banner ────────────────────────────────────────────────────────

class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Modo demostración — no se pudo conectar al servidor, '
              'mostrando avisos de ejemplo.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTypography.label),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            '$count',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textHint,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loading state ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.whiteSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Skeleton(height: 48, width: 48, borderRadius: 14),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(height: 18, width: 140),
                  const SizedBox(height: 8),
                  const Skeleton(height: 14, width: 100),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Skeleton(height: 14, width: double.infinity),
          const SizedBox(height: 8),
          const Skeleton(height: 14, width: double.infinity),
          const SizedBox(height: 8),
          const Skeleton(height: 14, width: 200),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 24),
            Text(
              'Sin avisos disponibles',
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Los avisos municipales aparecerán aquí cuando estén disponibles.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar avisos',
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
