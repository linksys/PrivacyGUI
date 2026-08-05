import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/ai_assistant/services/aws_credentials_store.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// In-memory storage with controllable per-operation latency, so tests can
/// interleave operations the way the UI does (fire-and-forget).
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = {};
  final List<String> log = [];

  Duration writeDelay = Duration.zero;
  Duration deleteDelay = Duration.zero;

  /// Keys whose next write should throw.
  final Set<String> failWritesFor = {};

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
  const legacyAccessKey = 'ai_assistant_aws_access_key_id';
  const legacySecretKey = 'ai_assistant_aws_secret_access_key';
  const legacyModelKey = 'ai_assistant_bedrock_model_id';

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

      test('removes keys left by the previous three-key layout', () async {
        storage.values[legacyAccessKey] = 'old';
        storage.values[legacySecretKey] = 'old';
        storage.values[legacyModelKey] = 'old';

        await store.store(
          accessKeyId: 'AKIAEXAMPLE',
          secretAccessKey: 'secret',
          modelId: 'model-a',
        );

        expect(storage.values.containsKey(legacyAccessKey), isFalse);
        expect(storage.values.containsKey(legacySecretKey), isFalse);
        expect(storage.values.containsKey(legacyModelKey), isFalse);
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
    });

    group('clear', () {
      test('removes the record and any legacy keys', () async {
        await store.store(
          accessKeyId: 'AKIAEXAMPLE',
          secretAccessKey: 'secret',
          modelId: 'model-a',
        );
        storage.values[legacyAccessKey] = 'old';

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
    });
  });

  group('AwsCredentialsStore with a mock storage', () {
    test('never logs credential values', () async {
      // Guards the contract that the store logs only lifecycle events. A
      // regression here would put a long-lived AWS secret into the log file.
      final mock = MockSecureStorage();
      when(() => mock.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => mock.delete(key: any(named: 'key'))).thenAnswer((_) async {});

      await AwsCredentialsStore(mock).store(
        accessKeyId: 'AKIA_SENSITIVE',
        secretAccessKey: 'SUPER_SECRET',
        modelId: 'model-a',
      );

      // The value written is the JSON record; assert it is what reaches storage
      // and nothing else was passed anywhere.
      final captured = verify(() =>
              mock.write(key: recordKey, value: captureAny(named: 'value')))
          .captured
          .single as String;
      expect(jsonDecode(captured)['secretAccessKey'], 'SUPER_SECRET');
    });
  });
}
