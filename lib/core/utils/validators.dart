/// Form-field and input validators used with [TextFormField].
///
/// Each method returns `null` when valid, or a human-readable error [String].
/// All messages are in Spanish — consistent with the Urbus UI locale.
abstract final class Validators {
  // ── Email ────────────────────────────────────────────────────

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    // RFC-5322 simplified — sufficient for UX-level validation.
    final pattern = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!pattern.hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  // ── Password ─────────────────────────────────────────────────

  /// Mínimo 8 caracteres, al menos una letra y un número.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una letra';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'La contraseña debe contener al menos un número';
    }
    return null;
  }

  /// Valida que [value] coincida con [original] (campo confirmar contraseña).
  static String? Function(String?) confirmPassword(String original) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Confirma tu contraseña';
      }
      if (value != original) {
        return 'Las contraseñas no coinciden';
      }
      return null;
    };
  }

  /// Validates current password before allowing a change.
  /// Delegates strength rules to [password] — kept separate so the
  /// "current password" field can show a simpler required-only error.
  static String? currentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña actual';
    }
    return null;
  }

  // ── Name ─────────────────────────────────────────────────────

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (value.trim().length > 80) {
      return 'El nombre no puede superar los 80 caracteres';
    }
    // Reject strings that are purely numeric or contain obvious junk.
    if (RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return 'Ingresa un nombre válido';
    }
    return null;
  }

  // ── Phone ────────────────────────────────────────────────────

  /// Colombian mobile numbers: 10 digits starting with 3xx.
  /// Also accepts 7-digit local landlines.
  /// Strips spaces, dashes, and parentheses before evaluating.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de teléfono es obligatorio';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10 && digits.startsWith('3')) return null;
    if (digits.length == 7) return null;

    if (digits.length != 10) {
      return 'Ingresa un número de 10 dígitos';
    }
    if (!digits.startsWith('3')) {
      return 'Los celulares colombianos comienzan con 3';
    }
    return null;
  }

  // ── Address ──────────────────────────────────────────────────

  /// Validates a Colombian-style street address.
  /// Minimum 5 chars; must not be purely numeric.
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La dirección es obligatoria';
    }
    if (value.trim().length < 5) {
      return 'Ingresa una dirección completa';
    }
    if (value.trim().length > 120) {
      return 'La dirección no puede superar los 120 caracteres';
    }
    if (RegExp(r'^[0-9\s]+$').hasMatch(value.trim())) {
      return 'Ingresa una dirección válida (Ej: Cra 45 #32-10)';
    }
    return null;
  }

  // ── Required / general ───────────────────────────────────────

  /// Generic non-empty validator for simple required fields.
  /// [fieldName] is used in the error message — pass the label of the field.
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  /// Validates that a numeric string is a positive number.
  /// Used for any quantity or unit-number input fields.
  static String? positiveNumber(String? value, {String fieldName = 'El valor'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    final parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName debe ser un número';
    }
    if (parsed <= 0) {
      return '$fieldName debe ser mayor a cero';
    }
    return null;
  }

  // ── Composition helper ───────────────────────────────────────

  /// Chains multiple validators and returns the first error found.
  ///
  /// Usage:
  /// ```dart
  /// validator: Validators.compose([
  ///   Validators.required,
  ///   Validators.email,
  /// ]),
  /// ```
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
