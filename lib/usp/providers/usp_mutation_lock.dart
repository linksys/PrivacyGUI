import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  /// can recover. The [action] itself is also subject to the same timeout.
  Future<T> withLock<T>(
    Future<T> Function() action, {
    Duration timeout = defaultTimeout,
  }) async {
    // Wait for any in-progress mutation to finish (with timeout protection).
    while (isLocked) {
      await _completer!.future.timeout(
        timeout,
        onTimeout: () {
          logger.w('[USP][MutationLock] Wait timeout after ${timeout.inSeconds}s '
              '— force releasing stale lock');
          if (!_completer!.isCompleted) _completer!.complete();
        },
      );
    }

    _completer = Completer<void>();
    try {
      return await action().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'USP mutation timed out after ${timeout.inSeconds}s',
            timeout,
          );
        },
      );
    } finally {
      if (!_completer!.isCompleted) _completer!.complete();
    }
  }
}
