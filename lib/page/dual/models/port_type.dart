
import 'package:flutter/material.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

enum PortType {
  wan1,
  wan2,
  lan;

  String toDisplayString() {
    return switch (this) {
      PortType.wan1 => 'WAN1',
      PortType.wan2 => 'WAN2',
      PortType.lan => 'LAN',
    };
  }

  static PortType fromValue(String value) {
    return PortType.values
        .firstWhere((e) => e.name == value, orElse: () => PortType.wan1);
  }

  String toValue() {
    return switch (this) {
      PortType.wan1 => 'wan1',
      PortType.wan2 => 'wan2',
      PortType.lan => 'lan',
    };
  }

  bool isWan() {
    return this == PortType.wan1 || this == PortType.wan2;
  }

  Color getDisplayColor(BuildContext context) {
    return switch (this) {
      PortType.wan1 => Theme.of(context).colorScheme.primary,
      PortType.wan2 => Theme.of(context).colorSchemeExt.green ?? Colors.green,
      PortType.lan => Theme.of(context).colorScheme.outline,
    };
  }
}
