import 'package:flutter/widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

enum DualWANMode {
  failover,
  loadBalancing;

  String toDisplayString(BuildContext context) {
    return switch (this) {
      DualWANMode.failover => loc(context).dualWanFailover,
      DualWANMode.loadBalancing => loc(context).dualWanLoadBalancing,
    };
  }

  static DualWANMode fromValue(String value) {
    return DualWANMode.values
        .firstWhere((e) => e.name == value, orElse: () => DualWANMode.failover);
  }
  
  String toValue() {
    return switch (this) {
      DualWANMode.failover => 'failover',
      DualWANMode.loadBalancing => 'loadBalancing',
    };
  }
}
