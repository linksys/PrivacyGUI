// The transport every router write goes through.
//
// RouterRepository.send and RouterRepository.transaction carry the read-only
// gate (#1637). These tests pin what full access does there - every action
// reaches the executor, with the data the caller passed, and the result comes
// back to the caller - so the gate cannot quietly change what a local user can
// do. Then the same transport with writing refused.
//
// Every JNAPAction is sent once, not a sample. The gate works from a list, and
// a list is exactly where one action gets missed; with all of them here, a
// regression on any single action fails by name.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/access/jnap_write_classifier.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/command/http/base_http_command.dart';
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';

/// Stands in for the HTTP client: records every command it is handed and
/// answers OK, so a test can see exactly what left the repository.
class _RecordingExecutor with JNAPCommandExecutor<Response> {
  final List<BaseCommand> executed = [];

  @override
  Future<Response> execute(BaseCommand command) async {
    executed.add(command);
    if (command is TransactionHttpCommand) {
      final count = (jsonDecode(command.data) as List).length;
      return Response(
          jsonEncode({
            keyJnapResult: jnapResultOk,
            keyJnapResponses: List.generate(
                count,
                (i) => {
                      keyJnapResult: jnapResultOk,
                      keyJnapOutput: {'index': i},
                    }),
          }),
          200);
    }
    return Response(
        jsonEncode({
          keyJnapResult: jnapResultOk,
          keyJnapOutput: {'echo': command.spec.action},
        }),
        200);
  }

  @override
  void dropCommand(String id) {}
}

/// The real repository with only the executor swapped, so URL, header and
/// command construction all run as they do in the app.
class _TestRouterRepository extends RouterRepository {
  _TestRouterRepository(super.ref, this.recorder);

  final _RecordingExecutor recorder;

  @override
  JNAPCommandExecutor get executor => recorder;
}

