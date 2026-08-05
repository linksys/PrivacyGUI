import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Single key holding the whole record.
///
/// One key rather than three is what makes a write atomic from a reader's point
/// of view: a failed write leaves the previous record intact instead of mixing a
/// new access key with an old secret, which would surface as an opaque signing
/// failure rather than "not configured".
const _kRecordKey = 'ai_assistant_aws_credentials';

/// Keys written by the previous three-key layout, removed on write and clear so
/// stale halves cannot linger after an upgrade.
const _kLegacyKeys = [
  'ai_assistant_aws_access_key_id',
  'ai_assistant_aws_secret_access_key',
  'ai_assistant_bedrock_model_id',
];

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
class AwsCredentialsStore {
  AwsCredentialsStore(this._storage);

  final FlutterSecureStorage _storage;

  /// Tail of the operation chain; each new operation is appended to it.
  Future<void> _pending = Future.value();

  /// Run [operation] after every operation requested before it.
  ///
  /// The chain is never broken by a failure: the tail swallows errors so a
  /// rejected write cannot stop later operations from running, while the
  /// returned future still reports the failure to this caller.
  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
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
      await _deleteLegacyKeys();
      logger.d('[AI][Credentials] Stored');
    });
  }

  /// The stored credentials, or null when nothing usable is saved.
  ///
  /// Returns null rather than a half-built record for anything unusable —
  /// absent, blank, or unparseable — so the caller's "not configured" path
  /// handles it instead of a signing error later.
  Future<StoredAwsCredentials?> read() {
    return _serialize(() async {
      final raw = await _storage.read(key: _kRecordKey);
      if (raw == null || raw.isEmpty) return null;

      final Map<String, dynamic> record;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) return null;
        record = decoded;
      } catch (e) {
        // Corrupted or externally tampered value; treat as not configured.
        logger.d('[AI][Credentials] Discarding unreadable record');
        return null;
      }

      final accessKeyId = (record['accessKeyId'] as String?)?.trim() ?? '';
      final secretAccessKey =
          (record['secretAccessKey'] as String?)?.trim() ?? '';
      // Blank is as unusable as absent, and whitespace reaching the form would
      // overwrite what the user typed with something that cannot connect.
      if (accessKeyId.isEmpty || secretAccessKey.isEmpty) return null;

      final modelId = (record['modelId'] as String?)?.trim();
      return StoredAwsCredentials(
        accessKeyId: accessKeyId,
        secretAccessKey: secretAccessKey,
        // A model may be missing if it was never chosen; the caller falls back
        // to its own default rather than being forced to re-enter everything.
        modelId: (modelId == null || modelId.isEmpty) ? null : modelId,
      );
    });
  }

  /// Replace only the stored model, keeping the credentials.
  ///
  /// Does nothing when there is no record to update — there is no useful
  /// meaning to a model preference without credentials to use it with.
  Future<void> storeModelId(String modelId) {
    return _serialize(() async {
      final raw = await _storage.read(key: _kRecordKey);
      if (raw == null || raw.isEmpty) return;

      final Map<String, dynamic> record;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) return;
        record = decoded;
      } catch (e) {
        return;
      }

      record['modelId'] = modelId;
      await _storage.write(key: _kRecordKey, value: jsonEncode(record));
      logger.d('[AI][Credentials] Model updated');
    });
  }

  Future<void> clear() {
    return _serialize(() async {
      await _storage.delete(key: _kRecordKey);
      await _deleteLegacyKeys();
      logger.d('[AI][Credentials] Cleared');
    });
  }

  Future<void> _deleteLegacyKeys() async {
    for (final key in _kLegacyKeys) {
      await _storage.delete(key: key);
    }
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
