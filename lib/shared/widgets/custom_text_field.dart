import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Branded text field that wraps [TextFormField] and applies the Urbus
/// design system — pill shape, dark fill, floating label, error highlight.
///
/// Usage:
/// ```dart
/// CustomTextField(
///   label: 'Email',
///   hint: 'tu@correo.com',
///   controller: _emailCtrl,
///   prefixIcon: Icons.mail_outline,
///   keyboardType: TextInputType.emailAddress,
///   validator: _validateEmail,
///   textInputAction: TextInputAction.next,
///   onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
/// )
/// ```
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.inputFormatters,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.initialValue,
    this.maxLength,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  /// When true, renders the show/hide password toggle automatically.
  /// If [suffixIcon] is also provided, it takes priority only when
  /// [obscureText] is false.
  final bool obscureText;

  final IconData? prefixIcon;

  /// Optional suffix icon — pass an [IconData], not a Widget.
  /// Use [onSuffixTap] to handle taps on it.
  /// Ignored when [obscureText] is true (password toggle takes priority).
  final IconData? suffixIcon;

  /// Called when the user taps the [suffixIcon].
  final VoidCallback? onSuffixTap;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Called when the user submits the field (presses the keyboard action).
  /// Use this to move focus to the next field or trigger form submission.
  final ValueChanged<String>? onFieldSubmitted;

  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  /// Number of lines. Forced to 1 when [obscureText] is true.
  final int maxLines;

  final bool enabled;
  final bool autofocus;
  final String? initialValue;
  final int? maxLength;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscured;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If caller toggles obscureText externally, sync internal state.
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  void _onFocusChange() {
    // Local UI state only — setState is correct here.
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    // Only dispose the node if we created it — never dispose caller's node.
    if (widget.focusNode == null) {
      _focusNode
        ..removeListener(_onFocusChange)
        ..dispose();
    }
    super.dispose();
  }

  // ── Suffix icon ───────────────────────────────────────────────────────────

  Widget? get _suffixWidget {
    // Password field — always show visibility toggle.
    if (widget.obscureText) {
      return _SuffixIconButton(
        icon: _obscured
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        isFocused: _isFocused,
        onTap: () => setState(() => _obscured = !_obscured),
      );
    }

    // Custom suffix icon from caller.
    if (widget.suffixIcon != null) {
      return _SuffixIconButton(
        icon: widget.suffixIcon!,
        isFocused: _isFocused,
        onTap: widget.onSuffixTap,
      );
    }

    return null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.surface
                : AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? AppColors.accent : AppColors.border,
              width: 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            validator: widget.validator,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            onChanged: widget.onChanged,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            initialValue: widget.controller == null ? widget.initialValue : null,
            style: AppTypography.body.copyWith(fontSize: 15),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: _isFocused ? AppColors.accent : AppColors.textSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _isFocused ? AppColors.accent : AppColors.textSecondary,
                    )
                  : null,
              suffixIcon: _suffixWidget,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

// ── Suffix icon button ────────────────────────────────────────────────────────

/// Reusable tappable suffix icon with consistent sizing and color.
class _SuffixIconButton extends StatelessWidget {
  const _SuffixIconButton({
    required this.icon,
    required this.isFocused,
    this.onTap,
  });

  final IconData icon;
  final bool isFocused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Minimum 44x44 touch target.
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          icon,
          size: 20,
          color: isFocused
              ? AppColors.accent
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}
