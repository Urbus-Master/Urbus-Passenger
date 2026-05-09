import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Convenience extensions on [BuildContext] to reduce boilerplate.
extension ContextExtensions on BuildContext {
  // ── Theme shortcuts ────────────────────────────────────────────────────────

  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ── App colour shortcuts ────────────────────────────────────────────────────

  Color get background => AppColors.background;
  Color get surface => AppColors.surface;
  Color get accent => AppColors.accent;
  Color get textPrimary => AppColors.textPrimary;
  Color get textSecondary => AppColors.textSecondary;

  // ── App typography shortcuts ───────────────────────────────────────────────

  TextStyle get h1 => AppTypography.h1;
  TextStyle get h2 => AppTypography.h2;
  TextStyle get h3 => AppTypography.h3;
  TextStyle get bodyText => AppTypography.body;
  TextStyle get bodySmall => AppTypography.bodySmall;
  TextStyle get labelStyle => AppTypography.label;

  // ── Media query ────────────────────────────────────────────────────────────

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Safe area top padding (status bar height).
  double get topPadding => MediaQuery.of(this).padding.top;

  /// Safe area bottom padding (home indicator height on iOS).
  double get bottomPadding => MediaQuery.of(this).padding.bottom;

  bool get isSmallScreen => screenWidth < 360;
  bool get isTablet => screenWidth >= 600;

  // ── Navigation ─────────────────────────────────────────────────────────────

  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  bool get canPop => Navigator.of(this).canPop();

  // ── SnackBar ───────────────────────────────────────────────────────────────

  void showSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Dismisses the keyboard by removing focus from the current node.
  void dismissKeyboard() => FocusScope.of(this).unfocus();
}
