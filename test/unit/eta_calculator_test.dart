import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:urbus/core/utils/eta_calculator.dart';
import 'package:urbus/core/constants/app_constants.dart';
import 'package:urbus/core/models/checkpoint_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Medellín downtown — used as a stable reference point for all tests.
const _medellin = LatLng(6.2442, -75.5812);

/// ~1.0 km north of [_medellin].
const _oneKmNorth = LatLng(6.2532, -75.5812);

/// ~10.0 km north of [_medellin].
const _tenKmNorth = LatLng(6.3342, -75.5812);

/// A point within [AppConstants.arrivalRadiusMetres] of [_medellin].
/// 0.001° lat ≈ 111 m → well inside the 150 m radius.
const _veryClose = LatLng(6.2442 + 0.0010, -75.5812);

/// Builds a dummy [CheckpointModel] for use in routing tests.
CheckpointModel _cp({
  required int id,
  required double lat,
  required double lng,
  CheckpointStatus status = CheckpointStatus.upcoming,
}) {
  return CheckpointModel(
    id: id.toString(),
    name: 'CP $id',
    address: 'Address $id',
    latitude: lat,
    longitude: lng,
    order: id,
    estimatedTime: DateTime.now().add(Duration(minutes: id * 5)),
    status: status,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // Reset the internal speed smoother between every test so samples from one
  // test cannot bleed into another.
  setUp(EtaCalculator.resetSmoother);

  // ──────────────────────────────────────────────────────────────────────────
  group('EtaCalculator.calculate', () {
    // ── Null / unavailable position ───────────────────────────────────────

    test('returns null when userPosition is null', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: null,
        averageSpeedKmh: 30,
      );

      expect(result, isNull);
    });

    // ── Arrival detection ────────────────────────────────────────────────

    test('returns hasArrived=true when unit is within arrival radius', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _veryClose,
        averageSpeedKmh: 30,
      );

      expect(result, isNotNull);
      expect(result!.hasArrived, isTrue);
      expect(result.duration, equals(Duration.zero));
      expect(result.distanceKm, lessThanOrEqualTo(AppConstants.arrivalRadiusMetres / 1000));
    });

    test('returns hasArrived=false when unit is beyond arrival radius', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _oneKmNorth,
        averageSpeedKmh: 30,
      );

      expect(result, isNotNull);
      expect(result!.hasArrived, isFalse);
    });

    // ── Duration calculation ─────────────────────────────────────────────

    test('duration is positive for a non-zero distance', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _oneKmNorth,
        averageSpeedKmh: 30,
      );

      expect(result!.duration.inSeconds, greaterThan(0));
    });

    test('higher speed produces shorter ETA for the same distance', () {
      final slow = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        averageSpeedKmh: 10,
      );
      EtaCalculator.resetSmoother();

      final fast = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        averageSpeedKmh: 60,
      );

      expect(slow!.duration.inSeconds, greaterThan(fast!.duration.inSeconds));
    });

    test('ETA is reasonable for ~1 km at 30 km/h (≈ 2 min)', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _oneKmNorth,
        averageSpeedKmh: 30,
      );

      // 1 km ÷ 30 km/h = 0.033 h = 2 min = 120 s
      // Haversine gives ~1.0 km, allow ±30 s tolerance.
      expect(result!.duration.inSeconds, closeTo(120, 30));
    });

    // ── estimatedArrival ─────────────────────────────────────────────────

    test('estimatedArrival is in the future', () {
      final before = DateTime.now();
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        averageSpeedKmh: 30,
      );
      final after = DateTime.now();

      expect(result!.estimatedArrival.isAfter(before), isTrue);
      expect(
        result.estimatedArrival
            .isBefore(after.add(const Duration(hours: 2))),
        isTrue,
      );
    });

    test('estimatedArrival equals now when hasArrived is true', () {
      final before = DateTime.now();
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _veryClose,
        averageSpeedKmh: 30,
      );
      final after = DateTime.now();

      // estimatedArrival should be approximately DateTime.now().
      expect(result!.estimatedArrival.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(result.estimatedArrival.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    // ── distanceKm ────────────────────────────────────────────────────────

    test('distanceKm is positive and reasonable for ~1 km route', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _oneKmNorth,
        averageSpeedKmh: 30,
      );

      // Haversine between these two points is ≈ 1.00 km ± 5%.
      expect(result!.distanceKm, closeTo(1.0, 0.1));
    });

    // ── Checkpoint routing ────────────────────────────────────────────────

    test('routing through checkpoints produces a longer route than direct', () {
      // A checkpoint that is south — detour from the direct northward path.
      final detourCp = _cp(
        id: 1,
        lat: _medellin.latitude - 0.05, // ~5.5 km south
        lng: _medellin.longitude,
      );

      final direct = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        averageSpeedKmh: 30,
      );
      EtaCalculator.resetSmoother();

      final withDetour = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        remainingCheckpoints: [detourCp],
        averageSpeedKmh: 30,
      );

      expect(withDetour!.distanceKm, greaterThan(direct!.distanceKm));
      expect(withDetour.duration.inSeconds, greaterThan(direct.duration.inSeconds));
    });

    test('two intermediate checkpoints further increase total distance', () {
      final cp1 = _cp(id: 1, lat: _medellin.latitude - 0.03, lng: _medellin.longitude);
      final cp2 = _cp(id: 2, lat: _medellin.latitude - 0.06, lng: _medellin.longitude);

      final oneStop = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        remainingCheckpoints: [cp1],
        averageSpeedKmh: 30,
      );
      EtaCalculator.resetSmoother();

      final twoStops = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        remainingCheckpoints: [cp1, cp2],
        averageSpeedKmh: 30,
      );

      expect(twoStops!.distanceKm, greaterThan(oneStop!.distanceKm));
    });

    test('empty checkpoints list behaves the same as no checkpoints', () {
      final noList = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        averageSpeedKmh: 30,
      );
      EtaCalculator.resetSmoother();

      final emptyList = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        remainingCheckpoints: [],
        averageSpeedKmh: 30,
      );

      expect(emptyList!.distanceKm, closeTo(noList!.distanceKm, 0.001));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('EtaResult', () {
    test('isUrgent is true when duration is within urgent threshold', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _oneKmNorth, // ≈ 2 min at 30 km/h
        averageSpeedKmh: 30,
      );

      // 2 min < etaUrgentThresholdMinutes (5) → should be urgent.
      expect(result!.isUrgent, isTrue);
    });

    test('isUrgent is false when duration exceeds urgent threshold', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth, // ≈ 20 min at 30 km/h
        averageSpeedKmh: 30,
      );

      expect(result!.isUrgent, isFalse);
    });

    test('isUrgent is false when hasArrived is true', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _veryClose,
        averageSpeedKmh: 30,
      );

      expect(result!.hasArrived, isTrue);
      expect(result.isUrgent, isFalse);
    });

    // ── formatted ────────────────────────────────────────────────────────

    test('formatted returns "00:00" when hasArrived is true', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _veryClose,
        averageSpeedKmh: 30,
      );

      expect(result!.formatted, equals('00:00'));
    });

    test('formatted has mm:ss pattern for sub-hour durations', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        averageSpeedKmh: 30,
      );

      // Regex: exactly "mm:ss"
      expect(result!.formatted, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    // ── label ────────────────────────────────────────────────────────────

    test('label returns "Llegando" when hasArrived is true', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _veryClose,
        averageSpeedKmh: 30,
      );

      expect(result!.label, equals('Llegando'));
    });

    test('label returns "Menos de 1 min" for very short ETAs', () {
      // Place user just outside arrival radius but within walking distance.
      // ~0.0015° lat ≈ 167 m → outside 150 m radius but very close.
      const justOutside = LatLng(6.2442 + 0.0015, -75.5812);

      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: justOutside,
        averageSpeedKmh: 30,
      );

      // At 30 km/h, ~167 m takes ~0.33 min → label should be "Menos de 1 min".
      if (result != null && !result.hasArrived) {
        expect(result.label, equals('Menos de 1 min'));
      }
    });

    test('label returns "En X min" for trips under an hour', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        averageSpeedKmh: 30,
      );

      // ~20 min at 30 km/h.
      expect(result!.label, matches(RegExp(r'^En \d+ min$')));
    });

    test('label returns "En Xh Ymin" for trips over an hour', () {
      // 100 km north ≈ 2 h at 50 km/h.
      const farNorth = LatLng(6.2442 + 0.9, -75.5812);

      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: farNorth,
        averageSpeedKmh: 50,
      );

      expect(result!.label, matches(RegExp(r'^En \d+h.*')));
    });

    // ── distanceLabel ─────────────────────────────────────────────────────

    test('distanceLabel shows metres for distances under 1 km', () {
      // Slightly adjust to guarantee < 1 km.
      final shortResult = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: const LatLng(6.2442 + 0.003, -75.5812), // ~333 m
        averageSpeedKmh: 30,
      );

      if (shortResult != null && !shortResult.hasArrived) {
        expect(shortResult.distanceLabel, contains('m'));
        expect(shortResult.distanceLabel, isNot(contains('km')));
      }
    });

    test('distanceLabel shows km for distances over 1 km', () {
      final result = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        averageSpeedKmh: 30,
      );

      expect(result!.distanceLabel, contains('km'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('EtaCalculator.distanceKm', () {
    test('returns near-zero for identical points', () {
      final d = EtaCalculator.distanceKm(_medellin, _medellin);
      expect(d, closeTo(0.0, 0.001));
    });

    test('returns ~1.0 km for the two reference points', () {
      final d = EtaCalculator.distanceKm(_medellin, _oneKmNorth);
      expect(d, closeTo(1.0, 0.1));
    });

    test('is symmetric — distance A→B equals B→A', () {
      final ab = EtaCalculator.distanceKm(_medellin, _tenKmNorth);
      final ba = EtaCalculator.distanceKm(_tenKmNorth, _medellin);
      expect(ab, closeTo(ba, 0.001));
    });

    test('is non-negative for any pair of points', () {
      final d = EtaCalculator.distanceKm(_tenKmNorth, _medellin);
      expect(d, greaterThanOrEqualTo(0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('EtaCalculator.distanceMetres', () {
    test('is 1000× distanceKm for the same pair', () {
      final km = EtaCalculator.distanceKm(_medellin, _tenKmNorth);
      final m  = EtaCalculator.distanceMetres(_medellin, _tenKmNorth);
      expect(m, closeTo(km * 1000, 0.01));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('EtaCalculator.hasArrived', () {
    test('returns true when within arrival radius', () {
      expect(EtaCalculator.hasArrived(_medellin, _veryClose), isTrue);
    });

    test('returns false when beyond arrival radius', () {
      expect(EtaCalculator.hasArrived(_medellin, _oneKmNorth), isFalse);
    });

    test('returns true for identical positions', () {
      expect(EtaCalculator.hasArrived(_medellin, _medellin), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('EtaCalculator.hasMovedSignificantly', () {
    test('returns false for identical positions', () {
      expect(
        EtaCalculator.hasMovedSignificantly(_medellin, _medellin),
        isFalse,
      );
    });

    test('returns false for GPS jitter below threshold', () {
      // 0.00005° lat ≈ 5.5 m — below the 10 m threshold.
      const jitter = LatLng(6.2442 + 0.00005, -75.5812);
      expect(
        EtaCalculator.hasMovedSignificantly(_medellin, jitter),
        isFalse,
      );
    });

    test('returns true for movement above threshold', () {
      // 0.001° lat ≈ 111 m — well above the 10 m threshold.
      expect(
        EtaCalculator.hasMovedSignificantly(_medellin, _veryClose),
        isTrue,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('EtaCalculator.bearingDegrees', () {
    test('northward bearing is approximately 0°', () {
      final bearing = EtaCalculator.bearingDegrees(_medellin, _tenKmNorth);
      // Due north → bearing ≈ 0° (or 360°).
      expect(bearing, anyOf(closeTo(0.0, 2.0), closeTo(360.0, 2.0)));
    });

    test('southward bearing is approximately 180°', () {
      final bearing = EtaCalculator.bearingDegrees(_tenKmNorth, _medellin);
      expect(bearing, closeTo(180.0, 2.0));
    });

    test('bearing is in [0, 360] range', () {
      final bearing = EtaCalculator.bearingDegrees(_medellin, _oneKmNorth);
      expect(bearing, greaterThanOrEqualTo(0.0));
      expect(bearing, lessThan(360.0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('EtaCalculator.interpolate', () {
    test('t=0.0 returns from position', () {
      final result = EtaCalculator.interpolate(_medellin, _tenKmNorth, 0.0);
      expect(result.latitude,  closeTo(_medellin.latitude,  0.0001));
      expect(result.longitude, closeTo(_medellin.longitude, 0.0001));
    });

    test('t=1.0 returns to position', () {
      final result = EtaCalculator.interpolate(_medellin, _tenKmNorth, 1.0);
      expect(result.latitude,  closeTo(_tenKmNorth.latitude,  0.0001));
      expect(result.longitude, closeTo(_tenKmNorth.longitude, 0.0001));
    });

    test('t=0.5 returns midpoint', () {
      final result = EtaCalculator.interpolate(_medellin, _tenKmNorth, 0.5);
      final midLat = (_medellin.latitude + _tenKmNorth.latitude) / 2;
      final midLng = (_medellin.longitude + _tenKmNorth.longitude) / 2;
      expect(result.latitude,  closeTo(midLat, 0.0001));
      expect(result.longitude, closeTo(midLng, 0.0001));
    });

    test('t is clamped — values below 0 clamp to from', () {
      final result = EtaCalculator.interpolate(_medellin, _tenKmNorth, -1.0);
      expect(result.latitude,  closeTo(_medellin.latitude,  0.0001));
    });

    test('t is clamped — values above 1 clamp to to', () {
      final result = EtaCalculator.interpolate(_medellin, _tenKmNorth, 2.0);
      expect(result.latitude,  closeTo(_tenKmNorth.latitude,  0.0001));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('EtaCalculator.resetSmoother', () {
    test('reset clears speed history so next call uses provided speed', () {
      // Prime smoother with a slow speed.
      EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        averageSpeedKmh: 5,
      );

      // Reset — smoother should have no memory now.
      EtaCalculator.resetSmoother();

      // Calculate at a fast speed — should not be dragged down by old samples.
      final fast = EtaCalculator.calculate(
        unitPosition: _medellin,
        userPosition: _tenKmNorth,
        averageSpeedKmh: 60,
      );

      // At 60 km/h, 10 km takes ~600 s (10 min).
      // If the smoother still held 5 km/h it would give ~7200 s (120 min).
      expect(fast!.duration.inSeconds, lessThan(1200));
    });
  });
}
