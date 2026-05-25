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

  /// Cap on the HTTP wait for the Operate request. The SSE OperationComplete
  /// is the source of truth for completion; the HTTP call only acknowledges
  /// receipt. If the agent hangs, we don't want callers blocked indefinitely.
  ///
  /// Set conservatively (15s) — bridge typically acks in well under 1s, but
  /// can stall up to ~10s while OBUSPA finishes processing in-flight
  /// subscribe/unsubscribe traffic from a prior diagnostic session. We retry
  /// once on timeout (see [_operateWithRetry]) instead of relying on a long
  /// single timeout, which gives much faster recovery and matches what users
  /// already do manually ("Run Again worked").
  static const _operateHttpTimeout = Duration(seconds: 15);

  /// Number of times the HTTP operate POST is retried after an ack timeout
  /// before surfacing the failure to the caller. The bridge most often clears
  /// after its own queue drains (~1–2s), so a single retry recovers the vast
  /// majority of stalls.
  static const _operateHttpRetries = 1;

  SseOperationAwaiter(this._manager, this._usp);

  /// Wrap [UspClient.operate] with a per-attempt timeout and a single retry.
  ///
  /// We see the bridge occasionally take > [_operateHttpTimeout] to ack the
  /// first operate after a fresh page entry (the bridge appears to serialize
  /// the new POST behind in-flight cleanup from the prior session). The
  /// stall is transient: a second attempt typically returns in well under a
  /// second. Retrying here turns "stuck for 30s on first attempt" into a
  /// short hiccup and removes the need for the user to press "Run Again".
  Future<Map<String, dynamic>> _operateWithRetry(
    String operateCommand,
    Map<String, String> args,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt <= _operateHttpRetries; attempt++) {
      try {
        return await _usp.operate(operateCommand, args: args).timeout(
              _operateHttpTimeout,
              onTimeout: () => throw TimeoutException(
                'HTTP operate ack not received within '
                '${_operateHttpTimeout.inSeconds}s for $operateCommand '
                '(attempt ${attempt + 1})',
              ),
            );
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt < _operateHttpRetries) {
          logger.w('[USP][SSE][Operate]: HTTP ack timeout for $operateCommand '
              '(attempt ${attempt + 1}), retrying once');
          continue;
        }
        rethrow;
      }
    }
    // Unreachable: loop either returns or rethrows on the last attempt.
    throw lastError ?? StateError('operate retry loop exited unexpectedly');
  }

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

  final List<Future<void> Function()> _sharedCleanups = [];
  int _sharedRefCount = 0;

  /// In-flight teardown of the previous shared session, if any. New
  /// [startSharedSession] callers await this so we never race a fresh
  /// subscribe POST against the still-pending unsubscribe DELETE for the
  /// same TR-181 path — the firmware/bridge has been observed to drop the
  /// new subscription silently when the two overlap, which manifests as
  /// "no OperationComplete event received" on the second run.
  Future<void>? _pendingTeardown;

  /// When ref-count drops to zero we hold the subscription open for a short
  /// linger window instead of tearing it down immediately. If a re-acquire
  /// happens within the window we just bump the ref-count and reuse the
  /// existing bridge subscriptions — no HTTP, no firmware churn. This avoids
  /// the "tear down then immediately re-subscribe the same path" pattern the
  /// firmware mishandles (next OperationComplete is never delivered).
  static const _lingerDuration = Duration(seconds: 4);
  Timer? _lingerTimer;

  bool get hasSharedSubscription => _sharedRefCount > 0 || _lingerTimer != null;

  /// Start (or join) a shared subscription session for batch Operate commands.
  ///
  /// Ref-counted: each call must be paired with [endSharedSession]. Subscription
  /// is created on the first acquire and torn down only when the last holder
  /// releases.
  ///
  /// Pass [referencePaths] for multi-path subscriptions (e.g.
  /// `['Device.IP.Diagnostics.', 'Device.DNS.Diagnostics.']`). Each path is
  /// subscribed as its own bridge subscription so firmware delivers
  /// OperationComplete events for that subtree.
  ///
  /// [referencePath] is retained for backward compatibility — equivalent to
  /// passing a single-element [referencePaths] list.
  Future<void> startSharedSession({
    String? referencePath,
    List<String>? referencePaths,
  }) async {
    final paths = referencePaths ??
        (referencePath != null ? <String>[referencePath] : const <String>[]);
    if (paths.isEmpty) {
      throw ArgumentError(
          'startSharedSession requires referencePath or referencePaths');
    }

    if (_sharedRefCount > 0) {
      _sharedRefCount++;
      logger.d(
          '[USP][SSE][Operate]: Shared session ref++ (count=$_sharedRefCount)');
      return;
    }

    // Re-acquire within the linger window: cancel pending teardown and
    // reuse the existing subscriptions. No HTTP, no firmware churn.
    if (_lingerTimer != null && _sharedCleanups.isNotEmpty) {
      _lingerTimer!.cancel();
      _lingerTimer = null;
      _sharedRefCount = 1;
      logger.d('[USP][SSE][Operate]: Reusing lingering shared session '
          '(${_sharedCleanups.length} subscriptions)');
      return;
    }

    // If a previous teardown actually started (linger expired), wait for the
    // DELETEs to finish before issuing fresh subscribe POSTs for the same
    // paths — firmware drops the new subscription if it sees an overlapping
    // delete for the same reference path.
    final teardown = _pendingTeardown;
    if (teardown != null) {
      logger.d('[USP][SSE][Operate]: Waiting for previous teardown to finish');
      try {
        await teardown;
      } catch (_) {
        // Teardown errors are already logged; we still want a fresh start.
      }
    }

    final sessionId = _uuid.v4().substring(0, 8);
    logger.d('[USP][SSE][Operate]: Starting shared session '
        '$sessionId (paths=${paths.length})');

    final cleanups = <Future<void> Function()>[];
    try {
      for (var i = 0; i < paths.length; i++) {
        final cleanup = await _manager.subscribe(
          subscriptionId: 'operate-shared-$sessionId-$i',
          notifType: 'OperationComplete',
          referenceList: paths[i],
          onNotification: (_) {},
        );
        cleanups.add(cleanup);
      }
    } catch (e) {
      // Roll back any successful subscriptions if a later one fails.
      for (final c in cleanups) {
        try {
          await c();
        } catch (cleanupErr) {
          logger.w('[USP][SSE][Operate]: Rollback cleanup failed: $cleanupErr');
        }
      }
      rethrow;
    }

    _sharedCleanups.addAll(cleanups);
    _sharedRefCount = 1;
    logger.d('[USP][SSE][Operate]: Shared session started '
        '(${_sharedCleanups.length} subscriptions)');
  }

  /// Decrement the shared session ref-count. When the count reaches zero we
  /// schedule teardown after [_lingerDuration] — this lets a quick re-entry
  /// (Done → dashboard → re-open diagnostics) reuse the existing bridge
  /// subscriptions without churning the firmware.
  Future<void> endSharedSession() async {
    if (_sharedRefCount == 0) return;

    _sharedRefCount--;
    if (_sharedRefCount > 0) {
      logger.d(
          '[USP][SSE][Operate]: Shared session ref-- (count=$_sharedRefCount)');
      return;
    }

    // Already lingering — should not happen but stay idempotent.
    if (_lingerTimer != null) return;

    logger.d('[USP][SSE][Operate]: Ref-count 0 — lingering for '
        '${_lingerDuration.inSeconds}s before teardown');
    _lingerTimer = Timer(_lingerDuration, _teardownLingeringSession);
  }

  /// Force-tear-down the shared session right now. Used by [dispose] and
  /// tests. Production callers should rely on the linger timer.
  Future<void> tearDownSharedSessionNow() async {
    _lingerTimer?.cancel();
    _lingerTimer = null;
    if (_sharedCleanups.isEmpty) return;
    await _runTeardown();
  }

  void _teardownLingeringSession() {
    _lingerTimer = null;
    if (_sharedRefCount > 0 || _sharedCleanups.isEmpty) return;
    // Fire-and-forget: nobody is awaiting this. Errors are logged inside.
    unawaited(_runTeardown());
  }

  Future<void> _runTeardown() async {
    logger.d('[USP][SSE][Operate]: Tearing down shared session '
        '(${_sharedCleanups.length} subscriptions)');
    final cleanups = List<Future<void> Function()>.from(_sharedCleanups);
    _sharedCleanups.clear();

    // Expose this teardown so a concurrent re-acquire can await it before
    // re-subscribing the same paths.
    final completer = Completer<void>();
    _pendingTeardown = completer.future;
    try {
      for (final c in cleanups) {
        try {
          await c();
        } catch (e) {
          logger.w('[USP][SSE][Operate]: Shared session cleanup failed: $e');
        }
      }
    } finally {
      _pendingTeardown = null;
      completer.complete();
    }
  }

  /// Execute operate using shared subscription (no per-call subscription overhead).
  Future<OperateResult> executeInSession({
    required String operateCommand,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (_sharedRefCount == 0) {
      throw StateError(
          'No shared session active. Call startSharedSession first.');
    }

    final expectedCmd = operateCommand.split('.').last;
    final completer = Completer<OperateResult>();

    // Register wildcard handler BEFORE firing the operate to close the race
    // window where SSE OperationComplete arrives before the HTTP operate
    // response. Match by commandName first; once HTTP returns we tighten the
    // match to commandKey.
    String? expectedKey;
    VoidCallback? removeHandler;
    removeHandler = _manager.addWildcardHandler((notification) {
      if (notification.type != 'OperationComplete' || completer.isCompleted) {
        return;
      }
      final result = _parseOperateResult(notification);
      if (result == null) return;

      final key = expectedKey;
      final matched = (key != null && key.isNotEmpty)
          ? result.commandKey == key
          : result.commandName == expectedCmd;

      if (matched) {
        logger.d('[USP][SSE][Operate]: Session match for $expectedCmd');
        completer.complete(result);
      }
    });

    try {
      // Fire the operate command. Cap the HTTP wait so a hung agent cannot
      // leave the caller spinning forever, and retry once on timeout to
      // recover from the transient bridge stall after page re-entry.
      final operateResponse = await _operateWithRetry(operateCommand, args);
      expectedKey = operateResponse['commandKey'] as String?;

      logger.d('[USP][SSE][Operate]: Executing $operateCommand in session '
          '(commandKey=$expectedKey)');

      final result = await completer.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'OperationComplete not received within ${timeout.inSeconds}s',
        ),
      );
      return result;
    } finally {
      removeHandler();
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
    if (_sharedRefCount > 0) {
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

      // Step 2: Register wildcard handler BEFORE firing operate to close the
      // race window where SSE OperationComplete arrives before the HTTP
      // operate response. Match by commandName first; tighten to commandKey
      // once the HTTP response gives us one.
      String? expectedKey;
      removeHandler = _manager.addWildcardHandler((notification) {
        if (notification.type != 'OperationComplete' || completer.isCompleted) {
          return;
        }
        final result = _parseOperateResult(notification);
        if (result == null) return;

        final key = expectedKey;
        final matched = (key != null && key.isNotEmpty)
            ? result.commandKey == key
            : result.commandName == expectedCmd;

        if (matched) {
          logger.d('[USP][SSE][Operate]: Matched $expectedCmd');
          completer.complete(result);
        }
      });

      // Step 3: Fire the operate command and capture commandKey. Cap the HTTP
      // wait so a hung agent cannot leave the caller spinning forever, and
      // retry once on timeout to recover from transient bridge stalls.
      final operateResponse = await _operateWithRetry(operateCommand, args);
      expectedKey = operateResponse['commandKey'] as String?;

      logger.d('[USP][SSE][Operate]: Starting $operateCommand '
          '(commandKey=$expectedKey)');

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
