import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/command/http/base_http_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/jnap/spec/jnap_spec.dart';

/// Records which actions got as far as being turned into a request, and fails
/// the request right there so nothing is put on a queue or sent. A refused write
/// must never show up here.
class _RecordingRepository extends RouterRepository {
  _RecordingRepository(super.ref);

  final built = <String>[];

  @override
  Future<BaseCommand<JNAPResult, JNAPCommandSpec>> createCommand(
    String action, {
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeaders = const {},
    bool needAuth = false,
    CommandType? type,
    bool fetchRemote = false,
    CacheLevel cacheLevel = CacheLevel.localCached,
    int timeoutMs = 10000,
    int retries = 1,
  }) async {
    built.add(action);
    throw const _Sent();
  }

  @override
  Future<TransactionHttpCommand> createTransaction(
    List<Map<String, dynamic>> payload, {
    bool needAuth = false,
    required List<JNAPAction> actions,
    bool fetchRemote = false,
    CacheLevel cacheLevel = CacheLevel.localCached,
    int timeoutMs = 10000,
    int retries = 1,
    CommandType? type,
  }) async {
    built.addAll(actions.map((a) => a.actionValue));
    throw const _Sent();
  }
}

/// Stands for "the request went ahead". Thrown by the fake so a test can tell a
/// request that was sent from one the gate refused.
class _Sent implements Exception {
  const _Sent();
}

void main() {
  setUpAll(initBetterActions);

  late ProviderContainer container;

  _RecordingRepository repositoryWith(AccessPolicy policy) {
    late _RecordingRepository repository;
    container = ProviderContainer(overrides: [
      accessPolicyProvider.overrideWithValue(policy),
      routerRepositoryProvider.overrideWith((ref) {
        return repository = _RecordingRepository(ref);
      }),
    ]);
    addTearDown(container.dispose);
    container.read(routerRepositoryProvider);
    return repository;
  }

  group('read-only access', () {
    const readOnly = AccessPolicy(canWrite: false);

    test('refuses a write before it becomes a request', () async {
      final repository = repositoryWith(readOnly);

      await expectLater(
        repository.send(JNAPAction.setWANSettings, data: {'x': 1}),
        throwsA(isA<ReadOnlyAccessException>()),
      );
      expect(repository.built, isEmpty,
          reason: 'a refused write must not reach the router');
    });

    // Callers handle a failed write in many different ways, several of them
    // silently. Reporting the refusal where the app root can see it is what
    // guarantees the user is told, whatever the caller does with the error.
    test('reports every refusal, so the app can say why', () async {
      final repository = repositoryWith(readOnly);
      expect(container.read(readOnlyRefusalProvider), 0);

      await expectLater(repository.send(JNAPAction.reboot),
          throwsA(isA<ReadOnlyAccessException>()));
      await expectLater(
          repository.transaction(JNAPTransactionBuilder(commands: [
            const MapEntry(JNAPAction.setWANSettings, {}),
          ])),
          throwsA(isA<ReadOnlyAccessException>()));

      expect(container.read(readOnlyRefusalProvider), 2);
    });

    test('a read is not reported', () async {
      final repository = repositoryWith(readOnly);

      await expectLater(
          repository.send(JNAPAction.getDeviceInfo), throwsA(isA<_Sent>()));

      expect(container.read(readOnlyRefusalProvider), 0);
    });

    test('still sends a read', () async {
      final repository = repositoryWith(readOnly);

      await expectLater(
          repository.send(JNAPAction.getDeviceInfo), throwsA(isA<_Sent>()));
      expect(repository.built, [JNAPAction.getDeviceInfo.actionValue]);
    });

    test('still sends a firmware check', () async {
      final repository = repositoryWith(readOnly);

      await expectLater(
          repository
              .send(JNAPAction.updateFirmwareNow, data: {'onlyCheck': true}),
          throwsA(isA<_Sent>()));
      expect(repository.built, [JNAPAction.updateFirmwareNow.actionValue]);
    });

    test('refuses a transaction carrying one write, sending none of it',
        () async {
      final repository = repositoryWith(readOnly);

      await expectLater(
        repository.transaction(JNAPTransactionBuilder(commands: [
          const MapEntry(JNAPAction.getWANSettings, {}),
          const MapEntry(JNAPAction.setWANSettings, {'x': 1}),
        ])),
        throwsA(isA<ReadOnlyAccessException>()
            .having((e) => e.action, 'action', JNAPAction.setWANSettings)),
      );
      expect(repository.built, isEmpty);
    });

    test('still sends an all-read transaction', () async {
      final repository = repositoryWith(readOnly);

      await expectLater(
        repository.transaction(JNAPTransactionBuilder(commands: [
          const MapEntry(JNAPAction.getWANSettings, {}),
          const MapEntry(JNAPAction.getLANSettings, {}),
        ])),
        throwsA(isA<_Sent>()),
      );
      expect(repository.built, hasLength(2));
    });
  });

  test('full access sends a write', () async {
    final repository = repositoryWith(AccessPolicy.full);

    await expectLater(
        repository.send(JNAPAction.setWANSettings), throwsA(isA<_Sent>()));
    expect(repository.built, [JNAPAction.setWANSettings.actionValue]);
  });
}
