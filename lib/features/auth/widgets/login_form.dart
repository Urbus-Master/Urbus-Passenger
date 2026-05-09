import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/error_snackbar.dart';

// ── Form state ────────────────────────────────────────────────────────────────

class LoginFormState {
  const LoginFormState({
    this.isLoading       = false,
    this.obscurePassword = true,
    this.email           = '',
    this.password        = '',
    this.error,
  });

  final bool    isLoading;
  final bool    obscurePassword;
  final String  email;
  final String  password;
  final String? error;

  /// True when both fields have content — enables the login button.
  bool get canSubmit =>
      email.trim().isNotEmpty && password.isNotEmpty && !isLoading;

  LoginFormState copyWith({
    bool?    isLoading,
    bool?    obscurePassword,
    String?  email,
    String?  password,
    String?  error,
  }) =>
      LoginFormState(
        isLoading:       isLoading       ?? this.isLoading,
        obscurePassword: obscurePassword ?? this.obscurePassword,
        email:           email           ?? this.email,
        password:        password        ?? this.password,
        error:           error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class LoginFormNotifier extends Notifier<LoginFormState> {
  @override
  LoginFormState build() => const LoginFormState();

  void setEmail(String value) =>
      state = state.copyWith(email: value);

  void setPassword(String value) =>
      state = state.copyWith(password: value);

  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  void setLoading(bool value) =>
      state = state.copyWith(isLoading: value);

  void setError(String? message) =>
      state = state.copyWith(error: message);

  void reset() => state = const LoginFormState();
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// autoDispose — state is discarded when the user leaves the login screen.
final loginFormProvider =
    NotifierProvider<LoginFormNotifier, LoginFormState>(
  LoginFormNotifier.new,
);

// ── Widget ────────────────────────────────────────────────────────────────────

/// Standalone login form widget.
///
/// Extracts all form logic out of [LoginScreen] so the screen stays lean.
/// Can be used and tested independently of the full screen.
///
/// [onSuccess] is called after successful validation — the screen handles
/// the actual auth call and navigation.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({
    super.key,
    required this.onSuccess,
    this.onForgotPassword,
    this.onGoogleLogin,
  });

  /// Called with (email, password) when the form passes validation.
  final void Function(String email, String password) onSuccess;

  /// Called when the user taps "¿Olvidaste tu contraseña?".
  final VoidCallback? onForgotPassword;

  /// Called when the user taps "Continuar con Google".
  final VoidCallback? onGoogleLogin;

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus   = FocusNode();
  final _passFocus    = FocusNode();

  @override
  void initState() {
    super.initState();
    // Sync controller changes → provider state so canSubmit updates live.
    _emailCtrl.addListener(
      () => ref.read(loginFormProvider.notifier).setEmail(_emailCtrl.text),
    );
    _passwordCtrl.addListener(
      () => ref
          .read(loginFormProvider.notifier)
          .setPassword(_passwordCtrl.text),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo electrónico';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Mínimo ${AppConstants.minPasswordLength} caracteres';
    }
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSuccess(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(loginFormProvider);

    // Show error snackbar reactively whenever error changes.
    ref.listen(loginFormProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ErrorSnackBar.show(context, message: next.error!);
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Email ──────────────────────────────────────────────────────
          CustomTextField(
            label:           'Correo electrónico',
            hint:            'tu@correo.com',
            controller:      _emailCtrl,
            focusNode:       _emailFocus,
            keyboardType:    TextInputType.emailAddress,
            prefixIcon:      Icons.email_outlined,
            validator:       _validateEmail,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passFocus),
          ),
          const SizedBox(height: 16),

          // ── Password ───────────────────────────────────────────────────
          CustomTextField(
            label:           'Contraseña',
            hint:            '••••••••',
            controller:      _passwordCtrl,
            focusNode:       _passFocus,
            obscureText:     formState.obscurePassword,
            prefixIcon:      Icons.lock_outline_rounded,
            validator:       _validatePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            suffixIcon: formState.obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            onSuffixTap: () =>
                ref.read(loginFormProvider.notifier).toggleObscure(),
          ),
          const SizedBox(height: 8),

          // ── Forgot password ────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: AppTypography.buttonSmall,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Submit button ──────────────────────────────────────────────
          CustomButton(
            label:     'Iniciar sesión',
            onPressed: formState.canSubmit ? _submit : null,
            isLoading: formState.isLoading,
          ),
          const SizedBox(height: 24),

          // ── Divider ────────────────────────────────────────────────────
          const _OrDivider(),
          const SizedBox(height: 20),

          // ── Google button ──────────────────────────────────────────────
          _GoogleButton(
            onTap: widget.onGoogleLogin,
          ),
          const SizedBox(height: 28),

          // ── Support link ───────────────────────────────────────────────
          Center(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodySmall,
                children: [
                  const TextSpan(text: '¿Problemas para acceder? '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Contacta soporte',
                        style: AppTypography.buttonSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Or divider ────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

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

// ── Google button ─────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Continuar con Google',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.borderActive),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google G — fallback icon sin assets externos
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLight,
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Continuar con Google',
                style: AppTypography.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
