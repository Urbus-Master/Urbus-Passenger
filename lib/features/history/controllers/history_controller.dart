import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/models/visit_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth_service.dart';

// ─────────────────────────────────────────────
// FILTER TYPE
// ─────────────────────────────────────────────

enum HistoryFilter {
  all,
  thisMonth,
  lastMonth,
  onTime,
  delayed,
}

extension HistoryFilterX on HistoryFilter {
  String get label => switch (this) {
        HistoryFilter.all => 'Todos',
        HistoryFilter.thisMonth => 'Este mes',
        HistoryFilter.lastMonth => 'Último mes',
        HistoryFilter.onTime => 'A tiempo',
        HistoryFilter.delayed => 'Con retraso',
      };
}

// ─────────────────────────────────────────────
// HISTORY STATS
// ─────────────────────────────────────────────

class HistoryStats {
  final int totalThisMonth;
  final double avgWaitMinutes;
  final double onTimePercentage;

  const HistoryStats({
    this.totalThisMonth = 0,
    this.avgWaitMinutes = 0,
    this.onTimePercentage = 0,
  });

  factory HistoryStats.fromVisits(List<VisitModel> visits) {
    if (visits.isEmpty) return const HistoryStats();

    final now = DateTime.now();

    // FIX: `date` es una propiedad derivada de `arrivedAt` en el modelo nuevo.
    // Se reemplaza `v.date` por `v.arrivedAt` en todas las comparaciones.
    final thisMonth = visits.where(
      (v) =>
          v.arrivedAt.month == now.month && v.arrivedAt.year == now.year,
    );

    final onTimeCount = visits.where((v) => v.wasOnTime).length;
    final totalDelay = visits.fold<int>(
      0,
      (sum, v) => sum + (v.delayMinutes > 0 ? v.delayMinutes : 0),
    );

    return HistoryStats(
      totalThisMonth: thisMonth.length,
      avgWaitMinutes: totalDelay / visits.length,
      onTimePercentage: (onTimeCount / visits.length) * 100,
    );
  }

  String get avgWaitLabel => '${avgWaitMinutes.round()} min';
  String get onTimeLabel => '${onTimePercentage.round()}%';
}

// ─────────────────────────────────────────────
// HISTORY STATE
// ─────────────────────────────────────────────

class HistoryState {
  final List<VisitModel> visits;
  final List<VisitModel> filteredVisits;
  final HistoryFilter activeFilter;
  final HistoryStats stats;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final int page;
  final String? errorMessage;

