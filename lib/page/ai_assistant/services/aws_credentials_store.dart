import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/ai/ai_logging.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Single key holding the whole record.
///
/// One key rather than three is what makes a write atomic from a reader's point
/// of view: a failed write leaves the previous record intact instead of mixing a
/// new access key with an old secret, which would surface as an opaque signing
/// failure rather than "not configured".
const _kRecordKey = 'ai_assistant_aws_credentials';

/// How long a caller waits for its own operation before being told it failed.
///
/// This bounds the *reported* wait, not the operation. A stalled platform call
/// keeps its place in the queue — see [AwsCredentialsStore._serialize] for why
/// abandoning that place is unsafe — so this only stops a caller (a `View`
/// awaiting a restore, say) from hanging on a keychain that never answers.
const _kCallerTimeout = Duration(seconds: 10);

final awsCredentialsStoreProvider = Provider<AwsCredentialsStore>((ref) {
  return AwsCredentialsStore(const FlutterSecureStorage());
});

/// Bedrock credentials entered by the user, held in encrypted storage.
///
/// Only exists so the credentials survive an app restart — without it the user
/// re-types an access key and secret key on every launch. It is deliberately
/// not a general settings store.
///
/// The proper long-term answer is for the app never to hold AWS credentials at
/// all (a backend proxy would sign the requests), so nothing here should grow
/// into an abstraction that makes the current arrangement look permanent.
///
/// ## Ordering
///
/// Every operation runs through [_serialize], so a `store()` can never land
/// after a `clear()` that the user triggered later. Callers commonly fire these
/// without awaiting (a storage failure must not break a working session), and
/// without serialisation the writes of a connect could overtake the deletes of
/// the "change configuration" that followed it — resurrecting credentials the
/// user had just discarded.
///
/// Operations never overlap, even when one stalls: [_kCallerTimeout] bounds what
/// a caller waits for, not the operation itself. See [_serialize] — abandoning a
/// stalled operation's place in the queue is what makes credentials go missing
/// or come back.
///
/// The ordering guarantee holds because [awsCredentialsStoreProvider] is a
/// plain [Provider], i.e. one instance for the session. Making it `autoDispose`
/// would hand out fresh chains and revive the race invisibly.
///
/// ## Errors
///
/// Every method throws only [ServiceError] subtypes — [StorageError] for a
/// platform storage failure, [TimeoutError] when an operation exceeds
/// [_kCallerTimeout]. `FlutterSecureStorage`'s `PlatformException` never
/// leaves this class, so no caller has to reason about platform-specific error
/// shapes (constitution Art. XIII §13.1).
///
/// Callers are expected to log these rather than show them: persistence is a
/// convenience, and a failure to save leaves a working session untouched. The
/// user has nothing to act on, so surfacing it would be noise.
class AwsCredentialsStore {
  AwsCredentialsStore(this._storage);

  final FlutterSecureStorage _storage;

  /// Tail of the operation chain; each new operation is appended to it.
  Future<void> _pending = Future.value();

  /// Run [operation] after every operation requested before it.
  ///
  /// The queue waits for each operation to genuinely settle; only the future
  /// handed back to the caller is time-bounded.
  ///
  /// ## Why the timeout must not apply to the queue
  ///
  /// `Future.timeout` does not cancel the operation it wraps — it only stops
  /// waiting. So timing out the *queue* does not remove a stalled platform call;
  /// it lets the next operation start while that call is still in flight, and
  /// whichever finishes last wins at the storage layer. Every ordering
  /// guarantee this class exists to provide is lost at that moment:
  ///
  /// * a stalled `clear()` can delete credentials the user entered afterwards,
  ///   while their `store()` reports success
  /// * a stalled `store()` can restore credentials a later `clear()` removed
  /// * a stalled `storeModelId()` — a read-modify-write — can rewrite the whole
  ///   record from its stale snapshot over newer credentials, with no `clear()`
  ///   involved at all
  ///
  /// Guarding writes with a "has a clear happened since?" counter cannot fix
  /// this: it answers a different question than the one that matters, which is
  /// whether the record in storage is still the one this operation wrote. Since
  /// the platform gives no way to cancel and `write` is not conditional, the
  /// only sound answer is to never let two operations overlap.
  ///
  /// The cost is that one hung platform call blocks the operations behind it for
  /// as long as it hangs, and since the platform never reports back, that can be
  /// the rest of the session. Accepted for writes, whose worst case is a stale
  /// record. NOT accepted for [clear] — see [_forceClear], because a revocation
  /// that can never be applied is the one failure this class must not have.
  Future<T> _serialize<T>(Future<T> Function() operation) {
    final settled = _pending.then((_) => operation());
    // Chained to the real completion, so nothing starts early. This also
    // handles a late failure: without a listener, an operation that fails after
    // its caller's timeout has stopped watching becomes an unhandled async
    // error.
    _pending = settled.then((_) {}, onError: (Object e) {
      aiLog('[Credentials] Operation failed after its caller stopped waiting: '
          '${e.runtimeType}');
    });
    return settled
        .timeout(_kCallerTimeout)
        .onError<Object>((e, _) => throw _asServiceError(e));
  }

