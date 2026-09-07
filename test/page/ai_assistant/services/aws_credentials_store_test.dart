import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/ai/ai_logging.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/ai_assistant/services/aws_credentials_store.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// In-memory storage with controllable per-operation latency, so tests can
/// interleave operations the way the UI does (fire-and-forget).
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = {};

  /// Ordered record of the operations that reached storage, so a test can pin
  /// the ordering contract rather than only its outcome.
  final List<String> log = [];

  Duration writeDelay = Duration.zero;
  Duration deleteDelay = Duration.zero;

  /// Keys whose next write should throw.
  final Set<String> failWritesFor = {};

  /// Keys whose read should throw, as a platform failure would.
  final Set<String> failReadsFor = {};

  /// Keys whose write never completes, standing in for a keychain that never
  /// answers — the case where the caller must be told while the queue waits.
  final Set<String> hangWritesFor = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (hangWritesFor.contains(key)) {
      log.add('W…$key');
      return Completer<void>().future;
    }
    if (writeDelay > Duration.zero) await Future.delayed(writeDelay);
    if (failWritesFor.contains(key)) {
      log.add('W!$key');
      throw PlatformException(code: 'write_error', message: 'keychain failure');
    }
    log.add('W:$key');
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failReadsFor.contains(key)) {
      log.add('R!$key');
      throw PlatformException(code: 'read_error', message: 'keychain failure');
    }
    log.add('R:$key');
    return values[key];
  }

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (deleteDelay > Duration.zero) await Future.delayed(deleteDelay);
    log.add('D:$key');
    values.remove(key);
  }
}

