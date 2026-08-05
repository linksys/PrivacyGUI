import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/ai/ai_logging.dart';
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

  /// Keys whose write never completes, to exercise the operation timeout.
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
      throw Exception('write failed');
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
          throwsA(isA<Exception>()),
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
        await expectLater(failing, throwsA(isA<Exception>()));

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

      test('a hung operation does not block the queue forever', () {
        // The failure this guards: the user presses "change configuration"
        // behind a write that never settles, so the clear never runs and the
        // revoked credentials are restored on the next launch.
        fakeAsync((async) {
          // Built inside the zone: the operation chain starts from a
          // Future.value(), and one created outside would schedule its
          // continuations on a microtask queue this zone never flushes.
          storage = FakeSecureStorage();
          store = AwsCredentialsStore(storage);
          storage.hangWritesFor.add(recordKey);
          storage.values[recordKey] = 'stale';

          Object? storeError;
          var cleared = false;
          store
              .store(
                accessKeyId: 'AKIAEXAMPLE',
                secretAccessKey: 'secret',
                modelId: 'model-a',
              )
              .catchError((Object e) => storeError = e);
          store.clear().then((_) => cleared = true);

          async.elapse(const Duration(seconds: 30));

          expect(storeError, isA<TimeoutException>(),
              reason: 'the stalled write must be abandoned, not awaited');
          expect(cleared, isTrue,
              reason: 'the clear must still run once the write times out');
          expect(storage.values, isEmpty);
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
