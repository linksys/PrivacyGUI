import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/wan_traffic_stats.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/dashboard/models/traffic_monitor_state.dart';

/// Traffic monitor provider — tracks WAN upload/download rate history with
/// optional auto-refresh timer. NOT autoDispose so history persists across
/// tab switches.
final uspTrafficMonitorProvider =
    NotifierProvider<UspTrafficMonitorNotifier, TrafficMonitorState>(
  UspTrafficMonitorNotifier.new,
);

class UspTrafficMonitorNotifier extends Notifier<TrafficMonitorState> {
  Timer? _timer;

  @override
  TrafficMonitorState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    // Auto-start with 2s default interval
    const defaultInterval = Duration(seconds: 2);
    Future.microtask(() => setRefreshInterval(defaultInterval));
    return const TrafficMonitorState(
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
      final stats = await WanTrafficStats.fetch(usp);
      final now = DateTime.now();

      // First fetch: set baseline only, no rate to compute yet
      if (state.lastBytesSent == null || state.lastTimestamp == null) {
        state = state.copyWith(
          isFetching: false,
          lastBytesSent: () => stats.bytesSent,
          lastBytesReceived: () => stats.bytesReceived,
          lastTimestamp: () => now,
        );
        return;
      }

      // Delta calculation
      final elapsed = now.difference(state.lastTimestamp!).inMilliseconds;
      if (elapsed <= 0) {
        state = state.copyWith(isFetching: false);
        return;
      }

      final deltaSent = stats.bytesSent - state.lastBytesSent!;
      final deltaRecv = stats.bytesReceived - state.lastBytesReceived!;
      final seconds = elapsed / 1000.0;

      final snapshot = TrafficSnapshot(
        timestamp: now,
        uploadBytesPerSec: (deltaSent / seconds).clamp(0, double.infinity),
        downloadBytesPerSec: (deltaRecv / seconds).clamp(0, double.infinity),
        totalBytesSent: stats.bytesSent,
        totalBytesReceived: stats.bytesReceived,
      );

      state = state.copyWith(
        history: _appendToRingBuffer(state.history, snapshot),
        isFetching: false,
        lastBytesSent: () => stats.bytesSent,
        lastBytesReceived: () => stats.bytesReceived,
        lastTimestamp: () => now,
      );
    } catch (e) {
      logger.w('[TrafficMonitor] Fetch failed: $e');
      state = state.copyWith(isFetching: false);
    }
  }

  List<TrafficSnapshot> _appendToRingBuffer(
    List<TrafficSnapshot> list,
    TrafficSnapshot item,
  ) {
    final updated = [...list, item];
    if (updated.length > TrafficMonitorState.maxHistory) {
      return updated.sublist(updated.length - TrafficMonitorState.maxHistory);
    }
    return updated;
  }
}