void main() {
  const recordKey = 'ai_assistant_aws_credentials';

  group('AwsCredentialsStore', () {
    late FakeSecureStorage storage;
    late AwsCredentialsStore store;

    setUp(() {
      storage = FakeSecureStorage();
      store = AwsCredentialsStore(storage);
    });

    group('store', () {
      test('writes the record as one value', () async {
        await store.store(
          accessKeyId: 'AKIAEXAMPLE',
          secretAccessKey: 'secret',
          modelId: 'model-a',
        );

        expect(jsonDecode(storage.values[recordKey]!), {
          'accessKeyId': 'AKIAEXAMPLE',
          'secretAccessKey': 'secret',
          'modelId': 'model-a',
        });
      });

      test('touches only the record key', () async {
        await store.store(
          accessKeyId: 'AKIAEXAMPLE',
          secretAccessKey: 'secret',
          modelId: 'model-a',
        );

        expect(storage.log, ['W:$recordKey'],
            reason: 'one write is the whole operation; extra keys would cost '
                'a round trip and could leave a stale half behind');
      });

      test('a failed re-save leaves the previous record intact', () async {
        await store.store(
          accessKeyId: 'AKIA_OLD',
          secretAccessKey: 'secret_old',
          modelId: 'model-old',
        );

        storage.failWritesFor.add(recordKey);
        await expectLater(
          store.store(
            accessKeyId: 'AKIA_NEW',
            secretAccessKey: 'secret_new',
            modelId: 'model-new',
          ),
          throwsA(isA<StorageError>()),
        );

        final result = await store.read();
        expect(result!.accessKeyId, 'AKIA_OLD');
        expect(result.secretAccessKey, 'secret_old',
            reason: 'a single record cannot mix a new key with an old secret, '
                'which would fail at signing time with an opaque error');
      });
    });

    group('read', () {
      test('returns the stored credentials', () async {
        await store.store(
          accessKeyId: 'AKIAEXAMPLE',
          secretAccessKey: 'secret',
          modelId: 'model-a',
        );

        final result = await store.read();

        expect(result!.accessKeyId, 'AKIAEXAMPLE');
        expect(result.secretAccessKey, 'secret');
        expect(result.modelId, 'model-a');
      });

      test('returns null when nothing is stored', () async {
        expect(await store.read(), isNull);
      });

      test('returns null for a record with a blank secret', () async {
        storage.values[recordKey] = jsonEncode({
          'accessKeyId': 'AKIAEXAMPLE',
          'secretAccessKey': '',
          'modelId': 'm'
        });

        expect(await store.read(), isNull);
      });

      test('treats whitespace-only values as absent', () async {
        storage.values[recordKey] = jsonEncode({
          'accessKeyId': '   ',
          'secretAccessKey': '  ',
          'modelId': 'm',
        });

        expect(await store.read(), isNull,
            reason: 'whitespace reaching the form would overwrite what the '
                'user typed with something that cannot connect');
      });

      test('returns null for an unreadable record', () async {
        storage.values[recordKey] = 'not json at all';

        expect(await store.read(), isNull);
      });

      test('returns null when the record is not an object', () async {
        storage.values[recordKey] = jsonEncode(['unexpected']);

        expect(await store.read(), isNull);
      });

      test('returns null when a field holds the wrong JSON type', () async {
        storage.values[recordKey] = jsonEncode({
          'accessKeyId': 12345,
          'secretAccessKey': true,
          'modelId': ['m'],
        });

        // A tampered record must take the "not configured" path rather than
        // throwing a cast error the caller has no reason to expect.
        expect(await store.read(), isNull);
      });

      test('ignores a non-String model rather than failing the read', () async {
        storage.values[recordKey] = jsonEncode({
          'accessKeyId': 'AKIAEXAMPLE',
          'secretAccessKey': 'secret',
          'modelId': 42,
        });

        final result = await store.read();

        expect(result, isNotNull,
            reason: 'usable credentials must survive a bad model field');
        expect(result!.modelId, isNull);
      });

      test('trims stored values', () async {
        storage.values[recordKey] = jsonEncode({
          'accessKeyId': '  AKIAEXAMPLE  ',
          'secretAccessKey': ' secret ',
          'modelId': ' model-a ',
        });

        final result = await store.read();

        expect(result!.accessKeyId, 'AKIAEXAMPLE');
        expect(result.secretAccessKey, 'secret');
        expect(result.modelId, 'model-a');
      });

      test('returns a null model when none was saved', () async {
        storage.values[recordKey] = jsonEncode(
            {'accessKeyId': 'AKIAEXAMPLE', 'secretAccessKey': 'secret'});

        final result = await store.read();

        expect(result, isNotNull);
        expect(result!.modelId, isNull,
            reason: 'the caller falls back to its own default rather than '
                'discarding usable credentials');
      });
    });

    group('storeModelId', () {
      test('updates only the model, keeping the credentials', () async {
        await store.store(
          accessKeyId: 'AKIAEXAMPLE',
          secretAccessKey: 'secret',
          modelId: 'model-a',
        );

        await store.storeModelId('model-b');

        final result = await store.read();
        expect(result!.modelId, 'model-b');
        expect(result.accessKeyId, 'AKIAEXAMPLE');
        expect(result.secretAccessKey, 'secret');
      });

      test('does nothing when there is no record', () async {
        await store.storeModelId('model-b');

        expect(storage.values.containsKey(recordKey), isFalse,
            reason: 'a model preference with no credentials is meaningless');
      });

      test('reports an unreadable record the same way read() does', () async {
        storage.values[recordKey] = 'not json at all';
        final lines = captureAiLogs();
        addTearDown(resetAiLoggingForTest);

        await store.storeModelId('model-b');

        // One failure class, one diagnostic: a silent return here would leave
        // no trace of why the preference was dropped.
        expect(
            lines,
            contains('[AI]: [Credentials] Discarding unreadable '
                'record'));
        expect(storage.values[recordKey], 'not json at all',
            reason: 'a corrupt record must not be overwritten with a '
                'model-only jsonEncode of it');
      });
    });

    group('readWithin', () {
      test('gives up sooner than the default, still as a ServiceError', () {
        // Exists so a caller that needs a shorter bound does not wrap `read()`
        // in `.timeout()` itself, which would throw a bare TimeoutException and
        // break this class's only-ServiceError contract.
        fakeAsync((async) {
          storage = FakeSecureStorage();
          store = AwsCredentialsStore(storage);
          storage.hangWritesFor.add(recordKey);
          // Occupy the queue so the read cannot start.
          store
              .store(
                accessKeyId: 'AKIAEXAMPLE',
                secretAccessKey: 'secret',
                modelId: 'model-a',
              )
              .catchError((Object e) {});

          Object? error;
          store
              .readWithin(const Duration(seconds: 2))
              .then<void>((_) {})
              .onError<Object>((Object e, _) => error = e);

          async.elapse(const Duration(seconds: 3));

          // What matters to the caller: a shorter bound is honoured, and what
          // comes out is still the class's own error type. Which of the two
          // bounds fired is an implementation detail.
          expect(error, isA<TimeoutError>());
          expect(error, isNot(isA<TimeoutException>()),
              reason: 'the dart:async type must not reach the View');
        });
      });

      test('returns the record when it arrives in time', () async {
        await store.store(
          accessKeyId: 'AKIAEXAMPLE',
          secretAccessKey: 'secret',
          modelId: 'model-a',
        );

        final result = await store.readWithin(const Duration(seconds: 5));

        expect(result?.accessKeyId, 'AKIAEXAMPLE');
      });
    });

    group('error mapping', () {
      test('a platform failure surfaces as StorageError, not PlatformException',
          () async {
        storage.failWritesFor.add(recordKey);

        // Art. XIII §13.1: the service layer is the conversion point, so no
        // caller has to reason about platform-specific error shapes.
        await expectLater(
          store.store(
            accessKeyId: 'AKIAEXAMPLE',
            secretAccessKey: 'secret',
            modelId: 'model-a',
          ),
          throwsA(isA<StorageError>()),
        );
      });

      test('keeps the platform error for the log but not for display',
          () async {
        storage.failReadsFor.add(recordKey);

        final error = await store.read().then<Object?>((_) => null,
            onError: (Object e) => e) as StorageError;

        expect(error.originalError, isNotNull,
            reason: 'the technical text stays available to logger.e');
        expect(error.detail, isNull,
            reason: 'localizeServiceError surfaces detail to the user, and a '
                'keychain code is not actionable — it must stay out');
      });

      test('every operation converts, not just writes', () async {
        storage.failReadsFor.add(recordKey);

        await expectLater(store.read(), throwsA(isA<StorageError>()));
      });
    });

    group('clear', () {
      test('removes the record', () async {
        await store.store(
          accessKeyId: 'AKIAEXAMPLE',
          secretAccessKey: 'secret',
          modelId: 'model-a',
        );

        await store.clear();

        expect(storage.values, isEmpty);
        expect(await store.read(), isNull);
      });
    });

    group('operation ordering', () {
      test('a slow store cannot land after a later clear', () async {
        // The UI fires both without awaiting; the store's writes are slow and
        // the clear's deletes are fast.
        storage.writeDelay = const Duration(milliseconds: 30);
        storage.deleteDelay = const Duration(milliseconds: 1);

        final storing = store.store(
          accessKeyId: 'AKIA_REVOKED',
          secretAccessKey: 'secret_revoked',
          modelId: 'model-a',
        );
        final clearing = store.clear();

        await Future.wait([storing, clearing]);

        expect(storage.values, isEmpty,
            reason: 'credentials the user asked to remove must not be '
                'resurrected by an in-flight write');
        expect(await store.read(), isNull);
      });

      test('a failed operation does not stall the ones queued behind it',
          () async {
        storage.failWritesFor.add(recordKey);
        final failing = store.store(
          accessKeyId: 'AKIAEXAMPLE',
          secretAccessKey: 'secret',
          modelId: 'model-a',
        );
        await expectLater(failing, throwsA(isA<StorageError>()));

        storage.failWritesFor.clear();
        await store.store(
          accessKeyId: 'AKIA_SECOND',
          secretAccessKey: 'secret_second',
          modelId: 'model-b',
        );

        final result = await store.read();
        expect(result!.accessKeyId, 'AKIA_SECOND');
      });

      test('reads see the result of a write requested before them', () async {
        storage.writeDelay = const Duration(milliseconds: 20);

        // Not awaited, exactly as the view does it.
        store.store(
          accessKeyId: 'AKIAEXAMPLE',
          secretAccessKey: 'secret',
          modelId: 'model-a',
        );
        final result = await store.read();

        expect(result?.accessKeyId, 'AKIAEXAMPLE');
      });

      test('a stalled write cannot be overtaken by the operations behind it',
          () {
        // `Future.timeout` does not cancel the operation it wraps. If the
        // timeout applied to the QUEUE, a stalled write would keep running while
        // the next operation started, and whichever finished last would win at
        // the storage layer — the ordering guarantee gone precisely when it is
        // needed. Storage order must follow request order regardless of latency.
        fakeAsync((async) {
          storage = FakeSecureStorage();
          store = AwsCredentialsStore(storage);
          // Far longer than the caller timeout, but it does eventually finish.
          storage.writeDelay = const Duration(seconds: 25);

          Object? storeError;
          store
              .store(
                accessKeyId: 'AKIA_REVOKED',
                secretAccessKey: 'secret_revoked',
                modelId: 'model-a',
              )
              .catchError((Object e) => storeError = e);
          store.clear().catchError((Object e) {});

          async.elapse(const Duration(seconds: 120));

          expect(storeError, isA<TimeoutError>(),
              reason: 'the caller is told promptly, even though the write is '
                  'still queued');
          expect(storage.values, isEmpty,
              reason: 'the clear was requested second, so it must be applied '
                  'second — the revoked record must not survive');
          expect(storage.log.where((e) => !e.startsWith('R:')).toList(),
              ['W:$recordKey', 'D:$recordKey'],
              reason: 'storage order must match request order (reads excluded: '
                  'clear() checks whether its delete landed before escalating)');
        });
      });

      test('a clear requested while a write is in flight still wins', () {
        // Same guarantee from the other direction: here the write has already
        // reached storage when the clear is requested, so only strict ordering
        // makes the user's revocation stick.
        fakeAsync((async) {
          storage = FakeSecureStorage();
          store = AwsCredentialsStore(storage);
          storage.writeDelay = const Duration(seconds: 25);

          store
              .store(
                accessKeyId: 'AKIA_REVOKED',
                secretAccessKey: 'secret',
                modelId: 'model-a',
              )
              .catchError((Object e) {});
          async.elapse(const Duration(seconds: 1));
          store.clear().catchError((Object e) {});

          async.elapse(const Duration(seconds: 120));

          expect(storage.values, isEmpty,
              reason: 'the user asked to discard these credentials after the '
                  'write began; the request must still win');
        });
      });

      test('a slow write with nothing behind it is simply applied', () {
        // The negative case: latency alone must not cost the user their
        // credentials. Only a later request may override a write.
        fakeAsync((async) {
          storage = FakeSecureStorage();
          store = AwsCredentialsStore(storage);
          storage.writeDelay = const Duration(seconds: 25);

          store
              .store(
                accessKeyId: 'AKIAEXAMPLE',
                secretAccessKey: 'secret',
                modelId: 'model-a',
              )
              .catchError((Object e) {});

          async.elapse(const Duration(seconds: 60));

          expect(storage.values.containsKey(recordKey), isTrue);
          expect(storage.log.where((e) => e.startsWith('D:')), isEmpty,
              reason: 'nothing asked for a delete');
        });
      });

      test('a merely slow queue is left to apply the clear in order', () {
        // Escalating is a concession, so it must not happen just because the
        // caller's bound elapsed. A queue that is still moving applies the
        // delete in its proper place, and the out-of-band path checks for that
        // before acting.
        fakeAsync((async) {
          storage = FakeSecureStorage();
          store = AwsCredentialsStore(storage);
          // Slower than the caller bound, faster than the grace period.
          storage.writeDelay = const Duration(seconds: 15);

          store
              .store(
                accessKeyId: 'AKIAEXAMPLE',
                secretAccessKey: 'secret',
                modelId: 'model-a',
              )
              .catchError((Object e) {});
          store.clear().catchError((Object e) {});

          async.elapse(const Duration(minutes: 2));

          expect(storage.values, isEmpty);
          expect(storage.log.where((e) => e.startsWith('D:')).length, 1,
              reason: 'one delete, applied in order — no out-of-band retry');
        });
      });

      test('a revocation escapes a queue a hung write has stalled', () {
        // A platform call that never returns holds the queue for the rest of
        // the session, since nothing ever reports back. For writes that only
        // means a stale record. For a revocation it would mean the credentials
        // silently return on the next launch, so `clear()` falls back to
        // deleting outside the queue.
        fakeAsync((async) {
          storage = FakeSecureStorage();
          store = AwsCredentialsStore(storage);
          storage.hangWritesFor.add(recordKey);
          storage.values[recordKey] = 'stale';

          store
              .store(
                accessKeyId: 'AKIAEXAMPLE',
                secretAccessKey: 'secret',
                modelId: 'model-a',
              )
              .catchError((Object e) {});

          var cleared = false;
          store
              .clear()
              .then<void>((_) => cleared = true)
              .onError<Object>((Object e, _) {});

          async.elapse(const Duration(minutes: 2));

          expect(cleared, isTrue,
              reason: 'the user asked for these credentials to be gone');
          expect(storage.values, isEmpty,
              reason: 'and they must actually be gone, not merely queued');
        });
      });

      test('a hung write blocks the writes behind it, but not a revocation',
          () {
        // The trade-off, stated exactly. A platform call that never answers does
        // hold the queue — letting the next write start alongside it is what
        // allows a late write to resurrect revoked credentials. A stale record
        // is an acceptable outcome for that; a revocation that never applies is
        // not, so `clear()` is the one operation allowed out.
        fakeAsync((async) {
          storage = FakeSecureStorage();
          store = AwsCredentialsStore(storage);
          storage.hangWritesFor.add(recordKey);
          storage.values[recordKey] = 'stale';

          Object? storeError;
          store
              .store(
                accessKeyId: 'AKIAEXAMPLE',
                secretAccessKey: 'secret',
                modelId: 'model-a',
              )
              .catchError((Object e) => storeError = e);

          var modelUpdated = false;
          store
              .storeModelId('model-b')
              .then<void>((_) => modelUpdated = true)
              .onError<Object>((Object e, _) {});

          async.elapse(const Duration(minutes: 2));

          expect(storeError, isA<TimeoutError>(),
              reason: 'the caller must not wait on a keychain that never '
                  'answers');
          expect(modelUpdated, isFalse,
              reason: 'a write stays queued rather than running concurrently '
                  'with the hung one');
          expect(storage.log, ['W…$recordKey'],
              reason: 'no later write reached storage');
        });
      });
    });
  });

  group('logging', () {
    late FakeSecureStorage storage;
    late AwsCredentialsStore store;
    late List<String> lines;

    setUp(() {
      storage = FakeSecureStorage();
      store = AwsCredentialsStore(storage);
      lines = captureAiLogs();
    });

    tearDown(resetAiLoggingForTest);

    test('no credential value reaches the log', () async {
      // A regression here would put a long-lived AWS secret into the log file,
      // so assert on the emitted lines themselves rather than on what was
      // written to storage.
      await store.store(
        accessKeyId: 'AKIA_SENSITIVE',
        secretAccessKey: 'SUPER_SECRET',
        modelId: 'model-sensitive',
      );
      await store.read();
      await store.storeModelId('model-other');
      await store.clear();

      final logged = lines.join('\n');
      expect(logged, isNot(contains('AKIA_SENSITIVE')));
      expect(logged, isNot(contains('SUPER_SECRET')));
      expect(logged, isNot(contains('model-sensitive')),
          reason: 'even the model id is only ever a lifecycle detail here');
    });

    test('logs lifecycle events so a field report shows what happened',
        () async {
      await store.store(
        accessKeyId: 'AKIAEXAMPLE',
        secretAccessKey: 'secret',
        modelId: 'model-a',
      );
      await store.storeModelId('model-b');
      await store.clear();

      expect(lines, [
        '[AI]: [Credentials] Stored',
        '[AI]: [Credentials] Model updated',
        '[AI]: [Credentials] Cleared',
      ]);
    });
  });

  group('AwsCredentialsStore with a mock storage', () {
    test('writes the credentials as a single value under one key', () async {
      final mock = MockSecureStorage();
      when(() => mock.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await AwsCredentialsStore(mock).store(
        accessKeyId: 'AKIA_SENSITIVE',
        secretAccessKey: 'SUPER_SECRET',
        modelId: 'model-a',
      );

      final captured = verify(() =>
              mock.write(key: recordKey, value: captureAny(named: 'value')))
          .captured
          .single as String;
      expect(jsonDecode(captured)['secretAccessKey'], 'SUPER_SECRET');
      verifyNever(() => mock.delete(key: any(named: 'key')));
      verifyNoMoreInteractions(mock);
    });
  });
}
