import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/page/network_diagnostics/models/network_diagnostics_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspNetworkDiagnosticsProvider = AsyncNotifierProvider.autoDispose<
    UspNetworkDiagnosticsNotifier, NetworkDiagnosticsState>(
  UspNetworkDiagnosticsNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspNetworkDiagnosticsNotifier
    extends AutoDisposeAsyncNotifier<NetworkDiagnosticsState> {
  @override
  Future<NetworkDiagnosticsState> build() async {
    // No initial fetch — user triggers diagnostics explicitly.
    return const NetworkDiagnosticsState();
  }

  SseOperationAwaiter get _awaiter {
    final awaiter = ref.read(sseOperationAwaiterProvider);
    if (awaiter == null) {
      throw const ConnectivityError(
          message: 'SseOperationAwaiter not available');
    }
    return awaiter;
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
      final result = await _awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        args: {
          'Host': s.host,
          'NumberOfRepetitions': s.pingCount.toString(),
        },
        timeout: const Duration(seconds: 30),
      );

      final pingResult = PingResult.fromOperateResult(result, s.host);

      logger.d('[USP][Diagnostics]Ping complete — '
          'avg=${pingResult.avgResponseTime}ms, '
          '${pingResult.successCount}/${pingResult.totalCount} success');

      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.completed,
        pingResult: pingResult,
      ));
    } on TimeoutException catch (e) {
      logger.w('[USP][Diagnostics]Ping timeout: $e');
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        errorMessage: 'Ping timed out — no response from ${s.host}',
      ));
    } catch (e) {
      logger.w('[USP][Diagnostics]Ping failed: $e');
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        errorMessage: 'Ping failed: $e',
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
      final result = await _awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.TraceRoute()',
        referencePath: 'Device.IP.Diagnostics.TraceRoute()',
        args: {
          'Host': s.host,
          'MaxHopCount': s.maxHops.toString(),
        },
        timeout: const Duration(seconds: 120),
      );

      final traceResult = TracerouteResult.fromOperateResult(result, s.host);

      logger.d('[USP][Diagnostics]Traceroute complete — '
          '${traceResult.hops.length} hops');

      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.completed,
        tracerouteResult: traceResult,
      ));
    } on TimeoutException catch (e) {
      logger.w('[USP][Diagnostics]Traceroute timeout: $e');
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        errorMessage: 'Traceroute timed out — route to ${s.host} incomplete',
      ));
    } catch (e) {
      logger.w('[USP][Diagnostics]Traceroute failed: $e');
      state = AsyncData(state.requireValue.copyWith(
        status: DiagnosticStatus.error,
        errorMessage: 'Traceroute failed: $e',
      ));
    }
  }
}
