import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// A shared mutex for USP mutations.
///
/// WASM-based USP client cannot handle concurrent calls. This lock ensures
/// only one mutation runs at a time across all domain notifiers.
final uspMutationLockProvider =
    Provider<UspMutationLock>((ref) => UspMutationLock());

class UspMutationLock {
  static const defaultTimeout = Duration(seconds: 30);

  Completer<void>? _completer;

  bool get isLocked => _completer != null && !_completer!.isCompleted;

  /// Executes [action] with an exclusive lock.
  ///
  /// If another mutation is already in progress, waits for it to complete
  /// before acquiring the lock and running [action].
  ///
  /// [timeout] protects against hung WASM calls. If the current lock holder
  /// exceeds the timeout, the stale lock is force-released so the system
  /// can recover — that wait never throws. The [action] itself is also subject
  /// to the same timeout.
  ///
  /// **Never throws a [TimeoutException]** (#1831). An [action] that outlasts
  /// [timeout] ends in a [TimeoutError], and so does a [TimeoutException] the
  /// action throws itself: either way something did not answer in time, and a
  /// caller's `on ServiceError` arm — the only kind constitution Article XIII
  /// §13.4 lets a provider have — sees it. While this threw a bare
  /// `TimeoutException`, every such arm missed it: the firmware install and
  /// upload were left mid-update with no failure card, and the pages that read
  /// the router again after a failed save skipped the read. Every other error
  /// the action throws passes through unchanged.
  ///
  /// The action is **not cancelled** when its window ends. A write that timed
  /// out may still land, which is why a caller treats it as "nobody knows what
  /// the router holds", not as "nothing was written".
  Future<T> withLock<T>(
    Future<T> Function() action, {
    Duration timeout = defaultTimeout,
  }) async {
    // Wait for any in-progress mutation to finish (with timeout protection).
    while (isLocked) {
      await _completer!.future.timeout(
        timeout,
        onTimeout: () {
          logger
              .w('[USP][MutationLock] Wait timeout after ${timeout.inSeconds}s '
                  '— force releasing stale lock');
          if (!_completer!.isCompleted) _completer!.complete();
        },
      );
    }

    _completer = Completer<void>();
    try {
      return await action().timeout(
        timeout,
        onTimeout: () => throw TimeoutError(
          detail: 'USP mutation timed out after ${timeout.inSeconds}s',
        ),
      );
    } on TimeoutException catch (e, stack) {
      Error.throwWithStackTrace(
        TimeoutError(
          detail: 'timed out inside a USP mutation: '
              '${e.message ?? e.duration ?? 'no detail'}',
        ),
        stack,
      );
    } finally {
      if (!_completer!.isCompleted) _completer!.complete();
    }
  }
}
