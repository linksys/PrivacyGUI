import 'package:flutter/widgets.dart';


import 'package:privacy_gui/localization/localization_hook.dart';

enum DualWANLogType {
  all,
  failover,
  throughput,
  speed,
  uptime;

  static DualWANLogType fromValue(String value) {
    return DualWANLogType.values.firstWhere((e) => e.name == value);
  }

  String toValue() {
    return switch (this) {
      DualWANLogType.all => 'all',
      DualWANLogType.failover => 'failover',
      DualWANLogType.throughput => 'throughput',
      DualWANLogType.speed => 'speed',
      DualWANLogType.uptime => 'uptime',
    };
  }

  String getFilterDisplayString(BuildContext context) {
    switch (this) {
      case DualWANLogType.all:
        return loc(context).allLogs;
      case DualWANLogType.failover:
        return loc(context).failoverEvents;
      case DualWANLogType.throughput:
        return loc(context).throughputData;
      case DualWANLogType.speed:
        return loc(context).speedTests;
      case DualWANLogType.uptime:
        return loc(context).uptimeRecords;
    }
  }

  String getDisplayString(BuildContext context) {
    switch (this) {
      case DualWANLogType.all:
        return loc(context).all;
      case DualWANLogType.failover:
        return loc(context).failover;
      case DualWANLogType.throughput:
        return loc(context).throughput;
      case DualWANLogType.speed:
        return loc(context).speed;
      case DualWANLogType.uptime:
        return loc(context).uptime;
    }
  }
}