  /// Convert anything storage throws into a [ServiceError].
  ///
  /// The platform error goes on `originalError`, never into `detail`. `detail`
  /// is the field a localizer may choose to surface — `localizeServiceError`
  /// already does for `UnexpectedError` — and a keychain error code or a web
  /// `localStorage` message is not something a user can act on. Keeping it out
  /// means the leak cannot happen even if the mapping changes later.
  /// `mapUspErrorToServiceError` makes the same call for an unparseable error.
  ///
  /// The `TimeoutError` detail is a fixed string naming the operation, not
  /// error text — safe by construction, and useful in a log.
  ServiceError _asServiceError(Object error) {
    if (error is ServiceError) return error;
    if (error is TimeoutException) {
      return const TimeoutError(detail: 'credential storage');
    }
    return StorageError(originalError: error);
  }

  /// Persist the credentials and the selected model.
  ///
  /// Values are never logged. Throws [StorageError] or [TimeoutError].
  ///
  /// A [TimeoutError] means only that the platform has not answered yet — the
  /// write is still queued and will still be applied in order.
  Future<void> store({
    required String accessKeyId,
    required String secretAccessKey,
    required String modelId,
  }) {
    return _serialize(() async {
      await _storage.write(
        key: _kRecordKey,
        value: jsonEncode({
          'accessKeyId': accessKeyId,
          'secretAccessKey': secretAccessKey,
          'modelId': modelId,
        }),
      );
      aiLog('[Credentials] Stored');
    });
  }

  /// As [read], but giving up after `min(within, _kCallerTimeout)`.
  ///
  /// For a caller that is holding UI hostage while it waits — the config screen
  /// disables itself during a restore — and would rather show an empty form
  /// sooner than the default allows. Wrapping `read()` in `.timeout()` at the
  /// call site instead would throw a bare `TimeoutException`, breaking this
  /// class's guarantee that callers only ever see a [ServiceError].
  ///
  /// The bound is a minimum, not a replacement: `read()` is already bounded by
  /// [_kCallerTimeout], so a [within] longer than that has no effect. Asserted
  /// rather than left as a trap for a future caller.
  Future<StoredAwsCredentials?> readWithin(Duration within) {
    assert(within <= _kCallerTimeout,
        'readWithin cannot extend the bound past _kCallerTimeout');
    return read()
        .timeout(within)
        .onError<Object>((e, _) => throw _asServiceError(e));
  }

  /// The stored credentials, or null when nothing usable is saved.
  ///
  /// Returns null rather than a half-built record for anything unusable —
  /// absent, blank, or unparseable — so the caller's "not configured" path
  /// handles it instead of a signing error later. A bad record is therefore not
  /// an error; only storage itself failing is ([StorageError], [TimeoutError]).
  Future<StoredAwsCredentials?> read() {
    return _serialize(() async {
      final record = await _readRecord();
      if (record == null) return null;

      final accessKeyId = _stringOrNull(record['accessKeyId']) ?? '';
      final secretAccessKey = _stringOrNull(record['secretAccessKey']) ?? '';
      // Blank is as unusable as absent, and whitespace reaching the form would
      // overwrite what the user typed with something that cannot connect.
      if (accessKeyId.isEmpty || secretAccessKey.isEmpty) return null;

      return StoredAwsCredentials(
        accessKeyId: accessKeyId,
        secretAccessKey: secretAccessKey,
        // A model may be missing if it was never chosen; the caller falls back
        // to its own default rather than being forced to re-enter everything.
        modelId: _stringOrNull(record['modelId']),
      );
    });
  }

