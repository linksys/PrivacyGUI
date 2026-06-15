import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/manual_tools_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/diagnostics_scope_service.dart';

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

  DiagnosticsScopeService get _svc {
    final svc = ref.read(diagnosticsScopeServiceProvider);
    if (svc == null) {
      throw const ConnectivityError(
          detail: 'DiagnosticsScopeService not available');
    }
    return svc;
  }

  Future<DiagnosticScope> _ensureScope() async {
    final existing = _scope;
    if (existing != null && !existing.isReleased) return existing;

    final scope = await _svc.acquireScope();
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
      final result = await _svc.ping(
        scope,
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
        errorMessage: 'Ping timed out — no response from ${s.host}',
      ));
    } on ServiceError catch (e) {
      logger.w('[USP][Diagnostics]: Ping failed: $e');
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        errorMessage: _pingErrorMessage(e, s.host),
      ));
    }
  }

  String _pingErrorMessage(ServiceError e, String host) {
    return switch (e) {
      InvalidInputError(:final detail) =>
        detail ?? 'Cannot ping $host — invalid host',
      NetworkError() => 'Ping failed — router lost connection',
      ConnectivityError() => 'Ping unavailable — diagnostics scope not ready',
      _ => 'Ping failed — please try again',
    };
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
      final result = await _svc.traceRoute(
        scope,
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
        errorMessage: 'Traceroute timed out — route to ${s.host} incomplete',
      ));
    } on ServiceError catch (e) {
      logger.w('[USP][Diagnostics]: Traceroute failed: $e');
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        errorMessage: _tracerouteErrorMessage(e, s.host),
      ));
    }
  }

  String _tracerouteErrorMessage(ServiceError e, String host) {
    return switch (e) {
      InvalidInputError(:final detail) =>
        detail ?? 'Cannot trace $host — invalid host',
      NetworkError() => 'Traceroute failed — router lost connection',
      ConnectivityError() =>
        'Traceroute unavailable — diagnostics scope not ready',
      _ => 'Traceroute failed — please try again',
    };
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
      final result = await _svc.nsLookup(
        scope,
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
        errorMessage:
            'NS Lookup timed out — no response while resolving ${s.host}',
      ));
    } on ServiceError catch (e) {
      logger.w('[USP][Diagnostics]: NS Lookup failed: $e');
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        errorMessage: _nsLookupErrorMessage(e, s.host),
      ));
    }
  }

  String _nsLookupErrorMessage(ServiceError e, String host) {
    return switch (e) {
      InvalidInputError(:final detail) =>
        detail ?? 'Cannot resolve $host — invalid host',
      NetworkError() => 'NS Lookup failed — router lost connection',
      ConnectivityError() =>
        'NS Lookup unavailable — diagnostics scope not ready',
      _ => 'NS Lookup failed — please try again',
    };
  }
}
