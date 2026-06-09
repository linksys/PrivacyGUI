import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/diagnostics_scope_service.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final speedTestProvider =
    AsyncNotifierProvider.autoDispose<SpeedTestNotifier, SpeedTestState>(
  SpeedTestNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SpeedTestNotifier extends AutoDisposeAsyncNotifier<SpeedTestState> {
  bool _cancelled = false;
  DiagnosticScope? _activeScope;

  @override
  Future<SpeedTestState> build() async {
    ref.onDispose(_disposeRun);
    return const SpeedTestState();
  }

  Future<void> _disposeRun() async {
    _cancelled = true;
    final scope = _activeScope;
    _activeScope = null;
    if (scope != null && !scope.isReleased) {
      try {
        await scope.release();
      } catch (e) {
        logger.w('[USP][SpeedTest]: Failed to release scope on dispose: $e');
      }
    }
  }

  /// Cancels an in-flight speed test, releases the diagnostics scope, and
  /// resets state to idle. Safe to call when no test is running.
  Future<void> cancel() async {
    final s = state.valueOrNull;
    if (s != null && !s.isRunning) return;
    _cancelled = true;
    final scope = _activeScope;
    _activeScope = null;
    if (scope != null && !scope.isReleased) {
      try {
        await scope.release();
      } catch (e) {
        logger.w('[USP][SpeedTest]: Failed to release scope on cancel: $e');
      }
    }
    state = const AsyncData(SpeedTestState());
  }

  DiagnosticsScopeService get _svc {
    final svc = ref.read(diagnosticsScopeServiceProvider);
    if (svc == null) {
      throw const ConnectivityError(
          message: 'DiagnosticsScopeService not available');
    }
    return svc;
  }

  // -------------------------------------------------------------------------
  // Server Selection
  // -------------------------------------------------------------------------

  void selectServer(SpeedTestServer server) {
    final s = state.valueOrNull;
    if (s == null || s.isRunning) return;
    state = AsyncData(s.copyWith(selectedServer: server));
  }

  // -------------------------------------------------------------------------
  // Run Speed Test
  // -------------------------------------------------------------------------

  Future<void> runSpeedTest() async {
    final s = state.valueOrNull;
    if (s == null || s.isRunning) return;

    _cancelled = false;
    final server = s.selectedServer;
    final downloadUrl = server.downloadUrl;

    // Cache service reference at start — avoids ref.read() after dispose
    final svc = _svc;

    state = AsyncData(s.copyWith(
      step: SpeedTestStep.testingLatency,
      result: null,
      clearError: true,
      progressMessage: 'Testing latency...',
    ));

    int? latencyMs;

    // Acquire scope for the duration of this run. With autoDispose the
    // notifier (and thus the OperationComplete subscription) is torn down
    // when the last listener leaves the page.
    final DiagnosticScope scope;
    try {
      scope = await svc.acquireScope();
    } on ServiceError catch (e) {
      logger.w('[USP][SpeedTest]: Failed to acquire scope: $e');
      state = AsyncData(state.requireValue.copyWith(
        step: SpeedTestStep.error,
        clearProgress: true,
        errorMessage: _scopeErrorMessage(e),
      ));
      return;
    }
    _activeScope = scope;
    if (_cancelled) {
      _activeScope = null;
      try {
        await scope.release();
      } catch (_) {}
      return;
    }

    try {
      // Step 1: Latency test (ping the selected server)
      logger.d('[USP][SpeedTest]: Starting latency test to ${server.host}');
      try {
        final pingResult = await svc.ping(
          scope,
          host: server.host,
          numberOfRepetitions: 3,
          timeout: const Duration(seconds: 15),
        );

        final pingArgs = pingResult.outputArgs;
        latencyMs = int.tryParse(pingArgs['AverageResponseTime'] ?? '');
        logger.d('[USP][SpeedTest]: Latency complete — ${latencyMs}ms');
      } catch (e) {
        logger.w('[USP][SpeedTest]: Latency test failed: $e');
      }

      // Step 2: Download test
      state = AsyncData(state.requireValue.copyWith(
        step: SpeedTestStep.testingDownload,
        progressMessage: 'Testing download speed...',
        result: SpeedTestResult(serverHost: server.name, latencyMs: latencyMs),
      ));

      logger.d('[USP][SpeedTest]: Starting download test: $downloadUrl');
      final downloadResult = await svc.downloadDiagnostic(
        scope,
        downloadUrl: downloadUrl,
        timeout: const Duration(seconds: 120),
      );

      final downloadArgs = downloadResult.outputArgs;
      logger.d('[USP][SpeedTest]: Download result args: $downloadArgs');
      final downloadStatus = downloadArgs['Status'] ?? 'Unknown';

      // Check for download errors
      if (downloadStatus != 'Complete') {
        logger.w(
            '[USP][SpeedTest]: Download failed with status: $downloadStatus');
        final errorMsg = _getDownloadErrorMessage(downloadStatus, downloadUrl);
        state = AsyncData(state.requireValue.copyWith(
          step: SpeedTestStep.error,
          clearProgress: true,
          errorMessage: errorMsg,
        ));
        return;
      }

      final bomTime = DateTime.tryParse(downloadArgs['BOMTime'] ?? '');
      final eomTime = DateTime.tryParse(downloadArgs['EOMTime'] ?? '');
      final downloadBytes =
          int.tryParse(downloadArgs['TestBytesReceived'] ?? '') ?? 0;
      final downloadDurationMs = (bomTime != null && eomTime != null)
          ? eomTime.difference(bomTime).inMilliseconds
          : 0;
      final downloadBps = downloadDurationMs > 0
          ? (downloadBytes * 8 * 1000) ~/ downloadDurationMs
          : 0;

      logger.d('[USP][SpeedTest]: Download complete — '
          '${(downloadBps / 1000000).toStringAsFixed(1)} Mbps');

      // Upload test skipped — firmware bug: UploadDiagnostics does not send
      // OperationComplete notification (confirmed 2026-05-19, FW 1.0.18)
      logger.d('[USP][SpeedTest]: Upload test skipped — '
          'firmware does not support OperationComplete for UploadDiagnostics');

      state = AsyncData(state.requireValue.copyWith(
        step: SpeedTestStep.completed,
        clearProgress: true,
        result: SpeedTestResult(
          serverHost: server.name,
          latencyMs: latencyMs,
          downloadStatus: downloadStatus,
          downloadBps: downloadBps,
          downloadBytes: downloadBytes,
          downloadDurationMs: downloadDurationMs,
          uploadStatus: 'NotSupported',
        ),
      ));
    } on TimeoutException catch (e) {
      logger.w('[USP][SpeedTest]: Timeout: $e');
      state = AsyncData(state.requireValue.copyWith(
        step: SpeedTestStep.error,
        clearProgress: true,
        errorMessage: 'Speed test timed out',
      ));
    } on ServiceError catch (e) {
      logger.w('[USP][SpeedTest]: Failed: $e');
      state = AsyncData(state.requireValue.copyWith(
        step: SpeedTestStep.error,
        clearProgress: true,
        errorMessage: _runErrorMessage(e),
      ));
    } finally {
      if (identical(_activeScope, scope)) _activeScope = null;
      if (!scope.isReleased) {
        try {
          await scope.release();
        } catch (e) {
          logger.w('[USP][SpeedTest]: Failed to release scope: $e');
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Reset
  // -------------------------------------------------------------------------

  void reset() {
    final s = state.valueOrNull;
    if (s != null && s.isRunning) {
      // Fire-and-forget: cancel() will release the scope and reset state.
      unawaited(cancel());
      return;
    }
    state = const AsyncData(SpeedTestState());
  }

  // -------------------------------------------------------------------------
  // Error messages
  // -------------------------------------------------------------------------

  String _scopeErrorMessage(ServiceError e) {
    return switch (e) {
      ConnectivityError() =>
        'Speed test unavailable — diagnostics scope not ready',
      NetworkError() => 'Speed test unavailable — router lost connection',
      _ => 'Speed test unavailable — please try again',
    };
  }

  String _runErrorMessage(ServiceError e) {
    return switch (e) {
      NetworkError() => 'Speed test failed — router lost connection',
      ConnectivityError() =>
        'Speed test unavailable — diagnostics scope not ready',
      InvalidInputError(:final message) =>
        message ?? 'Speed test failed — invalid configuration',
      _ => 'Speed test failed — please try again',
    };
  }

  String _getDownloadErrorMessage(String status, String url) {
    // Extract hostname from URL for display
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? url;

    return switch (status) {
      'Error_NoResponse' =>
        'Could not connect to test server ($host). Please check your internet connection.',
      'Error_InitConnectionFailed' =>
        'Failed to establish connection to test server ($host).',
      'Error_CannotResolveHostName' =>
        'Could not resolve test server address ($host). DNS may be unavailable.',
      'Error_Timeout' => 'Connection to test server timed out.',
      'Error_TransferFailed' => 'Data transfer failed during test.',
      'Error_PasswordRequestFailed' =>
        'Authentication failed with test server.',
      'Error_LoginFailed' => 'Login to test server failed.',
      'Error_NoTransferMode' =>
        'Server does not support required transfer mode.',
      'Error_NoPASV' => 'Server does not support passive mode.',
      'Error_IncorrectSize' => 'Downloaded file size mismatch.',
      'Error_Internal' => 'Internal error occurred during speed test.',
      _ => 'Speed test failed: $status',
    };
  }
}
