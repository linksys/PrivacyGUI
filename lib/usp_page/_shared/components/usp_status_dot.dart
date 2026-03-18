import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Themed status dot for USP Dashboard.
///
/// Uses [AppBreathDot] with pulse animation for active items
/// and a static dot for inactive items. Colors are resolved
/// from [AppColorScheme] semantic tokens.
class UspStatusDot extends StatelessWidget {
  final bool isActive;
  final double size;

  const UspStatusDot({
    super.key,
    required this.isActive,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final successColor =
        Theme.of(context).extension<AppColorScheme>()?.semanticSuccess ??
            Colors.green;
    final inactiveColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return AppBreathDot(
      color: isActive ? successColor : inactiveColor,
      size: size,
      animation: isActive ? BreathDotAnimation.pulse : BreathDotAnimation.none,
    );
  }
}
