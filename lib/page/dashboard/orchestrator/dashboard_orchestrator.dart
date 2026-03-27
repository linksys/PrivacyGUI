import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/utils/usp_subscriptions.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_loader.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';

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

  @override
  Future<DashboardOrchestratorState> build() async {
    ref.onDispose(() => _retryTimer?.cancel());

    try {
      return await _buildImpl();
    } catch (e, st) {
      logger.e('[USP][Orchestrator] build() failed: $e\n$st');
      rethrow;
    }
  }

  /// Invalidate all domain providers and re-run initialization.
  ///
  /// Called by pull-to-refresh and the refresh button.
  Future<void> refreshAll() async {
    // Invalidate domain providers so they re-fetch on next read.
    ref.invalidate(systemInfoDataProvider);
    ref.invalidate(devicesDataProvider);
    ref.invalidate(ethernetDataProvider);
    ref.invalidate(wifiDataProvider);
    // Re-run orchestrator build (auth check + re-trigger providers).
    ref.invalidateSelf();
  }

  Future<DashboardOrchestratorState> _buildImpl() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) {
      throw StateError('USP service not available');
    }
    // On page reload WASM state is lost — attempt session restore
    bool authWasRestored = false;
    if (!usp.isAuthenticated) {
      await ref.read(uspAuthCoordinatorProvider).restoreSession();
      if (!usp.isAuthenticated) {
        throw StateError('USP not authenticated after restore attempt');
      }
      authWasRestored = true;
    }

    // Trigger all domain providers (fire-and-forget — each card shows its
    // own skeleton until its provider resolves).
    logger.d('[USP][Orchestrator] Triggering domain providers');
    ref.read(systemInfoDataProvider);
    ref.read(devicesDataProvider);
    ref.read(ethernetDataProvider);

    // Load package widget templates (fire-and-forget — settings panel
    // shows native specs immediately, package specs appear when loaded).
    ref.read(packageWidgetLoaderProvider);

    // SSE subscription setup
    if (authWasRestored) {
      final manager = ref.read(sseManagerProvider);
      if (manager != null) {
        manager.setCoreSubscriptions(coreSubscriptions);
        if (!manager.isConnected) {
          await manager.connect();
        }
        await manager.registerDeferredSubscriptions(force: true);
        logger.d('[USP][Orchestrator]Post-reload SSE setup complete');
      }
    } else {
      ref.read(sseManagerProvider)?.registerDeferredSubscriptions();
    }

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
        logger.w('[USP][Orchestrator] System monitor snapshot failed: $e');
      }),
    );

    // Delayed retry: if domain providers failed (e.g. bridge 503 on startup),
    // invalidate them after a delay so they re-fetch once the bridge is ready.
    _scheduleProviderRetry();

    return DashboardOrchestratorState(
      isAuthenticated: usp.isAuthenticated,
    );
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
    // Retry all domain providers that may have failed during initial load.
    // wifiDataProvider starts lazily via devicesDataProvider's soft dependency
    // but can fail due to throttler queue delays — include it in retries.
    final providers = [
      ('systemInfo', systemInfoDataProvider),
      ('devices', devicesDataProvider),
      ('ethernet', ethernetDataProvider),
      ('wifi', wifiDataProvider),
    ];

    _retryTimer = Timer(retryDelay, () {
      _retryTimer = null;
      final failed = <String>[];
      for (final (name, provider) in providers) {
        final state = ref.read(provider);
        if (state.hasError) {
          failed.add(name);
          ref.invalidate(provider);
        }
      }
      if (failed.isNotEmpty) {
        logger.d('[USP][Orchestrator] Retrying failed providers (attempt '
            '${attempt + 1}/$maxRetryAttempts): ${failed.join(', ')}');
      }
      // Always schedule next retry — providers may still be loading at this
      // check (e.g. throttler queue wait) and could fail after this point.
      // The maxRetryAttempts guard at the top prevents infinite retries.
      _scheduleProviderRetry(attempt + 1);
    });
  }
}
