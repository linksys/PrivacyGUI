import 'package:flutter/material.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

import 'package:privacy_gui/localization/localization_hook.dart';

enum DualWANConnection {
  connected,
  disconnected,
  active;

  static DualWANConnection fromValue(String value) {
    return DualWANConnection.values.firstWhere((e) => e.name == value,
        orElse: () => DualWANConnection.disconnected);
  }

  String toDisplayString(BuildContext context) {
    return switch (this) {
      DualWANConnection.connected => loc(context).dualWanConnectionConnected,
      DualWANConnection.disconnected => loc(context).dualWanConnectionDisconnected,
      DualWANConnection.active => loc(context).dualWanConnectionActive,
    };
  }

  Color resolveLabelColor(BuildContext context) {
    return switch (this) {
          DualWANConnection.connected => Theme.of(context).colorSchemeExt.green,
          DualWANConnection.disconnected => Theme.of(context).colorScheme.error,
          DualWANConnection.active => Theme.of(context).colorScheme.primary,
        } ??
        Theme.of(context).colorScheme.outline;
  }
}
