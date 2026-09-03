import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Design constants for layout blocks.
///
/// Centralizes alpha values, border radius, and padding to ensure
/// visual consistency across all block components.
abstract final class BlockConstants {
  // ---------------------------------------------------------------------------
  // Alpha values for transparency
  // ---------------------------------------------------------------------------

  /// Block background alpha (surfaceContainerHighest)
  static const double backgroundAlpha = 0.5;

  /// Badge/icon tinted background alpha
  static const double badgeBackgroundAlpha = 0.15;

  /// Alert banner background alpha
  static const double bannerBackgroundAlpha = 0.1;

  /// Border/outline alpha
  static const double borderAlpha = 0.2;

  /// Disabled/muted element alpha — the *colour* case only (a muted icon, a
  /// muted label). Dimming a whole subtree is `AppLowEmphasis`, which is
  /// per-language and cannot be expressed as a number here.
  static const double disabledAlpha = AppStateTokens.disabledLabelAlpha;

  // ---------------------------------------------------------------------------
  // Border radius
  // ---------------------------------------------------------------------------

  /// Standard block border radius
  static const double borderRadius = AppSpacing.sm;

  // ---------------------------------------------------------------------------
  // Padding presets
  // ---------------------------------------------------------------------------

  /// Compact padding (status indicators, badges)
  static const EdgeInsets paddingSm = EdgeInsets.all(AppSpacing.sm);

  /// Standard padding (most blocks)
  static const EdgeInsets paddingMd = EdgeInsets.all(AppSpacing.md);

  /// Spacious padding (highlight values, hero blocks)
  static const EdgeInsets paddingLg = EdgeInsets.all(AppSpacing.lg);

  /// Horizontal list item padding
  static const EdgeInsets paddingListItem = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );

  // ---------------------------------------------------------------------------
  // Icon sizes
  // ---------------------------------------------------------------------------

  /// Small icon (inline with text)
  static const double iconSm = 16.0;

  /// Medium icon (list items, badges)
  static const double iconMd = 20.0;

  /// Large icon (feature icons, empty states)
  static const double iconLg = 24.0;

  /// Extra large icon (empty state hero)
  static const double iconXl = 48.0;
}
