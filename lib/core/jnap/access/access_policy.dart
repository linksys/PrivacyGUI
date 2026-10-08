import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/access/jnap_write_classifier.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// Thrown instead of sending a JNAP write the current login may not make.
///
/// Nothing reaches the router: the request is refused before it is built.
class ReadOnlyAccessException implements Exception {
  const ReadOnlyAccessException(this.action);

  /// The write that was refused. For a transaction, the first write in it.
  final JNAPAction action;

  @override
  String toString() => 'ReadOnlyAccessException: ${action.name} refused';
}

/// What the current login is allowed to do to the router.
///
/// The one place that answers "may this change the router", for both the JNAP
/// layer (which enforces it) and the UI (which uses it to disable controls
/// before the user gets as far as a refused request).
class AccessPolicy extends Equatable {
  const AccessPolicy({required this.canWrite});

  static const full = AccessPolicy(canWrite: true);

  final bool canWrite;

  /// Throws [ReadOnlyAccessException] when sending [action] with [data] would
  /// change the router and this policy does not allow it.
  void checkSend(JNAPAction action, {Map<String, dynamic> data = const {}}) {
    if (!canWrite && isJNAPWrite(action, data: data)) {
      throw ReadOnlyAccessException(action);
    }
  }

  /// Throws [ReadOnlyAccessException] for [action] unless this policy allows
  /// writes. For a write that does not go through [checkSend] - one sent some
  /// other way than a JNAP request.
  void checkWrite(JNAPAction action) {
    if (!canWrite) throw ReadOnlyAccessException(action);
  }

  /// [checkSend] for every command in a transaction; one write refuses it all.
  void checkTransaction(
      Iterable<MapEntry<JNAPAction, Map<String, dynamic>>> commands) {
    if (canWrite) return;
    final write = firstJNAPTransactionWrite(commands);
    if (write != null) {
      throw ReadOnlyAccessException(write);
    }
  }

  @override
  List<Object?> get props => [canWrite];
}

/// How many writes the read-only policy has refused.
///
/// A count rather than a flag, for the same reason as `routerUnreachableProvider`:
/// every refusal has to be told to the user, including the second one in a row.
/// Callers handle a failed write in many ways - several just dismiss the spinner
/// - so the app root listens here and says why, whatever the caller did.
final readOnlyRefusalProvider = StateProvider<int>((ref) => 0);

/// Runs [check] and, when it refuses a write, reports the refusal through
/// [readOnlyRefusalProvider] before letting it propagate.
///
/// Every refusal goes through here - the JNAP gate and anything that writes to
/// the router some other way - so none of them can go unexplained.
void enforceAccess(Ref ref, void Function(AccessPolicy policy) check) {
  try {
    check(ref.read(accessPolicyProvider));
  } on ReadOnlyAccessException catch (e) {
    logger.i('[Access]: $e');
    ref.read(readOnlyRefusalProvider.notifier).state++;
    rethrow;
  }
}

/// Whether this build holds remote logins to read-only.
///
/// A provider rather than a direct read of [BuildConfig.remoteReadOnly] only so
/// tests can reach both branches; the value is fixed per compilation.
final remoteReadOnlyEnabledProvider =
    Provider<bool>((ref) => BuildConfig.remoteReadOnly);

/// Whether the router is being reached through a remote (cloud) login.
///
/// Keyed on how the user logged in, not on the `force` build flag, which only
/// picks the transport: a Guardian reaching the router through the cloud is a
/// remote login whatever build they came in on. The one answer to "is this
/// remote" for anything that is not about writing - a feature that simply does
/// not work over a remote session, for instance.
final isRemoteLoginProvider = Provider<bool>((ref) =>
    ref.watch(authProvider.select((auth) => auth.value?.loginType)) ==
    LoginType.remote);

final accessPolicyProvider = Provider<AccessPolicy>((ref) {
  final readOnly = ref.watch(isRemoteLoginProvider) &&
      ref.watch(remoteReadOnlyEnabledProvider);
  return readOnly ? const AccessPolicy(canWrite: false) : AccessPolicy.full;
});
