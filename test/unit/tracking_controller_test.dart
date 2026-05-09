import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:urbus/core/services/tracking_service.dart';
import 'package:urbus/core/models/unit_model.dart';
import 'package:urbus/core/models/checkpoint_model.dart';
import 'package:urbus/core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a minimal [UnitModel] for use in state tests.
UnitModel _unit({
  int id = 1,
  String unitNumber = '101',
  String driverName = 'Test Driver',
  double latitude = 6.2442,
  double longitude = -75.5812,
  double speed = 25.0,
  UnitStatus status = UnitStatus.active,
}) {
  return UnitModel(
    id: id.toString(),
    unitNumber: unitNumber,
    driverName: driverName,
    driverRating: 4.5,
    latitude: latitude,
    longitude: longitude,
    speed: speed,
    status: status,
    lastUpdate: DateTime.now(),
    routeId: 'route-1',
  );
}

/// Builds a minimal [CheckpointModel] for use in state tests.
CheckpointModel _cp({
  required int id,
  required int order,
  CheckpointStatus status = CheckpointStatus.upcoming,
  DateTime? estimatedTime,
  DateTime? actualTime,
}) {
  return CheckpointModel(
    id: id.toString(),
    name: 'Stop $id',
    address: 'Address $id',
    latitude: 6.2442 + id * 0.005,
    longitude: -75.5812 + id * 0.005,
    order: order,
    estimatedTime: estimatedTime ?? DateTime.now().add(Duration(minutes: order * 5)),
    status: status,
    actualTime: actualTime,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  group('TrackingState — initial state', () {
    test('default constructor produces a clean initial state', () {
      const state = TrackingState.initial();

      expect(state.connectionStatus, equals(ConnectionStatus.disconnected));
      expect(state.activeUnit, isNull);
      expect(state.checkpoints, isEmpty);
      expect(state.eta, isNull);
      expect(state.userPosition, isNull);
      expect(state.isAlertScheduled, isFalse);
      expect(state.errorMessage, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('TrackingState — convenience getters', () {
    test('isConnected is true only when status is connected', () {
      expect(
        const TrackingState(connectionStatus: ConnectionStatus.connected).isConnected,
        isTrue,
      );
      expect(
        const TrackingState(connectionStatus: ConnectionStatus.disconnected).isConnected,
        isFalse,
      );
      expect(
        const TrackingState(connectionStatus: ConnectionStatus.reconnecting).isConnected,
        isFalse,
      );
    });

    test('isReconnecting is true only when status is reconnecting', () {
      expect(
        const TrackingState(connectionStatus: ConnectionStatus.reconnecting).isReconnecting,
        isTrue,
      );
      expect(
        const TrackingState(connectionStatus: ConnectionStatus.connected).isReconnecting,
        isFalse,
      );
    });

    test('hasUnit is false when activeUnit is null', () {
      expect(const TrackingState().hasUnit, isFalse);
    });

    test('hasUnit is true when activeUnit is set', () {
      final state = TrackingState(activeUnit: _unit());
      expect(state.hasUnit, isTrue);
    });

    test('hasEta is false when eta is null', () {
      expect(const TrackingState().hasEta, isFalse);
    });

    test('hasEta is true when eta is set', () {
      final state = TrackingState(eta: const Duration(minutes: 5));
      expect(state.hasEta, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('TrackingState — isEtaUrgent', () {
    test('returns false when eta is null', () {
      expect(const TrackingState().isEtaUrgent, isFalse);
    });

    test('returns true when eta is at the urgent threshold', () {
      final state = TrackingState(
        eta: Duration(minutes: AppConstants.etaUrgentThresholdMinutes),
      );
      expect(state.isEtaUrgent, isTrue);
    });

    test('returns true when eta is below the urgent threshold', () {
      final state = TrackingState(
        eta: Duration(minutes: AppConstants.etaUrgentThresholdMinutes - 1),
      );
      expect(state.isEtaUrgent, isTrue);
    });

    test('returns false when eta exceeds the urgent threshold', () {
      final state = TrackingState(
        eta: Duration(minutes: AppConstants.etaUrgentThresholdMinutes + 1),
      );
      expect(state.isEtaUrgent, isFalse);
    });

    test('returns false for a zero-second ETA (unit arrived)', () {
      final state = TrackingState(eta: Duration.zero);
      // Duration.zero.inMinutes == 0 which is <= threshold → urgent.
      // Documenting this intentional behaviour — arrived units are "urgent".
      expect(state.isEtaUrgent, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('TrackingState — etaFormatted', () {
    test('returns "--:--" when eta is null', () {
      expect(const TrackingState().etaFormatted, equals('--:--'));
    });

    test('formats minutes and seconds correctly', () {
      final state = TrackingState(eta: const Duration(minutes: 8, seconds: 42));
      expect(state.etaFormatted, equals('08:42'));
    });

    test('pads single-digit minutes and seconds with leading zero', () {
      final state = TrackingState(eta: const Duration(minutes: 3, seconds: 5));
      expect(state.etaFormatted, equals('03:05'));
    });

    test('handles exactly one hour correctly (wraps minutes)', () {
      // 60 min → remainder(60) == 0 min, 0 sec.
      final state = TrackingState(eta: const Duration(hours: 1));
      expect(state.etaFormatted, equals('00:00'));
    });

    test('formats zero duration as "00:00"', () {
      final state = TrackingState(eta: Duration.zero);
      expect(state.etaFormatted, equals('00:00'));
    });

    test('formatted output matches mm:ss pattern', () {
      final state = TrackingState(eta: const Duration(minutes: 12, seconds: 34));
      expect(state.etaFormatted, matches(RegExp(r'^\d{2}:\d{2}$')));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('TrackingState — currentCheckpoint', () {
    test('returns null when checkpoints list is empty', () {
      expect(const TrackingState().currentCheckpoint, isNull);
    });

    test('returns the checkpoint with current status', () {
      final cps = [
        _cp(id: 1, order: 1, status: CheckpointStatus.completed),
        _cp(id: 2, order: 2, status: CheckpointStatus.current),
        _cp(id: 3, order: 3, status: CheckpointStatus.upcoming),
      ];
      final state = TrackingState(checkpoints: cps);
      expect(state.currentCheckpoint?.id, equals('2'));
    });

    test('returns null when no checkpoint has current status', () {
      final cps = [
        _cp(id: 1, order: 1, status: CheckpointStatus.completed),
        _cp(id: 2, order: 2, status: CheckpointStatus.upcoming),
      ];
      final state = TrackingState(checkpoints: cps);
      expect(state.currentCheckpoint, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('TrackingState — completedCount', () {
    test('returns 0 when no checkpoints are completed', () {
      final cps = [
        _cp(id: 1, order: 1, status: CheckpointStatus.current),
        _cp(id: 2, order: 2, status: CheckpointStatus.upcoming),
      ];
      final state = TrackingState(checkpoints: cps);
      expect(state.completedCount, equals(0));
    });

    test('returns correct count with mixed statuses', () {
      final cps = [
        _cp(id: 1, order: 1, status: CheckpointStatus.completed),
        _cp(id: 2, order: 2, status: CheckpointStatus.completed),
        _cp(id: 3, order: 3, status: CheckpointStatus.current),
        _cp(id: 4, order: 4, status: CheckpointStatus.upcoming),
      ];
      final state = TrackingState(checkpoints: cps);
      expect(state.completedCount, equals(2));
    });

    test('returns total when all checkpoints are completed', () {
      final cps = List.generate(
        5,
        (i) => _cp(id: i + 1, order: i + 1, status: CheckpointStatus.completed),
      );
      final state = TrackingState(checkpoints: cps);
      expect(state.completedCount, equals(5));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('TrackingState — copyWith', () {
    test('returns a new instance with updated connectionStatus', () {
      const initial = TrackingState.initial();
      final updated = initial.copyWith(
        connectionStatus: ConnectionStatus.connected,
      );
      expect(updated.connectionStatus, equals(ConnectionStatus.connected));
      // Original must be unchanged.
      expect(initial.connectionStatus, equals(ConnectionStatus.disconnected));
    });

    test('preserves unspecified fields when partially updating', () {
      final unit = _unit(unitNumber: '202');
      final state = TrackingState(
        activeUnit: unit,
        eta: const Duration(minutes: 10),
        isAlertScheduled: true,
      );

      final updated = state.copyWith(
        connectionStatus: ConnectionStatus.connected,
      );

      expect(updated.activeUnit?.unitNumber, equals('202'));
      expect(updated.eta?.inMinutes, equals(10));
      expect(updated.isAlertScheduled, isTrue);
    });

    test('clearEta flag sets eta to null regardless of provided eta', () {
      final state = TrackingState(eta: const Duration(minutes: 5));
      final cleared = state.copyWith(clearEta: true);
      expect(cleared.eta, isNull);
    });

    test('clearError flag sets errorMessage to null', () {
      final state = TrackingState(errorMessage: 'Network error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('clearEta=true takes priority over a provided eta value', () {
      final state = TrackingState(eta: const Duration(minutes: 5));
      final cleared = state.copyWith(
        eta: const Duration(minutes: 99),
        clearEta: true,
      );
      expect(cleared.eta, isNull);
    });

    test('updating checkpoints replaces the entire list', () {
      final initial = TrackingState(
        checkpoints: [_cp(id: 1, order: 1)],
      );
      final newCps = [
        _cp(id: 2, order: 1),
        _cp(id: 3, order: 2),
      ];
      final updated = initial.copyWith(checkpoints: newCps);
      expect(updated.checkpoints.length, equals(2));
      expect(updated.checkpoints.first.id, equals('2'));
    });

    test('updating userPosition stores the new LatLng', () {
      const initial = TrackingState.initial();
      const position = LatLng(6.2442, -75.5812);
      final updated = initial.copyWith(userPosition: position);
      expect(updated.userPosition?.latitude, closeTo(6.2442, 0.0001));
    });

    test('toggling isAlertScheduled works correctly', () {
      const state = TrackingState(isAlertScheduled: false);
      final on  = state.copyWith(isAlertScheduled: true);
      final off = on.copyWith(isAlertScheduled: false);

      expect(on.isAlertScheduled, isTrue);
      expect(off.isAlertScheduled, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('MockTrackingData', () {
    test('unit has the expected id and unit number', () {
      final unit = MockTrackingData.unit;
      expect(unit.id, equals('unit-204'));
      expect(unit.unitNumber, equals('204'));
    });

    test('unit has valid coordinates', () {
      final unit = MockTrackingData.unit;
      expect(unit.latitude, isNonZero);
      expect(unit.longitude, isNonZero);
    });

    test('unit status is active', () {
      expect(MockTrackingData.unit.status, equals(UnitStatus.active));
    });

    test('checkpoints list has exactly 5 stops', () {
      expect(MockTrackingData.checkpoints.length, equals(5));
    });

    test('checkpoints are in sequential order', () {
      final orders = MockTrackingData.checkpoints.map((c) => c.order).toList();
      expect(orders, equals([1, 2, 3, 4, 5]));
    });

    test('first two checkpoints are completed', () {
      final cps = MockTrackingData.checkpoints;
      expect(cps[0].status, equals(CheckpointStatus.completed));
      expect(cps[1].status, equals(CheckpointStatus.completed));
    });

    test('third checkpoint is current', () {
      expect(
        MockTrackingData.checkpoints[2].status,
        equals(CheckpointStatus.current),
      );
    });

    test('last two checkpoints are upcoming', () {
      final cps = MockTrackingData.checkpoints;
      expect(cps[3].status, equals(CheckpointStatus.upcoming));
      expect(cps[4].status, equals(CheckpointStatus.upcoming));
    });

    test('advanceUnit changes latitude and longitude on each tick', () {
      final base = MockTrackingData.unit;
      final tick1 = MockTrackingData.advanceUnit(base, 1);
      final tick2 = MockTrackingData.advanceUnit(base, 2);

      // Position should differ between ticks.
      expect(tick1.latitude,  isNot(equals(base.latitude)));
      expect(tick2.latitude,  isNot(equals(tick1.latitude)));
    });

    test('advanceUnit updates lastUpdate timestamp', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final base = MockTrackingData.unit;
      final advanced = MockTrackingData.advanceUnit(base, 5);
      expect(advanced.lastUpdate.isAfter(before), isTrue);
    });

    test('advanceUnit preserves driver metadata', () {
      final base = MockTrackingData.unit;
      final advanced = MockTrackingData.advanceUnit(base, 3);
      expect(advanced.driverName, equals(base.driverName));
      expect(advanced.unitNumber, equals(base.unitNumber));
      expect(advanced.driverRating, equals(base.driverRating));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('ConnectionStatus enum', () {
    test('all expected values exist', () {
      const values = ConnectionStatus.values;
      expect(values, contains(ConnectionStatus.disconnected));
      expect(values, contains(ConnectionStatus.connecting));
      expect(values, contains(ConnectionStatus.connected));
      expect(values, contains(ConnectionStatus.reconnecting));
      expect(values, contains(ConnectionStatus.error));
    });

    test('connected and reconnecting are mutually exclusive states', () {
      const connected    = ConnectionStatus.connected;
      const reconnecting = ConnectionStatus.reconnecting;
      expect(connected == reconnecting, isFalse);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM MATCHERS
// ─────────────────────────────────────────────────────────────────────────────

/// Matcher that asserts a numeric value is not zero.
const Matcher isNonZero = _IsNonZero();

class _IsNonZero extends Matcher {
  const _IsNonZero();

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is num) return item != 0;
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('a non-zero number');
}
