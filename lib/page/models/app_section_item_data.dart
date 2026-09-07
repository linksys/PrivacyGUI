import 'package:flutter/material.dart';
import 'package:privacy_gui/page/models/menu_badge.dart';

/// Data model for menu section items.
///
/// This is a local replacement for the privacygui_widgets AppSectionItemData,
/// used in dashboard menu and other grid-based menu views.
class AppSectionItemData {
  final IconData? iconData;
  final String title;
  final String? description;
  final List<MenuBadge> badges;
  final bool disabledOnBridge;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Stable E2E test hook, mapped to the `flt-semantics-identifier` DOM attr
  /// (silent to screen readers). Prefer this over [semanticLabel] for test
  /// slugs so the accessible name stays the localized card title.
  final String? identifier;

  const AppSectionItemData({
    this.iconData,
    required this.title,
    this.description,
    this.onTap,
    this.badges = const [],
    this.disabledOnBridge = false,
    this.semanticLabel,
    this.identifier,
  });
}
