import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

// Re-export core wifi utilities for convenience
// Note: formatSpeed is in NetworkUtils, not here
export 'package:privacy_gui/core/utils/wifi.dart'
    show
        rcpiToRssi,
        rssiToRcpi,
        getWifiSignalLevel,
        NodeSignalLevel,
        signalThresholdRSSI,
        rssiExcellent,
        rssiGood,
        rssiFair,
        SignalTier,
        getSignalTier,
        computeSNR,
        normalizeSNR;

/// UI utilities for WiFi signal display.
class WiFiUtils {
  static IconData getWifiSignalIconData(
      BuildContext context, int? signalStrength) {
    switch (getWifiSignalLevel(signalStrength)) {
      case NodeSignalLevel.excellent:
        return AppFontIcons.signalWifi4Bar;
      case NodeSignalLevel.good:
        return AppFontIcons.networkWifi3Bar;
      case NodeSignalLevel.fair:
        return AppFontIcons.networkWifi2Bar;
      case NodeSignalLevel.poor:
        return AppFontIcons.networkWifi1Bar;
      case NodeSignalLevel.none:
        return AppFontIcons.signalWifi0Bar;
      case NodeSignalLevel.wired:
        return AppFontIcons.ethernet;
    }
  }
}

/// UI extensions for [NodeSignalLevel].
extension NodeSignalLevelExt on NodeSignalLevel {
  String resolveLabel(BuildContext context) {
    return switch (this) {
      NodeSignalLevel.excellent => loc(context).excellent,
      NodeSignalLevel.good => loc(context).good,
      NodeSignalLevel.poor => loc(context).poor,
      NodeSignalLevel.fair => loc(context).fair,
      NodeSignalLevel.wired => loc(context).wired,
      NodeSignalLevel.none => '',
    };
  }

  Color? resolveColor(BuildContext context) {
    final appColorScheme = Theme.of(context).extension<AppColorScheme>();
    return switch (this) {
      NodeSignalLevel.excellent =>
        appColorScheme?.semanticSuccess ?? Colors.green,
      NodeSignalLevel.good => appColorScheme?.semanticSuccess ?? Colors.green,
      NodeSignalLevel.poor => Theme.of(context).colorScheme.error,
      NodeSignalLevel.fair => Theme.of(context).colorScheme.error,
      NodeSignalLevel.wired => Theme.of(context).colorScheme.onSurface,
      NodeSignalLevel.none => Colors.black,
    };
  }
}

// ─── SignalTier UI helpers ──────────────────────────────────────────────────

/// UI extensions for [SignalTier] (performance analytics).
extension SignalTierExt on SignalTier {
  /// Localized tier label for display in the View layer.
  String resolveLabel(BuildContext context) => switch (this) {
        SignalTier.excellent => loc(context).excellent,
        SignalTier.good => loc(context).good,
        SignalTier.fair => loc(context).fair,
        SignalTier.weak => loc(context).weak,
      };

  /// Tier-appropriate color from the current color scheme.
  Color resolveColor(ColorScheme cs) => switch (this) {
        SignalTier.excellent => cs.primary,
        SignalTier.good => cs.tertiary,
        SignalTier.fair => Colors.orange,
        SignalTier.weak => cs.error,
      };
}

/// Bar color based on RSSI value.
Color rssiColor(int rssi, ColorScheme cs) =>
    getSignalTier(rssi).resolveColor(cs);

/// Localizes device/firmware WiFi values that are plain UI words, for DISPLAY
/// only. The original value is still used as the stored value / map key by
/// callers; technical tokens (WPA2-Personal, 20MHz, 802.11..., channel numbers)
/// are returned unchanged.
String wifiDisplayValue(BuildContext context, String value) {
  switch (value) {
    case 'Auto':
      return loc(context).auto;
    case 'None':
      return loc(context).none;
    case 'Mixed':
      return loc(context).mixed;
    default:
      return value;
  }
}