  /// Replace only the stored model, keeping the credentials.
  ///
  /// Does nothing when there is no record to update — there is no useful
  /// meaning to a model preference without credentials to use it with.
  Future<void> storeModelId(String modelId) {
    return _serialize(() async {
      final record = await _readRecord();
      if (record == null) return;

      record['modelId'] = modelId;
      await _storage.write(key: _kRecordKey, value: jsonEncode(record));
      aiLog('[Credentials] Model updated');
    });
  }

  /// Remove the stored credentials.
  ///
  /// This is the revocation path — the user pressing "change configuration"
  /// means they want these credentials gone.
  ///
  /// Ordinarily queued like everything else, so it cannot be undone by a write
  /// requested before it. But a queue held by a platform call that never returns
  /// would mean a revocation is never applied and the record silently restores
  /// on the next launch, so this one operation escapes that: see [_forceClear].
  Future<void> clear() {
    final queued = _serialize(() async {
      await _storage.delete(key: _kRecordKey);
      aiLog('[Credentials] Cleared');
    });
    return queued
        .onError<TimeoutError>((_, __) => _clearOutOfBand().then((_) {}));
  }

  /// Delete outside the queue, unless the queued delete already landed.
  ///
  /// The check first, because a slow-but-moving queue often applies its delete
  /// while the caller's bound is elapsing — and skipping the queue is a
  /// concession that should not be made when it is not needed.
  Future<void> _clearOutOfBand() async {
    if (await _isRecordAbsent()) {
      aiLog('[Credentials] Queued clear landed after its caller gave up');
      return;
    }
    return _forceClear();
  }

  Future<bool> _isRecordAbsent() async {
    try {
      final raw =
          await _storage.read(key: _kRecordKey).timeout(_kCallerTimeout);
      return raw == null || raw.isEmpty;
    } catch (_) {
      // Cannot tell; assume it is still there so the delete is attempted.
      return false;
    }
  }

  /// Delete the record without waiting for the queue.
  ///
  /// Reached only when a queued [clear] timed out, which means some earlier
  /// platform call has not returned. Skipping the queue reintroduces the overlap
  /// [_serialize] exists to prevent — deliberately, and only here:
  ///
  /// * the racing operation can only be a write, and the user has since asked
  ///   for the record to be gone, so if the delete loses the race the outcome is
  ///   the same stale record we already had, not a worse one
  /// * whereas not trying at all means the revocation is never applied and the
  ///   credentials come back on the next launch
  ///
  /// The queued attempt is left running: if it eventually completes, it deletes
  /// an already-deleted key, which is a no-op.
  Future<void> _forceClear() async {
    aiLog('[Credentials] Queue stalled; deleting outside it');
    try {
      await _storage.delete(key: _kRecordKey).timeout(_kCallerTimeout);
      aiLog('[Credentials] Cleared out of band');
    } catch (e) {
      // The caller shows this one, unlike other storage failures: the user
      // believes these credentials are gone and they are not.
      aiLog('[Credentials] Out-of-band clear failed: ${e.runtimeType}');
      throw _asServiceError(e);
    }
  }

  /// The stored record as a map, or null when there is nothing usable.
  ///
  /// Never throws on a bad value: absent, blank, non-JSON and non-object all
  /// collapse to null, so both callers can treat "unusable" as "not
  /// configured" rather than having to catch.
  Future<Map<String, dynamic>?> _readRecord() async {
    final raw = await _storage.read(key: _kRecordKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        aiLog('[Credentials] Discarding unreadable record');
        return null;
      }
      return decoded;
    } catch (_) {
      // Corrupted or externally tampered value; treat as not configured.
      aiLog('[Credentials] Discarding unreadable record');
      return null;
    }
  }

  /// A trimmed non-empty String, or null for anything else.
  ///
  /// A tampered record can hold a number, bool or list where a String belongs.
  /// Returning null keeps [read]'s "unusable means not configured" contract
  /// instead of throwing a cast error at the caller.
  static String? _stringOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Credentials loaded from storage.
class StoredAwsCredentials {
  const StoredAwsCredentials({
    required this.accessKeyId,
    required this.secretAccessKey,
    this.modelId,
  });

  final String accessKeyId;
  final String secretAccessKey;

  /// Model chosen when these credentials were saved, if any.
  final String? modelId;
}
