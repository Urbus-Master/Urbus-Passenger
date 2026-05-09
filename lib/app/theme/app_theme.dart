import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(primary: AppColors.accent, surface: AppColors.surface),
    useMaterial3: true,
  );
}
