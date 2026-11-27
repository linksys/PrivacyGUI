import 'package:flutter/widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';

/// The level of a WiFi signal reading in words, for a diagnostics result that
/// shows it beside its dBm. A reading of 0 is no reading, which
/// [NodeSignalLevelExt.resolveLabel] leaves blank, so it reads "No signal"
/// here (#1778: these used `NodeSignalLevel.displayTitle`, which is English).
String diagnosticsSignalLevelLabel(BuildContext context, int dbm) {
  final level = getWifiSignalLevel(dbm);
  return level == NodeSignalLevel.none
      ? loc(context).diagnosticsNoSignal
      : level.resolveLabel(context);
}
