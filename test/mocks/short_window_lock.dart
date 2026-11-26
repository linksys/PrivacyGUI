import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';

/// The real [UspMutationLock], with every window shortened to 20 ms.
///
/// For a test that needs the lock to run out for real — what it throws then is
/// production's, not a stand-in's — without waiting the 30 s (or the upload's
/// 60 s per chunk) it would take.
class ShortWindowLock extends UspMutationLock {
  @override
  Future<T> withLock<T>(
    Future<T> Function() action, {
    Duration timeout = UspMutationLock.defaultTimeout,
  }) =>
      super.withLock(action, timeout: const Duration(milliseconds: 20));
}
