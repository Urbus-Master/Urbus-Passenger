import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/tracking_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/map_widget.dart';
import '../widgets/bottom_sheet_card.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with WidgetsBindingObserver {
  final PanelController _panelController = PanelController();
  bool _isPanelOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialise location after the first frame — avoids blocking the UI.
    Future.microtask(
      () => ref.read(locationProvider.notifier).initialise(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check GPS when app comes back to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: 140,
        maxHeight: screenHeight * 0.75,
        backdropEnabled: true,
        backdropOpacity: 0.2,
        renderPanelSheet: false, // Permite que el panel sea flotante
        color: Colors.transparent,

        onPanelSlide: (position) {
          final isOpen = position > 0.5;
          if (isOpen != _isPanelOpen) {
            setState(() => _isPanelOpen = isOpen);
          }
        },

        // ── Collapsed header — always visible ────────────────
        collapsed: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: AppColors.shadowHigh,
            ),
            child: _CollapsedHeader(
              panelController: _panelController,
              isPanelOpen: _isPanelOpen,
            ),
          ),
        ),

        // ── Expanded panel body ──────────────────────────────
        panel: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: AppColors.shadowHigh,
            ),
            child: BottomSheetCard(
              panelController: _panelController,
            ),
          ),
        ),

        // ── Map — fills remaining space ──────────────────────
        body: Stack(
          children: [
            // Full-screen map
            const MapWidget(),

            // Top bar gradient + controls
            _TopBar(topPadding: topPadding),

            // GPS error banner
            if (ref.watch(locationProvider).value?.hasError ?? false)
              _GpsErrorBanner(
                message: ref.watch(locationProvider).value!.errorMessage!,
                onRetry: () =>
                    ref.read(locationProvider.notifier).refresh(),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final double topPadding;

  const _TopBar({required this.topPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == ConnectionStatus.connected;
    final isReconnecting = connectionStatus == ConnectionStatus.reconnecting;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: topPadding + 72,
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.4),
          border: Border(
            bottom: BorderSide(color: AppColors.whiteSubtle),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: AppColors.background.withValues(alpha: 0.3),
              padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 0),
              child: Row(
                children: [
                  // ── Hamburger ──────────────────────────────────
                  _TopBarButton(
                    icon: Icons.menu_rounded,
                    onTap: () => Scaffold.of(context).openDrawer(),
                  ),

                  const Spacer(),

                  // ── App name + live indicator ───────────────────
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Urbus', style: AppTypography.h3),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? AppColors.success
                                  : isReconnecting
                                      ? AppColors.warning
                                      : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isConnected
                                ? 'En vivo'
                                : isReconnecting
                                    ? 'Reconectando...'
                                    : 'Sin conexión',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Notifications ───────────────────────────────
                  _NotificationButton(),
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
// TOP BAR BUTTON
// ─────────────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NOTIFICATION BUTTON
// ─────────────────────────────────────────────

class _NotificationButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Unread alerts count drives the badge.
    final unreadCount = ref.watch(trackingProvider
        .select((s) => 0)); // replace with alertsProvider when wired

    return Semantics(
      button: true,
      label: 'Notificaciones',
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/alerts'),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      Formatters.badgeCount(unreadCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// COLLAPSED HEADER
// ─────────────────────────────────────────────

class _CollapsedHeader extends ConsumerWidget {
  final PanelController panelController;
  final bool isPanelOpen;

  const _CollapsedHeader({
    required this.panelController,
    required this.isPanelOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final activeUnit = ref.watch(activeUnitProvider);
    final etaFormatted = ref.watch(etaFormattedProvider);

    return SizedBox(
      width: screenWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => isPanelOpen
                  ? panelController.close()
                  : panelController.open(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isPanelOpen ? 48 : 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isPanelOpen
                      ? AppColors.accent.withValues(alpha: 0.6)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ETA row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // ── ETA left ─────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIEMPO DE LLEGADA',
                      style: AppTypography.label,
                    ),
                    const SizedBox(height: 2),
                    Text(etaFormatted, style: AppTypography.etaSmall),
                    Text(
                      'minutos',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),

                const Spacer(),

                // ── Unit info right ───────────────────────────
                if (activeUnit != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          color: AppColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Formatters.unitLabel(activeUnit.unitNumber),
                          style: AppTypography.h3,
                        ),
                      ],
                    ),
                  )
                else
                  _NoUnitChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NO UNIT CHIP
// ─────────────────────────────────────────────

class _NoUnitChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Buscando unidad...',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GPS ERROR BANNER
// ─────────────────────────────────────────────

class _GpsErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GpsErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 80,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_off_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Reintentar',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
