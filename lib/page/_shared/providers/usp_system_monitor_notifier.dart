import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/services/usp_system_monitor_service.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';

/// System monitor provider — tracks CPU/Memory history with optional
/// auto-refresh timer. NOT autoDispose so history persists across tab switches.
final uspSystemMonitorProvider =
    NotifierProvider<UspSystemMonitorNotifier, SystemMonitorState>(
  UspSystemMonitorNotifier.new,
);

class UspSystemMonitorNotifier extends Notifier<SystemMonitorState> {
  Timer? _timer;

  @override
  SystemMonitorState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    const defaultInterval = Duration(seconds: 30);
    ref.listen(dashboardDomainReadyProvider, (_, next) {
      if (next is AsyncData) {
        setRefreshInterval(defaultInterval);
      }
    });

    return const SystemMonitorState(
      refreshInterval: defaultInterval,
    );
  }

  /// Push a snapshot from the dashboard notifier (avoids duplicate fetch).
  void pushSnapshot(SystemSnapshot snapshot) {
    state = state.copyWith(
      history: _appendToRingBuffer(state.history, snapshot),
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
    final svc = ref.read(uspSystemMonitorServiceProvider);
    if (svc == null || !svc.isAuthenticated) return;

    state = state.copyWith(isFetching: true);
    try {
      final snapshot = await svc.fetchSnapshot();
      state = state.copyWith(
        history: _appendToRingBuffer(state.history, snapshot),
        isFetching: false,
      );
    } catch (e) {
      logger.w('[USP][Monitor][System]: Fetch failed: $e');
      state = state.copyWith(isFetching: false);
    }
  }

  List<SystemSnapshot> _appendToRingBuffer(
    List<SystemSnapshot> list,
    SystemSnapshot item,
  ) {
    final updated = [...list, item];
    if (updated.length > SystemMonitorState.maxHistory) {
      return updated.sublist(updated.length - SystemMonitorState.maxHistory);
    }
    return updated;
  }
}
