import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

// ─────────────────────────────────────────────
// SOCIAL PROVIDER ENUM
// ─────────────────────────────────────────────

enum SocialProvider {
  google,
  apple,
}

extension SocialProviderX on SocialProvider {
  String get label => switch (this) {
        SocialProvider.google => 'Continuar con Google',
        SocialProvider.apple => 'Continuar con Apple',
      };

  String get iconAsset => switch (this) {
        SocialProvider.google => 'assets/icons/google.svg',
        SocialProvider.apple => 'assets/icons/apple.svg',
      };
}

// ─────────────────────────────────────────────
// SOCIAL LOGIN BUTTON
// ─────────────────────────────────────────────

/// Reusable social OAuth button for Google and Apple sign-in.
///
/// Handles its own loading state internally so the parent widget
/// doesn't need to manage it — just pass [onPressed] and react
/// to success/error via the auth provider.
class SocialLoginButton extends StatefulWidget {
  final SocialProvider provider;
  final Future<void> Function() onPressed;

  /// When true, disables the button regardless of internal state.
  /// Useful when another async operation is in progress on the same screen.
  final bool disabled;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.disabled = false,
  });

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;

  // Subtle press animation — scale down on tap.
  late final AnimationController _scaleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.97,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isLoading || widget.disabled) return;

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    _scaleController.reverse();

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        _scaleController.forward();
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || _isLoading;

    return Semantics(
      label: widget.provider.label,
      button: true,
      enabled: !isDisabled,
      child: ScaleTransition(
        scale: _scaleController,
        child: GestureDetector(
          onTap: _handleTap,
          onTapDown: (_) => _scaleController.reverse(),
          onTapCancel: () => _scaleController.forward(),
          child: AnimatedOpacity(
            opacity: isDisabled && !_isLoading ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: _isLoading
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : AppColors.border,
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Icon + label row ─────────────────────────
                  AnimatedOpacity(
                    opacity: _isLoading ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          widget.provider.iconAsset,
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.provider.label,
                          style: AppTypography.button.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Loading indicator ────────────────────────
                  if (_isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SOCIAL LOGIN DIVIDER
// ─────────────────────────────────────────────

/// "— o continúa con —" divider between email form and social buttons.
/// Extracted here so the login screen stays clean.
class SocialLoginDivider extends StatelessWidget {
  const SocialLoginDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.border, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o continúa con',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.border, thickness: 1),
        ),
      ],
    );
  }
}
