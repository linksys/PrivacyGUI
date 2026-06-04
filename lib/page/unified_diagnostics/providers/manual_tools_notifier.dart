import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/manual_tools_state.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final manualToolsProvider = AsyncNotifierProvider.autoDispose<
    ManualToolsNotifier, NetworkDiagnosticsState>(
  ManualToolsNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ManualToolsNotifier
    extends AutoDisposeAsyncNotifier<NetworkDiagnosticsState> {
  DiagnosticScope? _scope;

  @override
  Future<NetworkDiagnosticsState> build() async {
    ref.onDispose(() async {
      final scope = _scope;
      _scope = null;
      if (scope != null) {
        try {
          await scope.release();
        } catch (e) {
          logger
              .w('[USP][Diagnostics]: Failed to release scope on dispose: $e');
        }
      }
    });
    // No initial fetch — user triggers diagnostics explicitly.
    return const NetworkDiagnosticsState();
  }

  Future<DiagnosticScope> _ensureScope() async {
    final existing = _scope;
    if (existing != null && !existing.isReleased) return existing;

    final executor = ref.read(networkDiagnosticsExecutorProvider);
    if (executor == null) {
      throw const ConnectivityError(
          message: 'NetworkDiagnosticsExecutor not available');
    }
    final scope = await executor.acquireScope();
    _scope = scope;
    return scope;
  }

  // -------------------------------------------------------------------------
  // UI state mutations (synchronous)
  // -------------------------------------------------------------------------

  void updateHost(String host) {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(host: host, clearError: true));
  }

  void updatePingCount(int count) {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(pingCount: count));
  }

  void updateMaxHops(int hops) {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(maxHops: hops));
  }

  void updateDnsServer(String server) {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(dnsServer: server, clearError: true));
  }

  void switchTab(DiagnosticType tab) {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(activeTab: tab, clearError: true));
  }

  // -------------------------------------------------------------------------
  // Ping
  // -------------------------------------------------------------------------

  Future<void> runPing() async {
    final s = state.valueOrNull;
    if (s == null || s.isRunning || s.host.isEmpty) return;

    state = AsyncData(s.copyWith(
      status: DiagnosticStatus.running,
      clearPingResult: true,
      clearError: true,
    ));

    try {
      final scope = await _ensureScope();
      final result = await scope.ping(
        host: s.host,
        numberOfRepetitions: s.pingCount,
        timeout: const Duration(seconds: 30),
      );

      final pingResult = PingResult.fromOperateResult(result, s.host);

      logger.d('[USP][Diagnostics]: Ping complete — '
          'avg=${pingResult.avgResponseTime}ms, '
          '${pingResult.successCount}/${pingResult.totalCount} success');

      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.completed,
        pingResult: pingResult,
      ));
    } on TimeoutException catch (e) {
      logger.w('[USP][Diagnostics]: Ping timeout: $e');
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        error: DiagnosticTimeoutError(operation: 'ping', host: s.host),
      ));
    } catch (e) {
      logger.w('[USP][Diagnostics]: Ping failed: $e');
      final mapped = e is ServiceError ? e : mapUspErrorToServiceError(e);
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        error: mapped,
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Traceroute
  // -------------------------------------------------------------------------

  Future<void> runTraceroute() async {
    final s = state.valueOrNull;
    if (s == null || s.isRunning || s.host.isEmpty) return;

    state = AsyncData(s.copyWith(
      status: DiagnosticStatus.running,
      clearTracerouteResult: true,
      clearError: true,
    ));

    try {
      final scope = await _ensureScope();
      final result = await scope.traceRoute(
        host: s.host,
        maxHopCount: s.maxHops,
        timeout: const Duration(seconds: 120),
      );

      final traceResult = TracerouteResult.fromOperateResult(result, s.host);

      logger.d('[USP][Diagnostics]: Traceroute complete — '
          '${traceResult.hops.length} hops');

      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.completed,
        tracerouteResult: traceResult,
      ));
    } on TimeoutException catch (e) {
      logger.w('[USP][Diagnostics]: Traceroute timeout: $e');
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        error: DiagnosticTimeoutError(operation: 'traceroute', host: s.host),
      ));
    } catch (e) {
      logger.w('[USP][Diagnostics]: Traceroute failed: $e');
      final mapped = e is ServiceError ? e : mapUspErrorToServiceError(e);
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        error: mapped,
      ));
    }
  }

  // -------------------------------------------------------------------------
  // NS Lookup
  // -------------------------------------------------------------------------

  Future<void> runNsLookup() async {
    final s = state.valueOrNull;
    if (s == null || s.isRunning || s.host.isEmpty) return;

    state = AsyncData(s.copyWith(
      status: DiagnosticStatus.running,
      clearNsLookupResult: true,
      clearError: true,
    ));

    try {
      final scope = await _ensureScope();
      final dnsServer = s.dnsServer.trim();
      final result = await scope.nsLookup(
        hostName: s.host,
        dnsServer: dnsServer.isEmpty ? null : dnsServer,
        timeout: const Duration(seconds: 30),
      );

      final lookupResult = NsLookupResult.fromOperateResult(result, s.host);

      logger.d('[USP][Diagnostics]: NS Lookup complete — '
          'status=${lookupResult.status}, '
          '${lookupResult.answers.length} answers');

      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.completed,
        nsLookupResult: lookupResult,
      ));
    } on TimeoutException catch (e) {
      logger.w('[USP][Diagnostics]: NS Lookup timeout: $e');
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        error: DiagnosticTimeoutError(operation: 'nslookup', host: s.host),
      ));
    } catch (e) {
      logger.w('[USP][Diagnostics]: NS Lookup failed: $e');
      final mapped = e is ServiceError ? e : mapUspErrorToServiceError(e);
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        error: mapped,
      ));
    }
  }
}
