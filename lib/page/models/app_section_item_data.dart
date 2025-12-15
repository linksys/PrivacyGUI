import 'package:flutter/material.dart';

/// Data model for menu section items.
///
/// This is a local replacement for the privacygui_widgets AppSectionItemData,
/// used in dashboard menu and other grid-based menu views.
class AppSectionItemData {
  final IconData? iconData;
  final String title;
  final String? description;
  final bool? status;
  final bool isBeta;
  final bool disabledOnBridge;
  final VoidCallback? onTap;

  const AppSectionItemData({
    this.iconData,
    required this.title,
    this.description,
    this.onTap,
    this.status,
    this.isBeta = false,
    this.disabledOnBridge = false,
  });
}
