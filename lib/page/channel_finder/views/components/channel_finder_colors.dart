import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi_channel.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The colour of a channel's busyness, the same on the chart, the channel rows,
/// the page's band summaries and the dashboard card (#1778). Theme colours
/// only:
/// - at or above [busyChannelUtilization] (50 %): the theme's warning colour,
///   the severity the diagnostics congestion step gives it. Busy wins over in
///   use, so a busy channel the radio is on reads as busy;
/// - the channel the radio is on: the primary colour;
/// - any other channel, or one with no reading: the outline colour.
Color channelBusynessColor(
  BuildContext context, {
  required int? utilization,
  required bool isInUse,
}) {
  final theme = Theme.of(context);
  if (isBusyUtilization(utilization)) {
    return channelBusyColor(context);
  }
  if (utilization != null && isInUse) return theme.colorScheme.primary;
  return theme.colorScheme.outline;
}

/// The colour of a channel at or above [busyChannelUtilization]: the theme's
/// semantic warning colour, or its error colour where a theme has no
/// [AppColorScheme].
Color channelBusyColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.extension<AppColorScheme>()?.semanticWarning ??
      theme.colorScheme.error;
}
