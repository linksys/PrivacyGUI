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

  /// Diagnostics whose `OperationComplete` has not arrived yet, by `commandKey`.
  ///
  /// The whole of #1578's state. Guardian publishes a diagnostic's push signal **at
  /// most once and never retries it**, so a signal lost to a reconnect is
  /// unrecoverable from the stream — but the result is stored, and
  /// `GET /usp/results?commandKey=` reads it back. This map is what says which keys
  /// are worth asking about.
  final Map<String, Completer<OperateResult>> _pending = {};

  /// Removes the stream-opened listener when this awaiter is torn down.
  VoidCallback? _removeStreamOpenedListener;

  SseOperationAwaiter(this._manager, this._usp) {
    // Reconcile on reconnect, which is the case the read exists for: Guardian closes
    // every stream at ~10 minutes, so a diagnostic straddling that boundary loses its
    // push with nothing to notice it.
    //
    // **On the edge, not on an interval.** The spec prohibits polling these reads —
    // the server already polls DynamoDB on our behalf every ~10 s, and a second layer
    // multiplies the read volume the design budgets for. A stream open is a discrete
    // event, and `sse_operation_awaiter_reconcile_test.dart` asserts the call count
    // rather than trusting this paragraph.
    _removeStreamOpenedListener = _manager.addStreamOpenedListener(() {
      // Fire-and-forget: this runs from a stream callback nobody awaits, so an
      // escaping error would surface as an unhandled async error.
      _reconcileAllPending().catchError((Object e) {
        logger.w('[USP][SSE][Operate]: Reconcile after reopen failed: $e');
      });
    });
  }

  /// Reads Guardian's stored result for every outstanding diagnostic.
  ///
  /// Sequential rather than `Future.wait`: there is rarely more than one, and a burst
  /// of concurrent reads against the proxy is the shape the no-polling rule exists to
  /// keep down.
  Future<void> _reconcileAllPending() async {
    if (_pending.isEmpty) return;
    logger.d('[USP][SSE][Operate]: Stream reopened with ${_pending.length} '
        'diagnostic(s) outstanding — reconciling');
    for (final key in [..._pending.keys]) {
      await _reconcile(key);
    }
  }

  /// Completes the pending operation for [commandKey] from Guardian's store, if a row
  /// is there. Returns whether it did.
  ///
  /// **Attribution is the `commandKey` and nothing else.** #1575's verification item 2
  /// is closed without an environment: `web/usp_client.d.ts` documents `commandKey` as
  /// a UUID minted per `operate()` call, so it is unique *per execution* by
  /// construction and any row carrying it belongs to this run. The spec's other
  /// admissible route — record what already exists for the key before firing, accept
  /// only what is new — is therefore unnecessary, and implementing it would add a read
  /// on the happy path to disambiguate something that cannot collide.
  ///
  /// **Timestamps are not compared, deliberately.** `originTs` is the cloud broker's
  /// receive time; subtracting a local clock from it fails silently in both
  /// directions.
  ///
  /// An empty array is a definitive "not there yet" — no retry loop. And a
  /// not-yet-arrived push is not a lost one: the backend retries its own read-back
  /// three times with a doubling delay, so a healthy push can trail the write by
  /// several seconds. Reading empty here simply leaves the operation pending for the
  /// stream or the timeout to resolve.
  Future<bool> _reconcile(String commandKey) async {
    final completer = _pending[commandKey];
    if (completer == null || completer.isCompleted) return false;

    final List<Object?> rows;
    try {
      rows = await _manager.bridge.results(commandKey);
    } catch (e) {
      // Includes the local transport, where this read does not exist at all: the
      // stored-result endpoint is Guardian's, so locally every reconcile is a
      // `StateError` and the operation is left to its stream and its timeout — which
      // is the correct behaviour and not a degraded one. A lost local push is a
      // different problem with no store behind it.
      logger.d('[USP][SSE][Operate]: No stored result for $commandKey: $e');
      return false;
    }

    for (final row in rows) {
      final result = _parseStoredResult(row, commandKey);
      if (result == null) continue;
      if (completer.isCompleted) return false;
      logger.i('[USP][SSE][Operate]: Recovered ${result.commandName} from '
          'Guardian\'s store (commandKey=$commandKey)');
      completer.complete(result);
      return true;
    }
    return false;
  }

  /// One `results` row as an [OperateResult], or null if it is not one.
  ///
  /// **Two shapes are accepted, and that is a hedge with a reason.** The spec says the
  /// endpoint returns one row per execution and nothing more precise about the row, and
  /// no environment has served one yet (#1575's verification list). The two candidates
  /// are the notification envelope — `{msgId, originTs, notificationType, body: {…}}`,
  /// which is what `history` uses — and the bare notify payload. Tolerating both costs
  /// four lines and means whichever QA serves, this works; guessing one and being
  /// wrong means a reconcile that silently never matches, which is indistinguishable
  /// from "the result was not stored".
  ///
  /// The key is re-checked here even though the query already filtered on it: the
  /// query is the server's promise and this is the client's own attribution, which is
  /// the half the spec makes the client's job.
  OperateResult? _parseStoredResult(Object? row, String commandKey) {
    if (row is! Map<String, dynamic>) return null;
    final body = row['body'];
    final payload = body is Map<String, dynamic> ? body : row;
    if (payload['oper_complete'] is! Map<String, dynamic>) return null;

    final result = _parseOperateResult(
      SseNotification(
        subscriptionId: '',
        type: 'OperationComplete',
        payload: payload,
      ),
    );
    if (result == null) return null;
    return result.commandKey == commandKey ? result : null;
  }

  /// Last chance before a timeout is reported: read the stored result.
  ///
  /// The other half of #1578, and the cheaper half to get wrong — a timeout is what a
  /// caller sees when the push was lost, so reporting one without asking the store is
  /// throwing away the only copy that exists. One read, on one edge, and only when the
  /// stream has already failed to deliver.
  Future<OperateResult> _timeoutOrStoredResult(
    String? commandKey,
    String operateCommand,
    Duration timeout,
  ) async {
    if (commandKey != null && commandKey.isNotEmpty) {
      if (await _reconcile(commandKey)) {
        final completer = _pending[commandKey];
        if (completer != null && completer.isCompleted) {
          return completer.future;
        }
      }
    }
    throw TimeoutException(
      'OperationComplete not received within ${timeout.inSeconds}s '
      'for $operateCommand',
    );
  }

  /// Stops reconciling, and drops any operation still outstanding.
  ///
  /// Wired to `sseOperationAwaiterProvider`'s `onDispose`. Not strictly necessary —
  /// the awaiter is rebuilt only when its manager is, and a disposed manager's
  /// listener list goes with it — but an awaiter that outlived its registration would
  /// reconcile against a stream it no longer belongs to, and that is cheaper to
  /// prevent than to diagnose.
  ///
  /// Pending completers are **dropped, not errored**, the same contract
  /// `OperationCompleteWatch.release()` states: every one of them is already being
  /// awaited under a `.timeout`, so erroring them here would turn an ordinary teardown
  /// race into an unhandled async error.
  void dispose() {
    _removeStreamOpenedListener?.call();
    _removeStreamOpenedListener = null;
    _pending.clear();
  }

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

      // Outstanding from here, so a stream reopen can reconcile it (#1578).
      final trackedKey = expectedKey;
      if (trackedKey != null && trackedKey.isNotEmpty) {
        _pending[trackedKey] = completer;
      }

      final result = await completer.future.timeout(
        timeout,
        onTimeout: () =>
            _timeoutOrStoredResult(expectedKey, operateCommand, timeout),
      );
      return result;
    } finally {
      removeHandler();
      final trackedKey = expectedKey;
      if (trackedKey != null) _pending.remove(trackedKey);
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

    // Hoisted beside `removeHandler` and for the same reason: the `finally` has to
    // un-track this operation, so the key cannot live inside the `try` (#1578).
    String? expectedKey;
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

      // Outstanding from here, so a stream reopen can reconcile it (#1578).
      final trackedKey = expectedKey;
      if (trackedKey != null && trackedKey.isNotEmpty) {
        _pending[trackedKey] = completer;
      }

      // Await SSE OperationComplete, or read the stored result before reporting a
      // timeout — Guardian never re-publishes a push it has already sent once.
      final result = await completer.future.timeout(
        timeout,
        onTimeout: () =>
            _timeoutOrStoredResult(expectedKey, operateCommand, timeout),
      );

      logger.d(
          '[USP][SSE][Operate]: Completed $operateCommand: ${result.status}');
      return result;
    } finally {
      // Always cleanup: wildcard handler + subscription
      removeHandler?.call();
      final trackedKey = expectedKey;
      if (trackedKey != null) _pending.remove(trackedKey);
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

    // USP's OperationComplete carries *either* output args or a CommandFailure,
    // never both. Read under both spellings because only one of them has been
    // seen on a bench: the notification's other members arrive snake_cased
    // (`command_name`, `output_args`) so `err_code` is the expected shape, but
    // the bridge hands some payloads through with protobuf's camelCase intact
    // and a refusal read as a success is the one misparse that matters here.
    //
    // Which is why the *presence* of `cmd_failure` is what marks the refusal, and
    // the code inside it is only detail: hedging two spellings still left a third,
    // and a router that named its refusal with a message and no code, reading as
    // success. See [OperateResult.refused].
    final failure = operComplete['cmd_failure'] as Map<String, dynamic>?;
    final errorCode = _nonEmpty(failure?['err_code'] ?? failure?['errCode']);
    final errorMessage = _nonEmpty(failure?['err_msg'] ?? failure?['errMsg']);

    return OperateResult(
      commandName: operComplete['command_name']?.toString() ?? '',
      commandKey: operComplete['command_key']?.toString() ?? '',
      // Three outcomes, and the *absence* of `cmd_failure` is what decides
      // between them — never the absence of `output_args` (#1579).
      //
      // A refusal reads as `Error` rather than as the `Unknown` it used to,
      // because `cmd_failure` carries no `Status` and a caller checking
      // `isError` was being told nothing. `isFailure` is the finer question.
      //
      // Everything else is a **success**, whether or not the router named a
      // status: a diagnostic that completed with no output args at all carries
      // neither key, and one that answered without a `Status` key carries the
      // first but not that member. Both used to fall through to `'Unknown'`,
      // which every `isComplete` caller reads as "not complete" — so a
      // successful no-output diagnostic drew the error icon
      // (`diagnostic_manual_tools_view.dart:375`). `OperateResult
      // .completedWithoutOutput` is what keeps the two successes nameable now
      // that they share a status.
      status: outputArgs['Status'] ??
          outputArgs['status'] ??
          (failure != null ? 'Error' : 'Complete'),
      outputArgs: outputArgs,
      errorCode: errorCode,
      errorMessage: errorMessage,
      refused: failure != null,
    );
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString();
    return (text == null || text.isEmpty) ? null : text;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OperationComplete watch (for commands whose result is not in the event)
  // ══════════════════════════════════════════════════════════════════════════

  /// Subscribe `OperationComplete` for [referencePath] and hand the caller the
  /// feed, instead of blocking on one event and calling it the answer.
  ///
  /// [execute] is the right shape for a diagnostic: the notification *is* the
  /// result. It is the wrong shape for a command that reports through the data
  /// model. `FirmwareImage.{ota}.Download()` answers its OperationComplete in
  /// ~49 ms and takes 1–2 s to do the work, so awaiting the event and returning
  /// would report a check as finished before it had looked at anything.
  ///
  /// What the channel is still needed for is refusals — `cmd_failure` arrives
  /// here and nowhere else — so the caller polls for its own answer and races
  /// this to tell "found nothing" from "would not look".
  ///
  /// The caller **must** [OperationCompleteWatch.release] the result; the
  /// subscription is a real one on the agent.
  Future<OperationCompleteWatch> watchOperationComplete({
    required String referencePath,
  }) async {
    if (!_manager.isConnected) {
      // Deliberately *not* [_pollingFallback]. That fallback rewrites the operate
      // path into a GET and waits for `DiagnosticsState`, a parameter only the
      // diagnostics commands publish — pointed at a firmware Download it would
      // spin to its own timeout and then report a failure for a command that ran
      // fine. A watch nobody can feed is the honest degradation: the caller loses
      // `cmd_failure` and keeps its own result channel.
      logger
          .w('[USP][SSE][Operate]: SSE disconnected — OperationComplete watch '
              'on $referencePath will report nothing');
      return OperationCompleteWatch.detached();
    }

    final opId = _uuid.v4().substring(0, 8);
    final subscriptionId = 'watch-op-$opId';
    final cleanupSubscription = await _manager.subscribe(
      subscriptionId: subscriptionId,
      notifType: 'OperationComplete',
      referenceList: referencePath,
      onNotification: (_) {}, // No-op: matching happens on the wildcard below.
    );

    late final OperationCompleteWatch watch;
    final removeHandler = _manager.addWildcardHandler((notification) {
      if (notification.type != 'OperationComplete') return;
      final result = _parseOperateResult(notification);
      if (result != null) watch.emit(result);
    });
    watch = OperationCompleteWatch.detached(onRelease: () async {
      removeHandler();
      try {
        await cleanupSubscription();
      } catch (e) {
        logger.w('[USP][SSE][Operate]: Watch cleanup failed for '
            '$subscriptionId: $e');
      }
    });
    logger.d('[USP][SSE][Operate]: Watching OperationComplete on '
        '$referencePath ($subscriptionId)');
    return watch;
  }
}

