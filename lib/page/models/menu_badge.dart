import 'package:flutter/material.dart';

/// Badge configuration for menu cards.
///
/// Use predefined constants for common badges (beta, on, off) or create
/// custom badges with specific labels and colors via factory constructors.
class MenuBadge {
  final String label;
  final Color? color;
  final Color? textColor;

  const MenuBadge({
    required this.label,
    this.color,
    this.textColor,
  });

  /// Predefined badge for beta features.
  static const beta = MenuBadge(label: 'BETA');

  /// Predefined badge for enabled status.
  static const on = MenuBadge(label: 'On');

  /// Predefined badge for disabled status.
  static const off = MenuBadge(label: 'Off');

  /// Creates a success-styled badge (green).
  factory MenuBadge.success(String label) => MenuBadge(
        label: label,
        color: Colors.green,
      );

  /// Creates a warning-styled badge (orange).
  factory MenuBadge.warning(String label) => MenuBadge(
        label: label,
        color: Colors.orange,
      );

  /// Creates an info-styled badge (blue).
  factory MenuBadge.info(String label) => MenuBadge(
        label: label,
        color: Colors.blue,
      );

  /// Creates a badge showing a count.
  factory MenuBadge.count(int count) => MenuBadge(label: '$count');
}
