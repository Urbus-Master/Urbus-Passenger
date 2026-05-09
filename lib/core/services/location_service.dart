import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// ── Exceptions ─────────────────────────────────────────────

class LocationException implements Exception {
  final String message;
  final LocationExceptionType type;

  const LocationException(this.message, this.type);

  @override
  String toString() => message;
}

enum LocationExceptionType {
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  timeout,
  unknown,
}

// ── Location state ─────────────────────────────────────────────

enum LocationStatus { initial, loading, ready, error }

class LocationState {
  final LocationStatus status;
  final LatLng? position;
  final double? accuracy;
  final String? errorMessage;

  const LocationState({
    required this.status,
    this.position,
    this.accuracy,
    this.errorMessage,
  });

  const LocationState.initial()
      : status = LocationStatus.initial,
        position = null,
        accuracy = null,
        errorMessage = null;

  const LocationState.loading()
      : status = LocationStatus.loading,
        position = null,
        accuracy = null,
        errorMessage = null;

  LocationState.ready(Position p)
      : status = LocationStatus.ready,
        position = LatLng(p.latitude, p.longitude),
        accuracy = p.accuracy,
        errorMessage = null;

  LocationState.error(String msg)
      : status = LocationStatus.error,
        position = null,
        accuracy = null,
        errorMessage = msg;

  bool get hasError => status == LocationStatus.error;

  LocationState copyWith({
    LocationStatus? status,
    LatLng? position,
    double? accuracy,
    String? errorMessage,
    bool clearError = false,
  }) =>
      LocationState(
        status: status ?? this.status,
        position: position ?? this.position,
        accuracy: accuracy ?? this.accuracy,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}

// ── Location service ─────────────────────────────────────────────

class LocationService {
  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'El GPS está desactivado. Actívalo en la configuración.',
        LocationExceptionType.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Permiso de ubicación bloqueado. Actívalo desde Ajustes de la app.',
        LocationExceptionType.permissionPermanentlyDenied,
      );
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Se necesita tu ubicación para mostrarte el tiempo de llegada.',
          LocationExceptionType.permissionDenied,
        );
      }
    }

    return true;
  }

  Future<LatLng> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw const LocationException(
          'Tiempo agotado al obtener la ubicación.',
          LocationExceptionType.timeout,
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      if (e is LocationException) rethrow;
      throw const LocationException(
        'No se pudo obtener la ubicación.',
        LocationExceptionType.unknown,
      );
    }
  }

  Stream<LatLng> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).map((p) => LatLng(p.latitude, p.longitude));
  }

  bool hasMovedSignificantly(LatLng? oldPos, LatLng newPos, {double thresholdMeters = 10}) {
    if (oldPos == null) return true;
    final distance = Geolocator.distanceBetween(
      oldPos.latitude,
      oldPos.longitude,
      newPos.latitude,
      newPos.longitude,
    );
    return distance >= thresholdMeters;
  }
}

// ── Providers ─────────────────────────────────────────────

final locationServiceProvider = Provider<LocationService>((_) => LocationService());

class LocationNotifier extends Notifier<AsyncValue<LocationState>> {
  @override
  AsyncValue<LocationState> build() {
    _service = ref.watch(locationServiceProvider);
    return const AsyncValue.data(LocationState.initial());
  }

  late final LocationService _service;

  Future<void> initialise() async => refresh();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      await _service.requestPermission();
      final position = await _service.getCurrentPosition();
      state = AsyncValue.data(LocationState.ready(Position(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      )));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, AsyncValue<LocationState>>(
  LocationNotifier.new,
);

final currentPositionProvider = Provider<LatLng?>((ref) {
  return ref.watch(locationProvider).value?.position;
});
