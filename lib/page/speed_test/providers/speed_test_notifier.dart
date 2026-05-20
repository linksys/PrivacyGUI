import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/page/speed_test/models/speed_test_state.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final speedTestProvider =
    AsyncNotifierProvider<SpeedTestNotifier, SpeedTestState>(
  SpeedTestNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SpeedTestNotifier extends AsyncNotifier<SpeedTestState> {
  @override
  Future<SpeedTestState> build() async {
    return const SpeedTestState();
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

    final server = s.selectedServer;
    final downloadUrl = server.downloadUrl;

    state = AsyncData(s.copyWith(
      step: SpeedTestStep.testingLatency,
      result: null,
      clearError: true,
      progressMessage: 'Testing latency...',
    ));

    int? latencyMs;

    try {
      // Step 1: Latency test (ping the selected server)
      logger.d('[USP][SpeedTest]: Starting latency test to ${server.host}');
      try {
        final pingResult = await _awaiter.execute(
          operateCommand: 'Device.IP.Diagnostics.IPPing()',
          referencePath: 'Device.IP.Diagnostics.',
          args: {
            'Host': server.host,
            'NumberOfRepetitions': '3',
          },
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
      final downloadResult = await _awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.DownloadDiagnostics()',
        referencePath: 'Device.IP.Diagnostics.',
        args: {'DownloadURL': downloadUrl},
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
    } catch (e) {
      logger.w('[USP][SpeedTest]: Failed: $e');
      state = AsyncData(state.requireValue.copyWith(
        step: SpeedTestStep.error,
        clearProgress: true,
        errorMessage: 'Speed test failed: $e',
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Reset
  // -------------------------------------------------------------------------

  void reset() {
    state = const AsyncData(SpeedTestState());
  }

  // -------------------------------------------------------------------------
  // Error messages
  // -------------------------------------------------------------------------

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
