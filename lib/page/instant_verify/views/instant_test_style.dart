import 'package:flutter/material.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

/// How a check, finding or device reads at a glance. Every Instant-Test
/// status color, tint and icon comes from here so the page follows the router
/// theme, including dark mode and a custom theme color.
enum InstantTestTone { good, warning, problem, info, neutral }

extension InstantTestToneStyle on InstantTestTone {
  /// Icon, dot and accent color.
  Color color(BuildContext context) {
    final theme = Theme.of(context);
    return switch (this) {
      InstantTestTone.good => theme.colorSchemeExt.green!,
      InstantTestTone.warning => theme.colorSchemeExt.orange!,
      InstantTestTone.problem => theme.colorScheme.error,
      InstantTestTone.info => theme.colorScheme.primary,
      InstantTestTone.neutral => theme.colorScheme.onSurfaceVariant,
    };
  }

  /// Tinted background for chips, banners and highlighted rows.
  Color container(BuildContext context) {
    final theme = Theme.of(context);
    return switch (this) {
      InstantTestTone.good => theme.colorSchemeExt.secondaryGreen!,
      InstantTestTone.warning => theme.colorSchemeExt.secondaryOrange!,
      InstantTestTone.problem => theme.colorScheme.errorContainer,
      InstantTestTone.info => theme.colorScheme.primaryContainer,
      InstantTestTone.neutral => theme.colorSchemeExt.surfaceContainerHigh!,
    };
  }

  /// Text and icons placed on [container].
  Color onContainer(BuildContext context) {
    final theme = Theme.of(context);
    return switch (this) {
      InstantTestTone.good => theme.colorSchemeExt.onSecondaryGreen!,
      InstantTestTone.warning => theme.colorSchemeExt.onSecondaryOrange!,
      InstantTestTone.problem => theme.colorScheme.onErrorContainer,
      InstantTestTone.info => theme.colorScheme.onPrimaryContainer,
      InstantTestTone.neutral => theme.colorScheme.onSurfaceVariant,
    };
  }

  IconData get icon => switch (this) {
        InstantTestTone.good => LinksysIcons.checkCircle,
        InstantTestTone.warning => LinksysIcons.error,
        InstantTestTone.problem => LinksysIcons.error,
        InstantTestTone.info => LinksysIcons.infoCircle,
        InstantTestTone.neutral => LinksysIcons.circle,
      };
}
