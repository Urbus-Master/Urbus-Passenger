import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Full-width primary / outlined CTA button used throughout the app.
///
/// Usage:
/// ```dart
/// CustomButton(
///   label: 'Track My Truck',
///   onPressed: _handlePress,
/// )
///
/// CustomButton(
///   label: 'Sign Up',
///   isOutlined: true,
///   icon: Icons.person_add_outlined,
///   onPressed: _handlePress,
/// )
/// ```
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
  });

  final String label;

  /// Set to `null` to disable the button.
  final VoidCallback? onPressed;

  /// When `true`, replaces the label with a circular progress indicator
  /// and disables interaction.
  final bool isLoading;

  /// When `true`, renders a transparent button with an accent-coloured border
  /// and accent-coloured text (secondary action style).
  final bool isOutlined;

  /// Optional leading icon displayed to the left of the label.
  final IconData? icon;

  /// Override width; defaults to [double.infinity] (full-width).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isOutlined ? AppColors.accent : AppColors.background,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.button.copyWith(
                  color: isOutlined
                      ? AppColors.accent
                      : AppColors.background,
                ),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50),
      side: isOutlined
          ? const BorderSide(color: AppColors.accent, width: 1.5)
          : BorderSide.none,
    );

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            backgroundColor: Colors.transparent,
            minimumSize: Size(width ?? double.infinity, 54),
            shape: shape,
            side: const BorderSide(color: AppColors.accent, width: 1.5),
            textStyle: AppTypography.button,
          )
        : ElevatedButton.styleFrom(
            backgroundColor:
                isDisabled ? AppColors.surfaceLight : AppColors.accent,
            foregroundColor: AppColors.background,
            minimumSize: Size(width ?? double.infinity, 54),
            shape: shape,
            elevation: 0,
            textStyle: AppTypography.button,
          );

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: child,
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: !isDisabled,
      child: GestureDetector(
        onTap: () {
          if (!isDisabled) {
            HapticFeedback.lightImpact();
            onPressed?.call();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width ?? double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            gradient: isDisabled
                ? null
                : const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isDisabled ? AppColors.surfaceLight : null,
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
