import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/error_snackbar.dart';
import '../../tracking/controllers/auth_controller.dart';

// ── Form UI state — only the show/hide password toggle lives here.        ──
// ── Loading/error state comes from authControllerProvider (the real       ──
// ── source of truth for the login request).                              ──

final _obscurePasswordProvider =
    NotifierProvider<_ObscurePasswordNotifier, bool>(
  _ObscurePasswordNotifier.new,
);

class _ObscurePasswordNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeIn,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Delegates to AuthService → Traccar. On success, isAuthenticatedProvider
    // flips and go_router's redirect (see routes.dart) navigates to home —
    // no manual navigation needed here.
    await ref.read(authControllerProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
  }

  void _handleForgotPassword() {
    ErrorSnackBar.show(
      context,
      message: 'Recuperación de contraseña próximamente',
      isError: false,
    );
  }

  void _handleGoogleLogin() {
    ErrorSnackBar.show(
      context,
      message: 'Inicio con Google próximamente',
      isError: false,
    );
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoading       = ref.watch(authLoadingProvider);
    final obscurePassword = ref.watch(_obscurePasswordProvider);
    final size            = MediaQuery.sizeOf(context);

    // Show error snackbar reactively — errors come from AuthService's
    // typed AuthException, mapped to Spanish by authControllerProvider.
    ref.listen(authErrorProvider, (prev, next) {
      if (next != null && next != prev) {
        ErrorSnackBar.show(context, message: next);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      // Avoid bottom overflow when keyboard appears
      resizeToAvoidBottomInset: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // ── Hero section ─────────────────────────────────────
                    _HeroSection(
                      fadeAnim:  _fadeAnim,
                      slideAnim: _slideAnim,
                      height:    size.height * 0.38,
                    ),

                    // ── Form card ─────────────────────────────────────────
                    Expanded(
                      child: _FormCard(
                        formKey:         _formKey,
                        emailCtrl:       _emailCtrl,
                        passwordCtrl:    _passwordCtrl,
                        emailFocus:      _emailFocus,
                        passwordFocus:   _passwordFocus,
                        isLoading:       isLoading,
                        obscurePassword: obscurePassword,
                        onLogin:          _handleLogin,
                        onForgotPassword: _handleForgotPassword,
                        onGoogleLogin:    _handleGoogleLogin,
                        onTogglePassword: () => ref
                            .read(_obscurePasswordProvider.notifier)
                            .toggle(),
                        validateEmail:    _validateEmail,
                        validatePassword: _validatePassword,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.fadeAnim,
    required this.slideAnim,
    required this.height,
  });

  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(
        opacity: fadeAnim,
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D1829),
                      Color(0xFF101C2D),
                      AppColors.background,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // Decorative circles for depth
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Centered content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with glow
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: AppColors.accent,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App name
                    Text(
                      AppConstants.appName,
                      style: AppTypography.h1.copyWith(
                        fontSize: 32,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Monitorea tu servicio en tiempo real',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form card ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.emailFocus,
    required this.passwordFocus,
    required this.isLoading,
    required this.obscurePassword,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onGoogleLogin,
    required this.onTogglePassword,
    required this.validateEmail,
    required this.validatePassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoogleLogin;
  final VoidCallback onTogglePassword;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            Text('Iniciar sesión', style: AppTypography.h2),
            const SizedBox(height: 6),
            Text(
              'Ingresa tus credenciales para continuar',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 32),

            // Email field
            CustomTextField(
              label:        'Correo electrónico',
              hint:         'tu@correo.com',
              controller:   emailCtrl,
              focusNode:    emailFocus,
              keyboardType: TextInputType.emailAddress,
              prefixIcon:   Icons.email_outlined,
              validator:    validateEmail,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(passwordFocus),
            ),
            const SizedBox(height: 16),

            // Password field
            CustomTextField(
              label:          'Contraseña',
              hint:           '••••••••',
              controller:     passwordCtrl,
              focusNode:      passwordFocus,
              obscureText:    obscurePassword,
              prefixIcon:     Icons.lock_outline_rounded,
              validator:      validatePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onLogin(),
              suffixIcon: obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              onSuffixTap: onTogglePassword,
            ),
            const SizedBox(height: 8),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
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

            // Login button
            CustomButton(
              label:     'Iniciar sesión',
              onPressed: onLogin,
              isLoading: isLoading,
            ),
            const SizedBox(height: 24),

            // Divider
            _OrDivider(),
            const SizedBox(height: 20),

            // Google button
            _GoogleButton(onTap: onGoogleLogin),
            const SizedBox(height: 28),

            // Support link
            Center(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodySmall,
                  children: [
                    const TextSpan(text: '¿Problemas para acceder? '),
                    WidgetSpan(
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
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
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
  const _GoogleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Continuar con Google',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google G icon using text as fallback
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white10,
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Continuar con Google',
                style: AppTypography.button.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
