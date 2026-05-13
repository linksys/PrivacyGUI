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

  const AppSectionItemData({
    this.iconData,
    required this.title,
    this.description,
    this.onTap,
    this.badges = const [],
    this.disabledOnBridge = false,
    this.semanticLabel,
  });
}
