import 'package:flutter/material.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_status.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

import 'package:privacy_gui/localization/localization_hook.dart';

enum DualWANConnection {
  connected('Connected'),
  disconnected('Disconnected'),
  active('Active'),
  standby('Standby');

  final String value;

  const DualWANConnection(this.value);

  static DualWANConnection fromValue(DualWANConnectionStatusData value) {
    return DualWANConnection.values.firstWhere((e) => e.value == value.value,
        orElse: () => DualWANConnection.disconnected);
  }

  String toDisplayString(BuildContext context) {
    return switch (this) {
      DualWANConnection.connected => loc(context).dualWanConnectionConnected,
      DualWANConnection.disconnected =>
        loc(context).dualWanConnectionDisconnected,
      DualWANConnection.active => loc(context).dualWanConnectionActive,
      DualWANConnection.standby => loc(context).dualWanConnectionStandby,
    };
  }

  Color resolveLabelColor(BuildContext context) {
    return switch (this) {
          DualWANConnection.connected => Theme.of(context).colorSchemeExt.green,
          DualWANConnection.disconnected => Theme.of(context).colorScheme.error,
          DualWANConnection.active => Theme.of(context).colorScheme.primary,
          DualWANConnection.standby => Theme.of(context).colorSchemeExt.orange,
        } ??
        Theme.of(context).colorScheme.outline;
  }
}