class _LocalConnectivityNotifier extends ConnectivityNotifier {
  @override
  ConnectivityState build() => const ConnectivityState(
        hasInternet: true,
        connectivityInfo: ConnectivityInfo(
          gatewayIp: '192.168.1.1',
          routerType: RouterType.behindManaged,
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  // The command cache reaches for the temp directory, and the local auth header
  // reads the stored password; neither has a platform under the test binding.
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => Directory.systemTemp.path,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/shared_preferences'),
    (_) async => <String, Object>{},
  );

  late _RecordingExecutor recorder;
  late ProviderContainer container;
  late RouterRepository repo;

  ProviderContainer containerWith({required AccessPolicy policy}) =>
      ProviderContainer(overrides: [
        connectivityProvider.overrideWith(() => _LocalConnectivityNotifier()),
        accessPolicyProvider.overrideWithValue(policy),
        routerRepositoryProvider
            .overrideWith((ref) => _TestRouterRepository(ref, recorder)),
      ]);

  setUp(() {
    // Every service the app knows about, so that actions the app only enables
    // when the router advertises a service (clientDeauth, getWANExternal, ...)
    // have a value to send.
    buildBetterActions(
        JNAPService.appSupportedServices.map((s) => s.value).toList());
    recorder = _RecordingExecutor();
    container = containerWith(policy: AccessPolicy.full);
    repo = container.read(routerRepositoryProvider);
  });

  tearDown(() => container.dispose());

  test('the default build is not a remote build', () {
    // Everything below assumes the local transport. If this ever fails, the
    // build under test is not the one these tests are meant to protect.
    expect(BuildConfig.forceCommandType, ForceCommand.none);
  });

  group('send', () {
    // `transaction` is the envelope name, not a command a caller sends alone.
    final actions =
        JNAPAction.values.where((a) => a != JNAPAction.transaction).toList();

    test('covers every JNAPAction but the transaction envelope', () {
      expect(actions.length, JNAPAction.values.length - 1);
    });

    for (final action in actions) {
      test('dispatches ${action.name}', () async {
        final data = {'probe': action.name};

        final result = await repo.send(
          action,
          data: data,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        );

        expect(recorder.executed, hasLength(1));
        final command = recorder.executed.single as JNAPHttpCommand;
        expect(command.spec.action, action.actionValue);
        expect(command.spec.data, data);
        expect(command.url, 'https://192.168.1.1/JNAP/');
        expect(result.output['echo'], action.actionValue);
      });
    }

    test('the dashboard firmware check keeps its onlyCheck flag', () async {
      // Sent automatically on every dashboard visit; a read-only allowlist that
      // judges by action name alone would block it, so its exact shape matters.
      for (final action in [
        JNAPAction.updateFirmwareNow,
        JNAPAction.nodesUpdateFirmwareNow
      ]) {
        recorder.executed.clear();
        await repo.send(action,
            data: {'onlyCheck': true},
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            auth: true);
        final command = recorder.executed.single as JNAPHttpCommand;
        expect(command.spec.data, {'onlyCheck': true});
      }
    });
  });

  group('transaction', () {
    test('dispatches a mixed read and write batch in order', () async {
      final builder = JNAPTransactionBuilder(commands: [
        const MapEntry(JNAPAction.getWANSettings, {}),
        const MapEntry(JNAPAction.setWANSettings, {'wanType': 'DHCP'}),
        const MapEntry(JNAPAction.reboot, {}),
      ], auth: true);

      final result = await repo.transaction(builder, fetchRemote: true);

      final command = recorder.executed.single as TransactionHttpCommand;
      final sent = (jsonDecode(command.data) as List)
          .map((e) => [e['action'], e['request']])
          .toList();
      expect(sent, [
        [JNAPAction.getWANSettings.actionValue, <String, dynamic>{}],
        [
          JNAPAction.setWANSettings.actionValue,
          {'wanType': 'DHCP'}
        ],
        [JNAPAction.reboot.actionValue, <String, dynamic>{}],
      ]);
      // Results are paired back to actions by index - which is why a guard must
      // never drop entries from a batch.
      expect(result.data.map((e) => e.key), [
        JNAPAction.getWANSettings,
        JNAPAction.setWANSettings,
        JNAPAction.reboot,
      ]);
      expect(result.data.map((e) => (e.value as JNAPSuccess).output['index']),
          [0, 1, 2]);
    });

    test('dispatches a write-only batch', () async {
      final builder = JNAPTransactionBuilder(commands: [
        const MapEntry(JNAPAction.setMACFilterSettings, {'enabled': true}),
        const MapEntry(JNAPAction.deleteDevice, {'deviceID': 'abc'}),
      ], auth: true);

      await repo.transaction(builder, fetchRemote: true);

      final command = recorder.executed.single as TransactionHttpCommand;
      expect(command.actions,
          [JNAPAction.setMACFilterSettings, JNAPAction.deleteDevice]);
    });
  });

  group('scheduledCommand', () {
    test('polls through send', () async {
      final results = await repo
          .scheduledCommand(
            action: JNAPAction.getDeviceInfo,
            firstDelayInMilliSec: 0,
            retryDelayInMilliSec: 0,
            maxRetry: 1,
          )
          .toList();

      expect(results, hasLength(1));
      final command = recorder.executed.single as JNAPHttpCommand;
      expect(command.spec.action, JNAPAction.getDeviceInfo.actionValue);
    });
  });

  // The same transport with writing refused. The classification itself is
  // pinned action by action in jnap_write_classifier_test; what is pinned here
  // is that the gate consults it and refuses before anything reaches the
  // executor.
  group('read-only access', () {
    late RouterRepository readOnlyRepo;

    setUp(() {
      container.dispose();
      container = containerWith(policy: const AccessPolicy(canWrite: false));
      readOnlyRepo = container.read(routerRepositoryProvider);
    });

    Matcher refusal() => isA<ReadOnlyAccessException>();

    final actions =
        JNAPAction.values.where((a) => a != JNAPAction.transaction).toList();

    for (final action in actions) {
      final allowed = !isJNAPWrite(action);
      test('${allowed ? 'sends' : 'refuses'} ${action.name}', () async {
        final future = readOnlyRepo.send(action,
            fetchRemote: true, cacheLevel: CacheLevel.noCache);
        if (allowed) {
          await future;
          expect(recorder.executed, hasLength(1));
        } else {
          await expectLater(future, throwsA(refusal()));
          expect(recorder.executed, isEmpty);
        }
      });
    }

    test('sends the dashboard firmware check', () async {
      await readOnlyRepo.send(JNAPAction.updateFirmwareNow,
          data: {'onlyCheck': true},
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache);
      expect(recorder.executed, hasLength(1));
    });

    test('sends a batch of reads', () async {
      await readOnlyRepo.transaction(
          JNAPTransactionBuilder(commands: [
            const MapEntry(JNAPAction.getWANSettings, {}),
            const MapEntry(JNAPAction.getDeviceInfo, {}),
          ]),
          fetchRemote: true);
      expect(recorder.executed, hasLength(1));
    });

    test('refuses a whole batch that holds one write', () async {
      // Results pair back to actions by index, so dropping the write and
      // sending the rest would hand callers mismatched results.
      await expectLater(
          readOnlyRepo.transaction(
              JNAPTransactionBuilder(commands: [
                const MapEntry(JNAPAction.getWANSettings, {}),
                const MapEntry(JNAPAction.setWANSettings, {'wanType': 'DHCP'}),
              ]),
              fetchRemote: true),
          throwsA(refusal()));
      expect(recorder.executed, isEmpty);
    });

    // A refusal is not a router error, so the retry list never sees it.
    test('a refusal is not retried', () async {
      await expectLater(
          readOnlyRepo.send(JNAPAction.setWANSettings,
              fetchRemote: true, cacheLevel: CacheLevel.noCache, retries: 3),
          throwsA(refusal()));
      expect(recorder.executed, isEmpty);
    });
  });
}
