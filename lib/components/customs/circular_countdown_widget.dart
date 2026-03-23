import 'package:flutter/material.dart';

/// Circular countdown progress indicator.
///
/// Displays a circular arc that decreases as [remainingSeconds] approaches zero,
/// with optional center [child] (typically formatted time text).
/// The state is externally driven (by PnpNotifier), NOT by an internal timer.
class CircularCountdownWidget extends StatelessWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const CircularCountdownWidget({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.size = 160,
    this.strokeWidth = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: colorScheme.surfaceContainerHighest,
            ),
          ),
          // Foreground progress
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              color: colorScheme.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Center content
          if (child != null) child!,
        ],
      ),
    );
  }

  /// Format seconds as "mm:ss".
  static String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
