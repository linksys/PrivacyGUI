import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/utils/usp_subscriptions.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_loader.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Orchestrator state — only tracks auth readiness.
///
/// All domain data lives in Layer 1 domain providers. The orchestrator's role
/// is to coordinate auth, SSE bootstrap, and parallel domain initialization.
class DashboardOrchestratorState extends Equatable {
  final bool isAuthenticated;

  const DashboardOrchestratorState({required this.isAuthenticated});

  @override
  List<Object?> get props => [isAuthenticated];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Dashboard Orchestrator — coordinates auth, SSE, and domain provider init.
///
/// NOT autoDispose — persists across tab switches (Home/Menu/Support).
/// All domain data has been extracted to Layer 1 providers:
/// - [systemInfoDataProvider] — system info + firmware
/// - [devicesDataProvider] — connected devices + mesh + node models
/// - [ethernetDataProvider] — ethernet interfaces + port models
/// - wifiDataProvider — WiFi radios/SSIDs/APs + radio models
/// - firewallDataProvider, dhcpDataProvider, etc.
///
/// This orchestrator handles:
/// 1. Auth check + session restore
/// 2. Fire-and-forget domain provider triggers (cards show per-card skeletons)
/// 3. SSE bootstrap + deferred subscription registration
/// 4. Pull-to-refresh (invalidate all domain providers)
final dashboardOrchestratorProvider =
    AsyncNotifierProvider<DashboardOrchestrator, DashboardOrchestratorState>(
  DashboardOrchestrator.new,
);

class DashboardOrchestrator extends AsyncNotifier<DashboardOrchestratorState> {
  Timer? _retryTimer;

  /// All dashboard domain providers subject to retry and pull-to-refresh.
  /// Cards trigger these lazily — if any fail during bridge startup burst,
  /// the retry mechanism will invalidate them on a backoff schedule.
  static final _allDomainProviders = [
    ('systemInfo', systemInfoDataProvider),
    ('devices', devicesDataProvider),
    ('ethernet', ethernetDataProvider),
    ('wifi', wifiDataProvider),
    ('wan', wanDataProvider),
    ('lan', lanDataProvider),
    ('dhcp', dhcpDataProvider),
    ('firewall', firewallDataProvider),
    ('portForwarding', portForwardingDataProvider),
    ('portTriggering', portTriggeringDataProvider),
    ('time', timeDataProvider),
  ];

  @override
  Future<DashboardOrchestratorState> build() async {
    ref.onDispose(() => _retryTimer?.cancel());

    ref.listen(authProvider, (prev, next) {
      if (next.isLoading) return;
      final loginType = next.value?.loginType;
      final prevLoginType = prev?.value?.loginType;
      if (prevLoginType != LoginType.local && loginType == LoginType.local) {
        ref.invalidateSelf();
      }
    });

    try {
      return await _buildImpl();
    } catch (e, st) {
      logger.e('[USP][Orchestrator]: build() failed: $e\n$st');
      rethrow;
    }
  }

  /// Invalidate all domain providers and re-run initialization.
  ///
  /// Called by pull-to-refresh and the refresh button.
  Future<void> refreshAll() async {
    // Invalidate all domain providers so they re-fetch on next read.
    for (final (_, provider) in _allDomainProviders) {
      ref.invalidate(provider);
    }
    // Re-run orchestrator build (auth check + re-trigger providers).
    ref.invalidateSelf();
  }

