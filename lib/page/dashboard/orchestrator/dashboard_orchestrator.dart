import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/utils/usp_subscriptions.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/usp/providers/sse_providers.dart';
import 'package:privacy_gui/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';

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
  @override
  Future<DashboardOrchestratorState> build() async {
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
        final systemInfo = sysData.raw;
        final memPct = systemInfo.totalMemory > 0
            ? ((systemInfo.totalMemory - systemInfo.freeMemory) /
                    systemInfo.totalMemory *
                    100)
                .round()
                .clamp(0, 100)
            : 0;
        ref.read(uspSystemMonitorProvider.notifier).pushSnapshot(
              SystemSnapshot(
                timestamp: DateTime.now(),
                cpuPercent: systemInfo.cpuUsage.clamp(0, 100),
                memoryPercent: memPct,
                totalMemoryKb: systemInfo.totalMemory,
                freeMemoryKb: systemInfo.freeMemory,
              ),
            );
      }).catchError((e) {
        logger.w('[USP][Orchestrator] System monitor snapshot failed: $e');
      }),
    );

    return DashboardOrchestratorState(
      isAuthenticated: usp.isAuthenticated,
    );
  }
}
