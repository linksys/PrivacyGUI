import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
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
  int _consecutiveErrors = 0;
  static const _errorThreshold = 3;

  @override
  SystemMonitorState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    ref.listen(appConnectionStateProvider, (_, next) {
      if (next != AppConnectionState.authenticated) {
        _timer?.cancel();
        _timer = null;
      } else if (_timer == null && state.refreshInterval != null) {
        setRefreshInterval(state.refreshInterval);
      }
    });

    const defaultInterval = Duration(seconds: 30);

    // Listen for future state changes
    ref.listen(dashboardDomainReadyProvider, (_, next) {
      if (next is AsyncData) {
        setRefreshInterval(defaultInterval);
      }
    });

    // Check if already ready (provider initialized after domain ready)
    final domainReady = ref.read(dashboardDomainReadyProvider);
    if (domainReady is AsyncData) {
      Future.microtask(() => setRefreshInterval(defaultInterval));
    }

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
    final connectionState = ref.read(appConnectionStateProvider);
    if (connectionState != AppConnectionState.authenticated) return;

    final svc = ref.read(uspSystemMonitorServiceProvider);
    if (svc == null) return;

    state = state.copyWith(isFetching: true);
    try {
      final snapshot = await svc.fetchSnapshot();
      _consecutiveErrors = 0;
      state = state.copyWith(
        history: _appendToRingBuffer(state.history, snapshot),
        isFetching: false,
      );
    } on ConnectivityError {
      _consecutiveErrors++;
      if (_consecutiveErrors >= _errorThreshold) {
        ref
            .read(appConnectionStateProvider.notifier)
            .reportConnectivityFailure();
      }
      state = state.copyWith(isFetching: false);
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
