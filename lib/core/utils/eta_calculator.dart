import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/checkpoint_model.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────
// ETA RESULT
// ─────────────────────────────────────────────

class EtaResult {
  final Duration duration;
  final double distanceKm;
  final DateTime estimatedArrival;

  const EtaResult({
    required this.duration,
    required this.distanceKm,
    required this.estimatedArrival,
  });

  bool get hasArrived => duration.inSeconds <= 0;

  bool get isUrgent =>
      !hasArrived &&
      duration.inMinutes <= AppConstants.etaUrgentThresholdMinutes;

  String get formatted {
    if (hasArrived) return '00:00';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get label {
    if (hasArrived) return 'Llegando';
    if (duration.inMinutes < 1) return 'Menos de 1 min';
    if (duration.inHours >= 1) {
      return 'En ${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    }
    return 'En ${duration.inMinutes} min';
  }

  String get distanceLabel {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}

// ─────────────────────────────────────────────
// ETA CALCULATOR
// ─────────────────────────────────────────────

class EtaCalculator {
  static final List<double> _speedHistory = [];
  static const int _historyLimit = 5;

  /// Resets the speed history to avoid bleeding samples between tests.
  static void resetSmoother() => _speedHistory.clear();

  static EtaResult? calculate({
    required LatLng unitPosition,
    LatLng? userPosition,
    List<CheckpointModel> remainingCheckpoints = const [],
    required double averageSpeedKmh,
  }) {
    if (userPosition == null) return null;

    // Smoothen speed
    _speedHistory.add(averageSpeedKmh);
    if (_speedHistory.length > _historyLimit) _speedHistory.removeAt(0);
    final smoothSpeed = _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;
    final effectiveSpeed = smoothSpeed < 5 ? 5.0 : smoothSpeed; // Min 5km/h

    // Check arrival
    if (hasArrived(unitPosition, userPosition)) {
      return EtaResult(
        duration: Duration.zero,
        distanceKm: distanceKm(unitPosition, userPosition),
        estimatedArrival: DateTime.now(),
      );
    }

    // Calculate total distance through checkpoints
    double totalKm = 0;
    LatLng current = unitPosition;

    for (final cp in remainingCheckpoints) {
      final cpPos = LatLng(cp.latitude, cp.longitude);
      totalKm += distanceKm(current, cpPos);
      current = cpPos;
    }

    totalKm += distanceKm(current, userPosition);

    // Calculate duration (dist / speed)
    final hours = totalKm / effectiveSpeed;
    final duration = Duration(seconds: (hours * 3600).round());

    return EtaResult(
      duration: duration,
      distanceKm: totalKm,
      estimatedArrival: DateTime.now().add(duration),
    );
  }

  // ── Utils ───────────────────────────────────────────────────

  /// Distance between two points in Kilometres using Haversine formula.
  static double distanceKm(LatLng p1, LatLng p2) {
    const r = 6371.0; // Earth radius
    final dLat = _rad(p2.latitude - p1.latitude);
    final dLon = _rad(p2.longitude - p1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(p1.latitude)) *
            math.cos(_rad(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double distanceMetres(LatLng p1, LatLng p2) => distanceKm(p1, p2) * 1000;

  static bool hasArrived(LatLng p1, LatLng p2) =>
      distanceMetres(p1, p2) <= AppConstants.arrivalRadiusMetres;

  static bool hasMovedSignificantly(LatLng p1, LatLng p2) =>
      distanceMetres(p1, p2) >= 10.0; // 10m threshold

  /// Calculates bearing between two points in degrees [0, 360).
  static double bearingDegrees(LatLng p1, LatLng p2) {
    final lat1 = _rad(p1.latitude);
    final lng1 = _rad(p1.longitude);
    final lat2 = _rad(p2.latitude);
    final lng2 = _rad(p2.longitude);

    final dLng = lng2 - lng1;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x);
    return (_deg(bearing) + 360) % 360;
  }

  /// Linear interpolation between two points.
  static LatLng interpolate(LatLng from, LatLng to, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * clampedT,
      from.longitude + (to.longitude - from.longitude) * clampedT,
    );
  }

  static double _rad(double deg) => deg * (math.pi / 180);
  static double _deg(double rad) => rad * (180 / math.pi);
}
