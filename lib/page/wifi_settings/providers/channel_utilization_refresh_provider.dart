import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

/// How often the Channels tab re-reads channel utilization: DataElements
/// collects it every 60 s (`CollectionInterval` = 60000 on FW 2.0.4), so a
/// shorter period returns nothing new (#1295).
const channelUtilizationRefreshInterval = Duration(seconds: 60);

/// While the WiFi Performance card's Channels tab is on screen, re-reads each
/// radio's channel utilization: once when it opens, then every
/// [channelUtilizationRefreshInterval] (#1295).
///
/// A timer, not a data provider: it holds nothing, and the readings land in
/// [wifiDataProvider] through [WifiDataNotifier.refreshUtilization]. That is
/// why it is autoDispose while `wifiDataProvider` (L1) is not, and why it has
/// its own file. It is watched only by that tab, and the card builds only the
/// selected tab, so leaving the tab, or the dashboard, disposes this and stops
/// the timer — the lifecycle of `uspAppsProvider`'s poll.
final channelUtilizationRefreshProvider = Provider.autoDispose<void>((ref) {
  var disposed = false;
  void refresh() {
    if (disposed) return;
    unawaited(ref.read(wifiDataProvider.notifier).refreshUtilization());
  }

  Future.microtask(refresh);
  final timer =
      Timer.periodic(channelUtilizationRefreshInterval, (_) => refresh());
  ref.onDispose(() {
    disposed = true;
    timer.cancel();
  });
});