  Future<DashboardOrchestratorState> _buildImpl() async {
    final usp = ref.watch(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }
    // On page reload WASM state is lost — attempt session restore
    if (!usp.isAuthenticated) {
      await ref.read(uspAuthCoordinatorProvider).restoreSession();
      if (!usp.isAuthenticated) {
        throw const NotAuthenticatedError();
      }
    }

    // Trigger all domain providers (fire-and-forget — each card shows its
    // own skeleton until its provider resolves).
    logger.d('[USP][Orchestrator]: Triggering domain providers');
    ref.read(systemInfoDataProvider);
    ref.read(devicesDataProvider);
    ref.read(ethernetDataProvider);

    // Load package widget templates (fire-and-forget — settings panel
    // shows native specs immediately, package specs appear when loaded).
    ref.read(packageWidgetLoaderProvider);

    // SSE subscription registration: deferred until domain providers settle.
    // Core subscriptions are registered AFTER the initial data load to avoid
    // bridge overload — subscription POSTs competing with data GETs on the
    // single-threaded OBUSPA backend causes 503 errors.
    unawaited(_registerSSEAfterDomainReady());

    // Push initial snapshot to system monitor when system info arrives
    unawaited(
      ref.read(systemInfoDataProvider.future).then((sysData) {
        final model = sysData.model;
        ref.read(uspSystemMonitorProvider.notifier).pushSnapshot(
              SystemSnapshot(
                timestamp: DateTime.now(),
                cpuPercent: model.cpuPercent,
                memoryPercent: model.memoryPercent,
                totalMemoryKb: model.totalMemory,
                freeMemoryKb: model.freeMemory,
              ),
            );
      }).catchError((e) {
        logger.w('[USP][Orchestrator]: System monitor snapshot failed: $e');
      }),
    );

    // Delayed retry: if domain providers failed (e.g. bridge 503 on startup),
    // invalidate them after a delay so they re-fetch once the bridge is ready.
    _scheduleProviderRetry();

    return DashboardOrchestratorState(
      isAuthenticated: usp.isAuthenticated,
    );
  }

  /// Registers SSE core subscriptions AFTER domain providers have completed
  /// their initial fetch. This prevents subscription POST requests from
  /// competing with data GET requests on the bridge, which causes 503
  /// errors due to the single-threaded OBUSPA backend.
  Future<void> _registerSSEAfterDomainReady() async {
    await ref.read(dashboardDomainReadyProvider.future);

    // Wait for throttler to fully drain (WAN, LAN, DHCP, firewall, etc.)
    // before registering SSE subscriptions. Domain ready only covers the
    // core 3 providers — other dashboard card requests may still be in-flight.
    await ref.read(bridgeRequestThrottlerProvider).whenIdle();

    final manager = ref.read(sseManagerProvider);
    if (manager == null) return;

    // Ensure SSE is connected (normally via sseBootstrapProvider,
    // but explicitly check for post-reload scenarios).
    if (!manager.isConnected) {
      await manager.connect();
    }

    manager.setCoreSubscriptions(coreSubscriptions);
    await manager.registerDeferredSubscriptions(force: true);
    logger.d(
        '[USP][Orchestrator]: SSE subscriptions registered after domain ready');
  }

  /// Checks domain providers after a delay and invalidates any that are in
  /// error state. This handles the startup race where the bridge is
  /// temporarily unavailable (503) and providers fail before SSE connects.
  ///
  /// Uses exponential backoff (5s → 10s → 20s) with up to [maxRetryAttempts]
  /// attempts. The bridge can take 7+ seconds to come online after app start.
  static const maxRetryAttempts = 3;

  void _scheduleProviderRetry([int attempt = 0]) {
    if (attempt >= maxRetryAttempts) return;

    // Cancel any previously scheduled retry (e.g. from refreshAll re-build).
    _retryTimer?.cancel();

    final retryDelay = Duration(seconds: 5 * (1 << attempt)); // 5s, 10s, 20s

    _retryTimer = Timer(retryDelay, () {
      _retryTimer = null;
      final failed = <String>[];
      for (final (name, provider) in _allDomainProviders) {
        final state = ref.read(provider);
        if (state.hasError) {
          failed.add(name);
          ref.invalidate(provider);
        }
      }
      if (failed.isNotEmpty) {
        logger.d('[USP][Orchestrator]: Retrying failed providers (attempt '
            '${attempt + 1}/$maxRetryAttempts): ${failed.join(', ')}');
      }
      // Always schedule next retry — providers may still be loading at this
      // check (e.g. throttler queue wait) and could fail after this point.
      // The maxRetryAttempts guard at the top prevents infinite retries.
      _scheduleProviderRetry(attempt + 1);
    });
  }
}
