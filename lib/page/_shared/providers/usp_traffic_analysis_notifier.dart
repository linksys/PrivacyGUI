import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/multi_interface_traffic_stats.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';

/// Multi-interface traffic analysis provider — compares WAN vs LAN traffic
/// with timer-based polling. NOT autoDispose so history persists across tab
/// switches.
final uspTrafficAnalysisProvider =
    NotifierProvider<UspTrafficAnalysisNotifier, TrafficAnalysisState>(
  UspTrafficAnalysisNotifier.new,
);

class UspTrafficAnalysisNotifier extends Notifier<TrafficAnalysisState> {
  Timer? _timer;

  @override
  TrafficAnalysisState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    // Gate polling start on domain providers completing their first fetch.
    // This prevents traffic stats requests from competing for throttler slots
    // during the initial domain data load phase.
    const defaultInterval = Duration(seconds: 5);
    ref.listen(dashboardDomainReadyProvider, (_, next) {
      if (next is AsyncData) {
        setRefreshInterval(defaultInterval);
      }
    });

    return const TrafficAnalysisState(
      refreshInterval: defaultInterval,
    );
  }

  /// Set the auto-refresh interval. Pass null to stop.
  void setRefreshInterval(Duration? interval) {
    _timer?.cancel();
    _timer = null;

    state = state.copyWith(
      refreshInterval: () => interval,
    );

    if (interval != null) {
      _fetchAndAppend();
      _timer = Timer.periodic(interval, (_) => _fetchAndAppend());
    }
  }

  /// Manual one-shot fetch.
  Future<void> fetchNow() => _fetchAndAppend();

  Future<void> _fetchAndAppend() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null || !usp.isAuthenticated) return;

    state = state.copyWith(isFetching: true);
    try {
      final stats = await MultiInterfaceTrafficStats.fetch(usp);
      final now = DateTime.now();

      final currentBaselines = {
        TrafficInterface.wan: InterfaceBaseline(
          bytesSent: stats.wanBytesSent,
          bytesReceived: stats.wanBytesReceived,
          packetsSent: stats.wanPacketsSent,
          packetsReceived: stats.wanPacketsReceived,
          errorsSent: stats.wanErrorsSent,
          errorsReceived: stats.wanErrorsReceived,
          discardsSent: stats.wanDiscardPacketsSent,
          discardsReceived: stats.wanDiscardPacketsReceived,
        ),
        TrafficInterface.lan: InterfaceBaseline(
          bytesSent: stats.lanBytesSent,
          bytesReceived: stats.lanBytesReceived,
          packetsSent: stats.lanPacketsSent,
          packetsReceived: stats.lanPacketsReceived,
          errorsSent: stats.lanErrorsSent,
          errorsReceived: stats.lanErrorsReceived,
          discardsSent: stats.lanDiscardPacketsSent,
          discardsReceived: stats.lanDiscardPacketsReceived,
        ),
      };

      // First fetch: set baseline only, no rate to compute yet
      if (state.lastBaselines == null || state.lastTimestamp == null) {
        state = state.copyWith(
          isFetching: false,
          lastBaselines: () => currentBaselines,
          lastTimestamp: () => now,
        );
        return;
      }

      final elapsed = now.difference(state.lastTimestamp!).inMilliseconds;
      if (elapsed <= 0) {
        state = state.copyWith(isFetching: false);
        return;
      }

      final seconds = elapsed / 1000.0;
      final snapshot = MultiInterfaceSnapshot(
        timestamp: now,
        interfaces: {
          for (final iface in TrafficInterface.values)
            iface: _computeRates(
              current: currentBaselines[iface]!,
              previous: state.lastBaselines![iface]!,
              seconds: seconds,
              stats: stats,
              iface: iface,
            ),
        },
      );

      state = state.copyWith(
        history: _appendToRingBuffer(state.history, snapshot),
        isFetching: false,
        lastBaselines: () => currentBaselines,
        lastTimestamp: () => now,
      );
    } catch (e) {
      logger.w('[USP][Monitor][Traffic]Fetch failed: $e');
      state = state.copyWith(isFetching: false);
    }
  }

  InterfaceTrafficSnapshot _computeRates({
    required InterfaceBaseline current,
    required InterfaceBaseline previous,
    required double seconds,
    required MultiInterfaceTrafficStats stats,
    required TrafficInterface iface,
  }) {
    // Counter wraparound protection: negative delta → treat as 0
    final deltaSent = current.bytesSent - previous.bytesSent;
    final deltaRecv = current.bytesReceived - previous.bytesReceived;
    final deltaPktSent = current.packetsSent - previous.packetsSent;
    final deltaPktRecv = current.packetsReceived - previous.packetsReceived;

    // Error/discard deltas
    final deltaErrSent = current.errorsSent - previous.errorsSent;
    final deltaErrRecv = current.errorsReceived - previous.errorsReceived;
    final deltaDiscSent = current.discardsSent - previous.discardsSent;
    final deltaDiscRecv = current.discardsReceived - previous.discardsReceived;

    return InterfaceTrafficSnapshot(
      uploadBytesPerSec: deltaSent >= 0 ? (deltaSent / seconds) : 0,
      downloadBytesPerSec: deltaRecv >= 0 ? (deltaRecv / seconds) : 0,
      uploadPacketsPerSec: deltaPktSent >= 0 ? (deltaPktSent / seconds) : 0,
      downloadPacketsPerSec: deltaPktRecv >= 0 ? (deltaPktRecv / seconds) : 0,
      totalBytesSent: current.bytesSent,
      totalBytesReceived: current.bytesReceived,
      totalPacketsSent: current.packetsSent,
      totalPacketsReceived: current.packetsReceived,
      errorsSentPerSec: deltaErrSent >= 0 ? (deltaErrSent / seconds) : 0,
      errorsReceivedPerSec: deltaErrRecv >= 0 ? (deltaErrRecv / seconds) : 0,
      discardsSentPerSec: deltaDiscSent >= 0 ? (deltaDiscSent / seconds) : 0,
      discardsReceivedPerSec:
          deltaDiscRecv >= 0 ? (deltaDiscRecv / seconds) : 0,
      totalErrorsSent: current.errorsSent,
      totalErrorsReceived: current.errorsReceived,
      totalDiscardsSent: current.discardsSent,
      totalDiscardsReceived: current.discardsReceived,
    );
  }

  List<MultiInterfaceSnapshot> _appendToRingBuffer(
    List<MultiInterfaceSnapshot> list,
    MultiInterfaceSnapshot item,
  ) {
    final updated = [...list, item];
    if (updated.length > TrafficAnalysisState.maxHistory) {
      return updated.sublist(updated.length - TrafficAnalysisState.maxHistory);
    }
    return updated;
  }
}