/// A live `OperationComplete` feed for one TR-181 subtree.
///
/// Buffers what it has seen, so a predicate registered *after* an event arrived
/// still matches it. That is not a nicety: the only correlator worth matching on
/// is the `commandKey`, and the key does not exist until the Operate's HTTP
/// response returns — which the event is measured to beat.
class OperationCompleteWatch {
  /// A watch with no subscription behind it.
  ///
  /// Two callers, and they want it for opposite reasons.
  /// [SseOperationAwaiter.watchOperationComplete] returns one when SSE is down,
  /// where "nothing will ever arrive" is the truth; a test uses one plus [emit]
  /// to say exactly what arrives and when.
  OperationCompleteWatch.detached({Future<void> Function()? onRelease})
      : _onRelease = onRelease;

  final Future<void> Function()? _onRelease;
  final List<OperateResult> _seen = [];
  final List<
      ({
        bool Function(OperateResult) test,
        Completer<OperateResult> completer,
      })> _waiters = [];

  /// Feed one parsed notification in. Public because the wildcard handler that
  /// calls it is a closure registered by the awaiter, and because a test is the
  /// other producer.
  void emit(OperateResult result) {
    _seen.add(result);
    _waiters.removeWhere((waiter) {
      if (!waiter.test(result)) return false;
      waiter.completer.complete(result);
      return true;
    });
  }

  /// The first event — already seen or yet to arrive — satisfying [test].
  ///
  /// **Never completes with an error, and may never complete at all.** Both are
  /// deliberate: the caller races this against its own timeout, and a future that
  /// throws when the watch is released would surface as an unhandled async error
  /// on the losing side of every race that went the ordinary way.
  Future<OperateResult> firstWhere(bool Function(OperateResult) test) {
    for (final result in _seen) {
      if (test(result)) return Future.value(result);
    }
    final completer = Completer<OperateResult>();
    _waiters.add((test: test, completer: completer));
    return completer.future;
  }

  Future<void> release() async {
    _waiters.clear();
    await _onRelease?.call();
  }
}
