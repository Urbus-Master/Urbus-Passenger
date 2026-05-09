import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────
  static const Color background    = Color(0xFF0A0E12);
  static const Color surface       = Color(0xFF161B22);
  static const Color surfaceLight  = Color(0xFF21262D);
  static const Color surfaceHigh   = Color(0xFF2D333B);

  // ── Accent (teal eléctrico) ──────────────────────────────────
  static const Color accent        = Color(0xFF2F81F7);
  static const Color accentDark    = Color(0xFF1A6DD4);
  static const Color accentMedium  = Color(0xFF1F4D95);
  static const Color accentDisabled = Color(0xFF1A3A6B);
  static const Color accentSubtle  = Color(0x1A2F81F7); // 10% opacity
  static const Color accentMid     = Color(0x332F81F7); // 20% opacity

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textHint      = Color(0xFF484F58);
  static const Color textDisabled  = Color(0xFF30363D);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color success       = Color(0xFF3FB950);
  static const Color successSubtle = Color(0x1A3FB950);
  static const Color warning       = Color(0xFFD29922);
  static const Color warningSubtle = Color(0x1AD29922);
  static const Color error         = Color(0xFFF85149);
  static const Color errorSubtle   = Color(0x1AF85149);
  static const Color info          = Color(0xFF58A6FF);
  static const Color infoSubtle    = Color(0x1A58A6FF);

  // ── Borders ──────────────────────────────────────────────────
  static const Color border        = Color(0xFF30363D);
  static const Color borderActive  = Color(0xFF58A6FF);

  // ── Map ──────────────────────────────────────────────────────
  static const Color mapRoute          = Color(0xFF2F81F7);
  static const Color mapRouteCompleted = Color(0xFF3FB950);

  // ── Glassmorphism ───────────────────────────────────────────
  static const Color glassSurface  = Color(0xCC161B22); // 80% surface
  static const Color glassBorder   = Color(0x33FFFFFF); // 20% white
  
  // ── Shadows ──────────────────────────────────────────────────
  static List<BoxShadow> get shadowLow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowHigh => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ];

  // ── Misc ─────────────────────────────────────────────────────
  static const Color shimmer       = Color(0xFF21262D);
  static const Color overlay       = Color(0x80000000);
  static const Color whiteSubtle   = Color(0x0FFFFFFF);
}
