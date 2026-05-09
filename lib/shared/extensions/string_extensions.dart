/// Utility extensions on [String] used across the Urbus app.
extension StringExtensions on String {
  // ── Casing ─────────────────────────────────────────────────────────────────

  /// Capitalises the first letter; leaves the rest unchanged.
  /// e.g. "hello world" → "Hello world"
  String get capitalised {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Title-cases every word.
  /// e.g. "garbage route north" → "Garbage Route North"
  String get titleCase {
    return split(' ')
        .map((w) => w.isEmpty ? w : w.capitalised)
        .join(' ');
  }

  // ── Truncation ─────────────────────────────────────────────────────────────

  /// Truncates the string to [maxLength] characters, appending [ellipsis].
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  // ── Validation helpers ─────────────────────────────────────────────────────

  /// Returns `true` if the string is a syntactically valid email address.
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(trim());
  }

  /// Returns `true` if the string contains only digits.
  bool get isNumeric => RegExp(r'^\d+$').hasMatch(this);

  /// Returns `true` if the string is null-safe non-empty after trimming.
  bool get isNotBlank => trim().isNotEmpty;

  // ── Safe parsing ───────────────────────────────────────────────────────────

  /// Parses to [int], returning [fallback] on failure.
  int toIntOrDefault([int fallback = 0]) =>
      int.tryParse(this) ?? fallback;

  /// Parses to [double], returning [fallback] on failure.
  double toDoubleOrDefault([double fallback = 0.0]) =>
      double.tryParse(this) ?? fallback;

  // ── Sanitisation ───────────────────────────────────────────────────────────

  /// Strips all non-numeric characters — useful for cleaning phone inputs.
  String get digitsOnly => replaceAll(RegExp(r'\D'), '');

  /// Removes leading/trailing whitespace and collapses internal whitespace.
  String get normalized => trim().replaceAll(RegExp(r'\s+'), ' ');

  // ── Initials ───────────────────────────────────────────────────────────────

  /// Returns up to 2 uppercase initials from a full name.
  /// e.g. "Juan De Los Santos" → "JD"
  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Nullable-safe variant for nullable strings.
extension NullableStringExtensions on String? {
  /// Returns `true` when the string is `null` or blank.
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  /// Returns [fallback] when `null` or blank; otherwise returns `this`.
  String orDefault([String fallback = '']) =>
      isNullOrBlank ? fallback : this!;
}
