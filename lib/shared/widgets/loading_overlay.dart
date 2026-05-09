import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Full-screen semi-transparent overlay that blocks user interaction while
/// an async operation is in progress.
///
/// Wrap the overlay over your page content using a [Stack]:
/// ```dart
/// Stack(
///   children: [
///     MyPageContent(),
///     if (isLoading) const LoadingOverlay(),
///     if (isLoading) const LoadingOverlay(message: 'Fetching route…'),
///   ],
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.message,
  });

  /// Optional label displayed below the spinner.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // IgnorePointer prevents taps/gestures from reaching widgets below.
      ignoring: false, // set to false so all events are absorbed
      child: Container(
        color: AppColors.overlay,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.accent),
                strokeWidth: 3,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
