import 'package:flutter/material.dart';


import 'package:privacy_gui/localization/localization_hook.dart';

enum DualWANLogLevel {
  none,
  error,
  warning,
  info,
  ;

  static DualWANLogLevel fromValue(String value) {
    return DualWANLogLevel.values.firstWhere((e) => e.name == value);
  }

  String toValue() {
    return switch (this) {
      DualWANLogLevel.none => 'none',
      DualWANLogLevel.error => 'error',
      DualWANLogLevel.warning => 'warning',
      DualWANLogLevel.info => 'info',
    };
  }

  String? getDisplayString(BuildContext context) {
    switch (this) {
      case DualWANLogLevel.none:
        return null;
      case DualWANLogLevel.error:
        return loc(context).errors;
      case DualWANLogLevel.warning:
        return loc(context).warnings;
      case DualWANLogLevel.info:
        return loc(context).info;
    }
  }

  String? getLabelDisplayString(BuildContext context) {
    switch (this) {
      case DualWANLogLevel.none:
        return null;
      case DualWANLogLevel.error:
        return 'ERROR';
      case DualWANLogLevel.warning:
        return 'WARNING';
      case DualWANLogLevel.info:
        return 'INFO';
    }
  }

  Color getColor() {
    switch (this) {
      case DualWANLogLevel.none:
        return Colors.grey;
      case DualWANLogLevel.error:
        return Colors.red;
      case DualWANLogLevel.warning:
        return Colors.orange;
      case DualWANLogLevel.info:
        return Colors.blue;
    }
  }

  IconData getIcon() {
    switch (this) {
      case DualWANLogLevel.none:
        return Icons.info;
      case DualWANLogLevel.error:
        return Icons.cancel;
      case DualWANLogLevel.warning:
        return Icons.warning;
      case DualWANLogLevel.info:
        return Icons.check_circle;
    }
  }
}
