import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/ai/ai_logging.dart';

/// Single key holding the whole record.
///
/// One key rather than three is what makes a write atomic from a reader's point
/// of view: a failed write leaves the previous record intact instead of mixing a
/// new access key with an old secret, which would surface as an opaque signing
/// failure rather than "not configured".
const _kRecordKey = 'ai_assistant_aws_credentials';

/// How long a single storage operation may take before the chain gives up.
///
/// Without this, one hung `write` blocks every operation queued behind it — the
/// user's `clear()` included, so "change configuration" would never take effect
/// and the config screen would stay disabled with no error.
const _kOperationTimeout = Duration(seconds: 10);

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
/// Each operation is bounded by [_kOperationTimeout] so one that never settles
/// cannot hold the queue — and with it the user's `clear()` — indefinitely.
///
/// The ordering guarantee holds because [awsCredentialsStoreProvider] is a
/// plain [Provider], i.e. one instance for the session. Making it `autoDispose`
/// would hand out fresh chains and revive the race invisibly.
class AwsCredentialsStore {
  AwsCredentialsStore(this._storage);

  final FlutterSecureStorage _storage;

  /// Tail of the operation chain; each new operation is appended to it.
  Future<void> _pending = Future.value();

  /// Run [operation] after every operation requested before it.
  ///
  /// The chain is never broken by a failure: the tail swallows errors so a
  /// rejected write cannot stop later operations from running, while the
  /// returned future still reports the failure to this caller. A timeout counts
  /// as a failure, which is what stops a stalled operation from blocking the
  /// queue forever.
  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result =
        _pending.then((_) => operation().timeout(_kOperationTimeout));
    _pending = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Persist the credentials and the selected model.
  ///
  /// Values are never logged.
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

  /// The stored credentials, or null when nothing usable is saved.
  ///
  /// Returns null rather than a half-built record for anything unusable —
  /// absent, blank, or unparseable — so the caller's "not configured" path
  /// handles it instead of a signing error later.
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

  Future<void> clear() {
    return _serialize(() async {
      await _storage.delete(key: _kRecordKey);
      aiLog('[Credentials] Cleared');
    });
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