  const HistoryState({
    this.visits = const [],
    this.filteredVisits = const [],
    this.activeFilter = HistoryFilter.all,
    this.stats = const HistoryStats(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.page = 0,
    this.errorMessage,
  });

  const HistoryState.initial() : this(isLoading: true);

  bool get hasError => errorMessage != null;
  bool get isEmpty => filteredVisits.isEmpty && !isLoading;
  bool get hasVisits => filteredVisits.isNotEmpty;

  HistoryState copyWith({
    List<VisitModel>? visits,
    List<VisitModel>? filteredVisits,
    HistoryFilter? activeFilter,
    HistoryStats? stats,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    int? page,
    String? errorMessage,
    bool clearError = false,
  }) =>
      HistoryState(
        visits: visits ?? this.visits,
        filteredVisits: filteredVisits ?? this.filteredVisits,
        activeFilter: activeFilter ?? this.activeFilter,
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
        page: page ?? this.page,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}

// ─────────────────────────────────────────────
// HISTORY CONTROLLER
// ─────────────────────────────────────────────

class HistoryController extends Notifier<HistoryState> {
  static const int _pageSize = 20;

  late final Dio _dio;

  @override
  HistoryState build() {
    _dio = ref.read(dioProvider);
    Future.microtask(loadInitial);
    return const HistoryState.initial();
  }

  // ── Load initial page ────────────────────────────────────────

  Future<void> loadInitial() async {
    state = const HistoryState.initial();

    try {
      final visits = await _fetchPage(0);
      final stats = HistoryStats.fromVisits(visits);

      state = HistoryState(
        visits: visits,
        filteredVisits: visits,
        stats: stats,
        hasReachedEnd: visits.length < _pageSize,
        page: 0,
      );
    } catch (e) {
      final mock = _mockVisits();
      state = HistoryState(
        visits: mock,
        filteredVisits: mock,
        stats: HistoryStats.fromVisits(mock),
        hasReachedEnd: true,
        errorMessage: _mapError(e),
      );
    }
  }

  // ── Pagination ───────────────────────────────────────────────

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || state.hasReachedEnd) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.page + 1;
      final newVisits = await _fetchPage(nextPage);
      final allVisits = [...state.visits, ...newVisits];

      state = state.copyWith(
        visits: allVisits,
        filteredVisits: _applyFilter(allVisits, state.activeFilter),
        stats: HistoryStats.fromVisits(allVisits),
        isLoadingMore: false,
        hasReachedEnd: newVisits.length < _pageSize,
        page: nextPage,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _mapError(e),
      );
    }
  }

  // ── Filtering ────────────────────────────────────────────────

  void applyFilter(HistoryFilter filter) {
    state = state.copyWith(
      activeFilter: filter,
      filteredVisits: _applyFilter(state.visits, filter),
    );
  }

  List<VisitModel> _applyFilter(
    List<VisitModel> visits,
    HistoryFilter filter,
  ) {
    final now = DateTime.now();

    return switch (filter) {
      HistoryFilter.all => visits,

      // FIX: reemplazado `v.date` por `v.arrivedAt` en todos los filtros.
      // El modelo viejo tenía un campo `date: DateTime` separado.
      // El modelo nuevo tiene `arrivedAt: DateTime` y expone `date`
      // como getter derivado — pero para filtrar usamos `arrivedAt`
      // directamente para evitar crear objetos DateTime innecesarios.
      HistoryFilter.thisMonth => visits
          .where(
            (v) =>
                v.arrivedAt.month == now.month &&
                v.arrivedAt.year == now.year,
          )
          .toList(),

      HistoryFilter.lastMonth => () {
          // FIX: `DateTime(now.year, now.month - 1)` falla en enero
          // (month=0 no existe). Se usa `DateTime(now.year, now.month - 1, 1)`
          // que Dart normaliza correctamente a diciembre del año anterior.
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          return visits
              .where(
                (v) =>
                    v.arrivedAt.month == lastMonth.month &&
                    v.arrivedAt.year == lastMonth.year,
              )
              .toList();
        }(),

      HistoryFilter.onTime => visits.where((v) => v.wasOnTime).toList(),
      HistoryFilter.delayed => visits.where((v) => !v.wasOnTime).toList(),
    };
  }

  // ── API call ─────────────────────────────────────────────────

  Future<List<VisitModel>> _fetchPage(int page) async {
    final response = await _dio.get(
      ApiConstants.visitsEndpoint,
      queryParameters: {
        'page': page,
        'limit': _pageSize,
      },
    );

    final data = response.data as List<dynamic>;
    return data
        .map((json) => VisitModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ── Error mapping ────────────────────────────────────────────

  String _mapError(Object e) {
    if (e is DioException) {
      return switch (e.type) {
        DioExceptionType.connectionError => 'Sin conexión a internet.',
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout =>
          'Tiempo de conexión agotado.',
        DioExceptionType.badResponse when e.response?.statusCode == 401 =>
          'Sesión expirada. Inicia sesión nuevamente.',
        _ => 'Error del servidor. Intenta más tarde.',
      };
    }
    return 'No se pudo cargar el historial.';
  }

  // ── Mock data ────────────────────────────────────────────────

  List<VisitModel> _mockVisits() {
    final now = DateTime.now();

    // FIX: constructor actualizado al modelo nuevo.
    // Campos eliminados: `date` (derivado), `time` (String suelto).
    // Campos nuevos: `arrivedAt` (DateTime completo), `checkpointId` (int),
    // `unitId` (int), `id` (int).
    // Se construye `arrivedAt` con fecha + hora exacta en vez de
    // date + time como strings separados.
    return [
      VisitModel(
        id: 1,
        arrivedAt: DateTime(now.year, now.month, now.day - 1, 8, 15),
        unitNumber: '204',
        unitId: 204,
        wasOnTime: true,
        delayMinutes: 0,
        checkpointName: 'Estadio Atanasio',
        checkpointId: 3,
      ),
      VisitModel(
        id: 2,
        arrivedAt: DateTime(now.year, now.month, now.day - 3, 8, 22),
        unitNumber: '204',
        unitId: 204,
        wasOnTime: false,
        delayMinutes: 7,
        checkpointName: 'Parque Envigado',
        checkpointId: 4,
      ),
      VisitModel(
        id: 3,
        arrivedAt: DateTime(now.year, now.month, now.day - 5, 7, 58),
        unitNumber: '107',
        unitId: 107,
        wasOnTime: true,
        delayMinutes: 0,
        checkpointName: 'Hospital General',
        checkpointId: 2,
      ),
      VisitModel(
        id: 4,
        arrivedAt: DateTime(now.year, now.month, now.day - 8, 9, 10),
        unitNumber: '204',
        unitId: 204,
        wasOnTime: false,
        delayMinutes: 12,
        checkpointName: 'Plaza Sabaneta',
        checkpointId: 5,
      ),
      VisitModel(
        id: 5,
        arrivedAt: DateTime(now.year, now.month, now.day - 10, 8, 5),
        unitNumber: '312',
        unitId: 312,
        wasOnTime: true,
        delayMinutes: 0,
        checkpointName: 'Parque Berrío',
        checkpointId: 1,
      ),
      VisitModel(
        id: 6,
        arrivedAt: DateTime(now.year, now.month - 1, 20, 8, 30),
        unitNumber: '204',
        unitId: 204,
        wasOnTime: true,
        delayMinutes: 0,
        checkpointName: 'Estadio Atanasio',
        checkpointId: 3,
      ),
      VisitModel(
        id: 7,
        arrivedAt: DateTime(now.year, now.month - 1, 15, 8, 45),
        unitNumber: '107',
        unitId: 107,
        wasOnTime: false,
        delayMinutes: 5,
        checkpointName: 'Hospital General',
        checkpointId: 2,
      ),
      VisitModel(
        id: 8,
        arrivedAt: DateTime(now.year, now.month - 1, 8, 7, 50),
        unitNumber: '204',
        unitId: 204,
        wasOnTime: true,
        delayMinutes: 0,
        checkpointName: 'Parque Envigado',
        checkpointId: 4,
      ),
      VisitModel(
        id: 9,
        arrivedAt: DateTime(now.year, now.month - 1, 3, 9, 0),
        unitNumber: '312',
        unitId: 312,
        wasOnTime: true,
        delayMinutes: 0,
        checkpointName: 'Plaza Sabaneta',
        checkpointId: 5,
      ),
      VisitModel(
        id: 10,
        arrivedAt: DateTime(now.year, now.month - 2, 28, 8, 20),
        unitNumber: '204',
        unitId: 204,
        wasOnTime: false,
        delayMinutes: 18,
        checkpointName: 'Parque Berrío',
        checkpointId: 1,
      ),
    ];
  }
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryState>(
  HistoryController.new,
);

final filteredVisitsProvider = Provider<List<VisitModel>>(
  (ref) => ref.watch(historyControllerProvider).filteredVisits,
);

final historyStatsProvider = Provider<HistoryStats>(
  (ref) => ref.watch(historyControllerProvider).stats,
);

final activeHistoryFilterProvider = Provider<HistoryFilter>(
  (ref) => ref.watch(historyControllerProvider).activeFilter,
);
