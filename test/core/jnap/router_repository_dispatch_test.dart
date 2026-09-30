// Baseline for the transport every router write goes through.
//
// A read-only build is going to add a guard at the top of
// RouterRepository.send and RouterRepository.transaction. These tests pin what
// the default build - no --dart-define, which is what every local build is -
// does there today: every action reaches the executor, with the data the caller
// passed, and the result comes back to the caller. They are written before the
// guard exists so that adding it cannot quietly change the local build.
//
// Every JNAPAction is sent once, not a sample. Any allowlist the guard ends up
// using is a list, and a list is exactly where one action gets missed; with all
// of them here, a local-build regression on any single action fails by name.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/read_only_policy.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/command/http/base_http_command.dart';
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';

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

  ProviderContainer containerWith({required bool readOnly}) =>
      ProviderContainer(overrides: [
        connectivityProvider.overrideWith(() => _LocalConnectivityNotifier()),
        readOnlyModeProvider.overrideWithValue(readOnly),
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
    container = containerWith(readOnly: false);
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

  // The same transport with the read-only guard switched on. The allowlist
  // itself is pinned action by action in read_only_policy_test; what is pinned
  // here is that the guard consults it, refuses before anything reaches the
  // executor, and refuses in a form the app's error handling already knows.
  group('read-only build', () {
    late RouterRepository readOnlyRepo;

    setUp(() {
      container.dispose();
      container = containerWith(readOnly: true);
      readOnlyRepo = container.read(routerRepositoryProvider);
    });

    Matcher refusal() => isA<JNAPError>()
        .having((e) => e.runtimeType, 'exact type', JNAPError)
        .having((e) => e.result, 'result', errorReadOnlyMode);

    final actions =
        JNAPAction.values.where((a) => a != JNAPAction.transaction).toList();

    for (final action in actions) {
      final allowed = isAllowedInReadOnly(action, const {});
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

    test('a refusal is not retried', () async {
      expect(errorJNAPRetryList, isNot(contains(errorReadOnlyMode)));
    });
  });
}
