import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Provides static methods that present branded [SnackBar] notifications.
///
/// Usage:
/// ```dart
/// // Error
/// ErrorSnackBar.show(context, message: 'No se pudo conectar.');
///
/// // Success
/// ErrorSnackBar.show(context, message: 'Sesión iniciada.', isError: false);
///
/// // Info
/// ErrorSnackBar.showInfo(context, message: 'Función próximamente.');
/// ```
abstract final class ErrorSnackBar {
  // ── Core method ───────────────────────────────────────────────────────────

  /// Shows a floating snack-bar.
  ///
  /// [isError] controls the color scheme:
  /// - true  → red border + error icon (default)
  /// - false → green border + success icon
  static void show(
    BuildContext context, {
    required String message,
    bool isError = true,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message:     message,
      color:       isError ? AppColors.error : AppColors.success,
      icon:        isError
          ? Icons.error_outline_rounded
          : Icons.check_circle_outline_rounded,
      duration:    duration,
      actionLabel: actionLabel,
      onAction:    onAction,
    );
  }

  // ── Convenience methods ───────────────────────────────────────────────────

  /// Shows a success (green) snack-bar.
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message:     message,
      color:       AppColors.success,
      icon:        Icons.check_circle_outline_rounded,
      duration:    duration,
      actionLabel: actionLabel,
      onAction:    onAction,
    );
  }

  /// Shows a warning (amber) snack-bar.
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message:     message,
      color:       AppColors.warning,
      icon:        Icons.warning_amber_rounded,
      duration:    duration,
      actionLabel: actionLabel,
      onAction:    onAction,
    );
  }

  /// Shows an info (accent teal) snack-bar.
  /// Use for neutral messages like "Función próximamente".
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message:     message,
      color:       AppColors.accent,
      icon:        Icons.info_outline_rounded,
      duration:    duration,
      actionLabel: actionLabel,
      onAction:    onAction,
    );
  }

  // ── Private builder ───────────────────────────────────────────────────────

  static void _show(
    BuildContext context, {
    required String message,
    required Color color,
    required IconData icon,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;

    // Clear existing snack-bars to avoid stacking.
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration:  duration,
        behavior:  SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        content: Row(
          children: [
            // Status icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),

            // Message
            Expanded(
              child: Text(
                message,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label:     actionLabel,
                textColor: color,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
