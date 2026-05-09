import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../history/controllers/history_controller.dart';
import '../widgets/stats_row.dart';
import '../../../core/services/connectivity_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(historyStatsProvider);

    if (user == null) {
      return const _GuestView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Hero section ───────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroSection(
              name: user.name,
              email: user.email,
              avatarUrl: user.avatarUrl,
              role: user.role,
            ),
          ),

          // ── Stats row ──────────────────────────────────────
          SliverToBoxAdapter(
            child: StatsRow(stats: stats),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Mi cuenta ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(label: 'MI CUENTA'),
          ),
          SliverToBoxAdapter(
            child: _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.home_outlined,
                  label: 'Mi dirección',
                  subtitle: user.address ?? 'Sin dirección registrada',
                  onTap: () => _showEditAddressSheet(context, ref, user.address),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Preferencias de alertas',
                  onTap: () => ref.read(appRouterProvider).push('/alerts'),
                ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: 'Cambiar contraseña',
                  onTap: () => ErrorSnackBar.showInfo(
                    context,
                    message: 'Cambio de contraseña próximamente',
                  ),
                ),
                _MenuItem(
                  icon: Icons.language_outlined,
                  label: 'Idioma',
                  trailing: Text(
                    'Español',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  onTap: null,
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Soporte ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(label: 'SOPORTE'),
          ),
          SliverToBoxAdapter(
            child: _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Centro de ayuda',
                  onTap: () => ErrorSnackBar.showInfo(
                    context,
                    message: 'Abriendo centro de ayuda...',
                  ),
                ),
                _MenuItem(
                  icon: Icons.campaign_outlined,
                  label: 'Avisos municipales',
                  onTap: () =>
                      ref.read(appRouterProvider).push('/announcements'),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'Acerca de Urbus',
                  onTap: () => _showAboutDialog(context),
                ),
                _MenuItem(
                  icon: Icons.logout,
                  label: 'Cerrar sesión',
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── Modals ───────────────────────────────────────────────────

  void _showEditAddressSheet(
    BuildContext context,
    WidgetRef ref,
    String? currentAddress,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _EditAddressSheet(currentAddress: currentAddress),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('¿Cerrar sesión?', style: AppTypography.h3),
        content: Text(
          'Se cerrará tu sesión en este dispositivo.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Urbus',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Urbus. Todos los derechos reservados.',
      children: [
        const SizedBox(height: 12),
        Text(
          'Plataforma de monitoreo y control de flotas de transporte urbano.',
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────

class _HeroSection extends ConsumerWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final UserRole role;

  const _HeroSection({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding + 24, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              // Accent glow ring
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.accent,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!)
                    : null,
                onBackgroundImageError: avatarUrl != null
                    ? (_, __) {}
                    : null,
                child: avatarUrl == null
                    ? Text(
                        Formatters.initials(name),
                        style: AppTypography.h2.copyWith(
                          color: AppColors.background,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name
          GestureDetector(
            onDoubleTap: () => ref.read(connectivityProvider.notifier).toggle(),
            child: Text(name, style: AppTypography.h2),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),

          // Role + subscription badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Suscripción activa  ·  ${role.displayName}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(label, style: AppTypography.label),
    );
  }
}

// ─────────────────────────────────────────────
// MENU SECTION
// ─────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.onTap,
  });
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _MenuTile(item: items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                color: AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final iconColor = item.iconColor ?? AppColors.accent;
    final textColor = item.textColor ?? AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 18, color: iconColor),
            ),
            title: Text(
              item.label,
              style: AppTypography.body.copyWith(color: textColor),
            ),
            subtitle: item.subtitle != null
                ? Text(
                    item.subtitle!,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: item.trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: item.onTap != null
                      ? AppColors.textHint
                      : Colors.transparent,
                ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EDIT ADDRESS BOTTOM SHEET
// ─────────────────────────────────────────────

class _EditAddressSheet extends ConsumerStatefulWidget {
  final String? currentAddress;

  const _EditAddressSheet({this.currentAddress});

  @override
  ConsumerState<_EditAddressSheet> createState() => _EditAddressSheetState();
}

class _EditAddressSheetState extends ConsumerState<_EditAddressSheet> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentAddress);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      // TODO: call user service to persist address
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ErrorSnackBar.show(context, message: 'No se pudo guardar la dirección.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Mi dirección', style: AppTypography.h3),
            const SizedBox(height: 4),
            Text(
              'Esta es la dirección donde recibes el servicio.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 20),

            CustomTextField(
              label: 'Dirección',
              hint: 'Ej: Cra 45 #32-10, Medellín',
              controller: _controller,
              prefixIcon: Icons.home_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'La dirección es obligatoria';
                }
                if (v.trim().length < 5) {
                  return 'Ingresa una dirección completa';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            CustomButton(
              label: 'Guardar dirección',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GUEST VIEW
// ─────────────────────────────────────────────

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(24, topPadding + 64, 24, 48),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.whiteSubtle),
                          boxShadow: AppColors.shadowHigh,
                        ),
                        child: const Icon(
                          Icons.person_add_outlined,
                          size: 48,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Únete a la comunidad',
                        style: AppTypography.h1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Inicia sesión para personalizar tus rutas, recibir alertas inteligentes y mucho más.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      CustomButton(
                        label: 'Iniciar Sesión ahora',
                        onPressed: () => context.pushNamed(AppRoutes.login),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '¿No tienes cuenta? Regístrate',
                          style: AppTypography.buttonSmall.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _SectionLabel(label: 'EXPLORA MÁS'),
              ),
              SliverToBoxAdapter(
                child: _MenuSection(
                  items: [
                    _MenuItem(
                      icon: Icons.campaign_outlined,
                      label: 'Avisos municipales',
                      onTap: () => context.pushNamed(AppRoutes.announcements),
                    ),
                    _MenuItem(
                      icon: Icons.help_outline,
                      label: 'Centro de ayuda',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.info_outline,
                      label: 'Acerca de Urbus',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Urbus',
                          applicationVersion: '1.0.0',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
    );
  }
}
