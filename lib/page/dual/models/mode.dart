import 'package:flutter/widgets.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

enum DualWANMode {
  failover,
  loadBalanced;

  String toDisplayString(BuildContext context) {
    return switch (this) {
      DualWANMode.failover => loc(context).dualWanFailover,
      DualWANMode.loadBalanced => loc(context).dualWanLoadBalancing,
    };
  }

  static DualWANMode fromValue(DualWANModeData value) {
    return DualWANMode.values.firstWhere((e) => e.name == value.name,
        orElse: () => DualWANMode.failover);
  }

  String toValue() {
    return switch (this) {
      DualWANMode.failover => 'Fail Over',
      DualWANMode.loadBalanced => 'Load Balanced',
    };
  }
}
