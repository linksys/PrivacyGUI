import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A shared mutex for USP mutations.
///
/// WASM-based USP client cannot handle concurrent calls. This lock ensures
/// only one mutation runs at a time across all domain notifiers.
final uspMutationLockProvider =
    Provider<UspMutationLock>((ref) => UspMutationLock());

class UspMutationLock {
  Completer<void>? _completer;

  bool get isLocked => _completer != null && !_completer!.isCompleted;

  /// Executes [action] with an exclusive lock.
  ///
  /// If another mutation is already in progress, waits for it to complete
  /// before acquiring the lock and running [action].
  Future<T> withLock<T>(Future<T> Function() action) async {
    // Wait for any in-progress mutation to finish.
    while (isLocked) {
      await _completer!.future;
    }

    _completer = Completer<void>();
    try {
      return await action();
    } finally {
      _completer!.complete();
    }
  }
}
