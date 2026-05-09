import 'package:intl/intl.dart';
import '../models/checkpoint_model.dart';
import 'eta_calculator.dart';

/// Stateless formatting helpers used throughout the Urbus UI.
///
/// All methods are pure functions — no side-effects, no state.
/// All user-facing strings are in Spanish.
abstract final class Formatters {
  // ── Date / time ───────────────────────────────────────────────────────────

  /// e.g. "Lunes, 28 abr 2026"
  static String fullDate(DateTime dt) =>
      DateFormat('EEEE, d MMM yyyy', 'es_CO').format(dt);

  /// e.g. "28 abr"
  static String shortDate(DateTime dt) =>
      DateFormat('d MMM', 'es_CO').format(dt);

  /// e.g. "28 abr 2026"
  static String mediumDate(DateTime dt) =>
      DateFormat('d MMM yyyy', 'es_CO').format(dt);

  /// e.g. "08:30 AM"
  static String time(DateTime dt) =>
      DateFormat('hh:mm a', 'es_CO').format(dt);

  /// e.g. "08:30" (24h for compact labels)
  static String time24(DateTime dt) =>
      DateFormat('HH:mm').format(dt);

  /// e.g. "28 abr · 08:30 AM"
  static String dateTime(DateTime dt) =>
      '${shortDate(dt)} · ${time(dt)}';

  /// Relative time label — used in alert and announcement lists.
  ///
  /// Examples:
  ///   < 1 min ago  → "Ahora"
  ///   < 60 min ago → "Hace 14 min"
  ///   < 24 h ago   → "Hace 3 h"
  ///   yesterday    → "Ayer"
  ///   otherwise    → "28 abr"
  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'Ahora';
    if (diff.inMinutes < 60)  return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24)    return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1)     return 'Ayer';
    return shortDate(dt);
  }

  /// Day-of-week abbreviation — e.g. "Lun", "Mar", "Mié".
  static String weekdayShort(DateTime dt) =>
      DateFormat('EEE', 'es_CO').format(dt);

  // ── ETA / duration ────────────────────────────────────────────────────────

  /// Formats a [Duration] as a countdown string.
  ///
  /// Examples:
  ///   5 min    → "05:00"
  ///   1h 3min  → "01:03:00"
  ///   0        → "00:00"
  static String countdown(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) return '00:00';

    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    if (h > 0) return '${_pad(h)}:${_pad(m)}:${_pad(s)}';
    return '${_pad(m)}:${_pad(s)}';
  }

  /// Human-friendly ETA label — used in collapsed bottom sheet card.
  ///
  /// Examples:
  ///   arriving → "Llegando"
  ///   < 1 min  → "Menos de 1 min"
  ///   < 60 min → "En 8 min"
  ///   >= 1 h   → "En 1h 3min"
  static String etaLabel(Duration duration) {
    if (duration.isNegative || duration.inSeconds <= 0) return 'Llegando';
    if (duration.inSeconds < 60) return 'Menos de 1 min';
    if (duration.inMinutes < 60) return 'En ${duration.inMinutes} min';
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return m == 0 ? 'En ${h}h' : 'En ${h}h ${m}min';
  }

  /// Formats an [EtaResult] — preferred over [etaLabel] when an
  /// [EtaResult] is already available (avoids recomputing).
  static String fromEtaResult(EtaResult result) {
    if (result.hasArrived) return 'Llegando';
    return etaLabel(result.duration);
  }

  // ── Distance ──────────────────────────────────────────────────────────────

  /// e.g. "1.4 km" or "350 m"
  static String distance(double metres) {
    if (metres < 0) return '-- m';
    if (metres >= 1000) {
      return '${(metres / 1000).toStringAsFixed(1)} km';
    }
    return '${metres.round()} m';
  }

  /// e.g. "1.4 km" from kilometres directly.
  static String distanceFromKm(double km) => distance(km * 1000);

  // ── Speed ─────────────────────────────────────────────────────────────────

  /// e.g. "42 km/h" — shows "-- km/h" for invalid values.
  static String speed(double kmh) {
    if (kmh < 0) return '-- km/h';
    return '${kmh.round()} km/h';
  }

  // ── Rating ────────────────────────────────────────────────────────────────

  /// e.g. "4.8" — always one decimal place, clamped 0–5.
  static String rating(double value) =>
      value.clamp(0.0, 5.0).toStringAsFixed(1);

  // ── Delay ─────────────────────────────────────────────────────────────────

  /// Delay badge label shown in visit cards and tracking bottom sheet.
  ///
  /// Examples:
  ///   0 or negative → "A tiempo"
  ///   positive      → "+12 min"
  static String delay(int minutes) {
    if (minutes <= 0) return 'A tiempo';
    return '+$minutes min';
  }

  /// True when delay is within the on-time tolerance window.
  static bool isOnTime(int delayMinutes) => delayMinutes <= 0;

  // ── Unit / checkpoint ─────────────────────────────────────────────────────

  /// e.g. "Unidad #204"
  static String unitLabel(String unitNumber) => 'Unidad #$unitNumber';

  /// Checkpoint order label — e.g. "Parada 3 de 5"
  static String checkpointLabel(int order, int total) =>
      'Parada $order de $total';

  /// Status label for a checkpoint — used in progress bar tooltips.
  static String checkpointStatus(CheckpointStatus status) =>
      switch (status) {
        CheckpointStatus.completed => 'Completada',
        CheckpointStatus.current   => 'En curso',
        CheckpointStatus.upcoming  => 'Próxima',
      };

  // ── Phone ─────────────────────────────────────────────────────────────────

  /// Colombian mobile format — e.g. "313 555 1234".
  /// Falls back to raw string if it does not match.
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    // Colombian mobile: 10 digits starting with 3xx
    if (digits.length == 10 && digits.startsWith('3')) {
      return '${digits.substring(0, 3)} '
          '${digits.substring(3, 6)} '
          '${digits.substring(6)}';
    }

    // Local landline: 7 digits
    if (digits.length == 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }

    return raw;
  }

  // ── Initials ──────────────────────────────────────────────────────────────

  /// Returns up to 2 initials from a full name — used in avatar fallbacks.
  /// e.g. "Carlos Mendoza" → "CM", "Ana" → "A"
  static String initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || fullName.trim().isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ── Notification / badge ──────────────────────────────────────────────────

  /// Badge count label — caps at 99+.
  static String badgeCount(int count) {
    if (count <= 0) return '';
    if (count > 99) return '99+';
    return '$count';
  }

  // ── Address ───────────────────────────────────────────────────────────────

  /// Truncates a long address for compact display.
  /// e.g. "Calle 45 #32-10, El Poblado, Medellín" → "Calle 45 #32-10..."
  static String shortAddress(String address, {int maxLength = 35}) {
    final trimmed = address.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength - 3)}...';
  }

  // ── Coordinates ───────────────────────────────────────────────────────────

  /// e.g. "6.2442° N, 75.5812° W"
  static String coordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}° $latDir, '
        '${lng.abs().toStringAsFixed(4)}° $lngDir';
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
