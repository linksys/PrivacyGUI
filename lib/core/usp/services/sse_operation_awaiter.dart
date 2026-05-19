import 'dart:async';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'dart:ui';

import 'package:uuid/uuid.dart';

import 'sse_event_router.dart';
import 'sse_manager.dart';
import 'usp_client.dart';

export 'package:privacy_gui/core/usp/models/operate_result.dart';

/// Manages async USP Operate commands with SSE-based result delivery.
///
/// Unlike the Invalidation Signal pattern used by dashboard providers,
/// OperationComplete events carry the actual result data — there is no
/// "re-fetch" step. The SSE notification IS the data.
///
/// This is necessary because BUG-006 means Operate results are NOT written
/// back to the TR-181 data model. Polling GET returns empty.
///
/// Supports concurrent operations via unique subscription IDs.
class SseOperationAwaiter {
  final SseManager _manager;
  final UspClient _usp;
  static const _uuid = Uuid();

  SseOperationAwaiter(this._manager, this._usp);

  /// Execute an async Operate command and await result via SSE.
  ///
  /// If SSE is connected, uses SSE-based delivery (preferred).
  /// If SSE is disconnected, falls back to polling-based approach.
  ///
  /// [operateCommand] — full USP Operate path (e.g., "Device.IP.Diagnostics.IPPing()").
  /// [referencePath] — TR-181 reference for subscription (same as operateCommand).
  /// [args] — Operate input arguments (e.g., {'Host': '8.8.8.8'}).
  /// [timeout] — max wait time for result.
  Future<OperateResult> execute({
    required String operateCommand,
    required String referencePath,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (_manager.isConnected) {
      return _sseBasedExecute(operateCommand, referencePath, args, timeout);
    } else {
      return _pollingFallback(operateCommand, referencePath, args, timeout);
    }
  }

  /// Fire-and-forget: execute operate without waiting for result.
  Future<void> executeNoWait({
    required String operateCommand,
    Map<String, String> args = const {},
  }) async {
    await _usp.operate(operateCommand, args: args);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Shared Subscription Session (for batch operations like diagnostics)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> Function()? _sharedSubscriptionCleanup;
  bool _hasSharedSubscription = false;

  /// Start a shared subscription session for batch Operate commands.
  /// Call [endSharedSession] when done to cleanup.
  Future<void> startSharedSession({
    required String referencePath,
  }) async {
    if (_hasSharedSubscription) return;

    final subscriptionId = 'operate-shared-${_uuid.v4().substring(0, 8)}';
    logger.d('[USP][SSE][Operate]: Starting shared session $subscriptionId');

    _sharedSubscriptionCleanup = await _manager.subscribe(
      subscriptionId: subscriptionId,
      notifType: 'OperationComplete',
      referenceList: referencePath,
      onNotification: (_) {},
    );
    _hasSharedSubscription = true;
    logger.d('[USP][SSE][Operate]: Shared session started');
  }

  /// End the shared subscription session.
  Future<void> endSharedSession() async {
    if (!_hasSharedSubscription) return;

    logger.d('[USP][SSE][Operate]: Ending shared session');
    if (_sharedSubscriptionCleanup != null) {
      try {
        await _sharedSubscriptionCleanup!();
      } catch (e) {
        logger.w('[USP][SSE][Operate]: Shared session cleanup failed: $e');
      }
    }
    _sharedSubscriptionCleanup = null;
    _hasSharedSubscription = false;
  }

  /// Execute operate using shared subscription (no per-call subscription overhead).
  Future<OperateResult> executeInSession({
    required String operateCommand,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (!_hasSharedSubscription) {
      throw StateError(
          'No shared session active. Call startSharedSession first.');
    }

    final expectedCmd = operateCommand.split('.').last;
    final completer = Completer<OperateResult>();

    // Fire the operate command and capture commandKey
    final operateResponse = await _usp.operate(operateCommand, args: args);
    final expectedKey = operateResponse['commandKey'] as String?;

    logger.d('[USP][SSE][Operate]: Executing $operateCommand in session '
        '(commandKey=$expectedKey)');

    // Wildcard handler for this specific operation
    VoidCallback? removeHandler;
    removeHandler = _manager.addWildcardHandler((notification) {
      if (notification.type == 'OperationComplete' && !completer.isCompleted) {
        final result = _parseOperateResult(notification);
        if (result == null) return;

        final matched = (expectedKey != null && expectedKey.isNotEmpty)
            ? result.commandKey == expectedKey
            : result.commandName == expectedCmd;

        if (matched) {
          logger.d('[USP][SSE][Operate]: Session match for $expectedCmd');
          completer.complete(result);
        }
      }
    });

    try {
      final result = await completer.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'OperationComplete not received within ${timeout.inSeconds}s',
        ),
      );
      return result;
    } finally {
      removeHandler?.call();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SSE-Based Execution (preferred)
  // ══════════════════════════════════════════════════════════════════════════

  Future<OperateResult> _sseBasedExecute(
    String operateCommand,
    String referencePath,
    Map<String, String> args,
    Duration timeout,
  ) async {
    // If a shared session is active, use it instead
    if (_hasSharedSubscription) {
      return executeInSession(
        operateCommand: operateCommand,
        args: args,
        timeout: timeout,
      );
    }

    final expectedCmd = operateCommand.split('.').last;
    final opId = _uuid.v4().substring(0, 8);
    final subscriptionId = _operateSubId(operateCommand, opId);
    final completer = Completer<OperateResult>();

    VoidCallback? removeHandler;
    Future<void> Function()? cleanupSubscription;
    try {
      // Step 1: Register subscription (OBUSPA + bridge) so the CPE sends events
      cleanupSubscription = await _manager.subscribe(
        subscriptionId: subscriptionId,
        notifType: 'OperationComplete',
        referenceList: referencePath,
        onNotification: (_) {}, // No-op: actual matching via wildcard below
      );

      // Step 2: Fire the operate command and capture commandKey for correlation
      final operateResponse = await _usp.operate(operateCommand, args: args);
      final expectedKey = operateResponse['commandKey'] as String?;

      logger.d('[USP][SSE][Operate]: Starting $operateCommand '
          '(commandKey=$expectedKey)');

      // Step 3: Wildcard handler matches by commandKey (primary) or
      // falls back to command_name if commandKey is unavailable.
      removeHandler = _manager.addWildcardHandler((notification) {
        if (notification.type == 'OperationComplete' &&
            !completer.isCompleted) {
          final result = _parseOperateResult(notification);
          if (result == null) return;

          final matched = (expectedKey != null && expectedKey.isNotEmpty)
              ? result.commandKey == expectedKey
              : result.commandName == expectedCmd;

          if (matched) {
            logger.d('[USP][SSE][Operate]: Matched $expectedCmd');
            completer.complete(result);
          }
        }
      });

      // Await SSE OperationComplete or timeout
      final result = await completer.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'OperationComplete not received within ${timeout.inSeconds}s '
          'for $operateCommand',
        ),
      );

      logger.d(
          '[USP][SSE][Operate]: Completed $operateCommand: ${result.status}');
      return result;
    } finally {
      // Always cleanup: wildcard handler + subscription
      removeHandler?.call();
      if (cleanupSubscription != null) {
        try {
          await cleanupSubscription();
        } catch (e) {
          logger
              .w('[USP][SSE][Operate]: Cleanup failed for $subscriptionId: $e');
        }
      }
    }
  }

  /// Generate a subscription ID for an operate command.
  static String _operateSubId(String command, String opId) {
    // "Device.IP.Diagnostics.IPPing()" → "ipping-op-f7a93db5"
    final name = command.split('.').last.replaceAll('()', '').toLowerCase();
    return '$name-op-$opId';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Polling Fallback (when SSE disconnected)
  // ══════════════════════════════════════════════════════════════════════════

  Future<OperateResult> _pollingFallback(
    String operateCommand,
    String referencePath,
    Map<String, String> args,
    Duration timeout,
  ) async {
    logger.d('[USP][SSE][Operate]: SSE disconnected, using polling fallback '
        'for $operateCommand');

    // Fire the operate command
    await _usp.operate(operateCommand, args: args);

    // Derive the GET path from the operate path
    // "Device.IP.Diagnostics.IPPing()" → "Device.IP.Diagnostics.IPPing."
    final getPath = operateCommand.replaceAll('()', '.');

    // Poll until DiagnosticsState == 'Complete' or timeout
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(seconds: 1));

      try {
        final response = await _usp.get([getPath]);
        final stateKey = response.keys.firstWhere(
            (k) => k.endsWith('DiagnosticsState'),
            orElse: () => '');
        if (stateKey.isNotEmpty) {
          final state = response[stateKey]?.toString() ?? '';
          if (state == 'Complete' || state == 'Error') {
            // Extract command name from path
            final cmdName =
                operateCommand.split('.').last; // "IPPing()" or "TraceRoute()"

            // Convert response to output args format
            final outputArgs = response.map(
              (k, v) => MapEntry(
                k.replaceFirst(getPath, ''),
                v.toString(),
              ),
            );

            return OperateResult(
              commandName: cmdName,
              commandKey: '',
              status: state,
              outputArgs: outputArgs,
            );
          }
        }
      } catch (e) {
        logger.w('[USP][SSE][Operate]: Poll error: $e');
      }
    }

    throw TimeoutException(
      'Polling fallback timed out after ${timeout.inSeconds}s '
      'for $operateCommand',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════════════════

  /// Parse an SSE notification into an [OperateResult].
  OperateResult? _parseOperateResult(SseNotification notification) {
    final operComplete =
        notification.payload['oper_complete'] as Map<String, dynamic>?;
    if (operComplete == null) return null;

    final outputArgs = (operComplete['output_args'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString())) ??
        {};

    return OperateResult(
      commandName: operComplete['command_name']?.toString() ?? '',
      commandKey: operComplete['command_key']?.toString() ?? '',
      status: outputArgs['Status'] ?? outputArgs['status'] ?? 'Unknown',
      outputArgs: outputArgs,
    );
  }
}
