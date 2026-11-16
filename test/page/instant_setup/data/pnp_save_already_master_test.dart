// #1748: the real [PnpNotifier.save] recovering from ErrorAlreadyMaster.
//
// PnP can hold a stale `Unconfigured` device mode — read before Auto Master
// made the router Master — all the way to the save. The transaction then
// carries `SetDeviceMode Master`, firmware rejects the whole transaction with
// ErrorAlreadyMaster, and a plain retry sends the same transaction again. The
// setup view re-reads the mode on entry when Auto Master is `complete`, but
// that read can fail. So the save itself re-reads the mode on
// ErrorAlreadyMaster and rebuilds the transaction once — only when the router
// no longer answers Unconfigured.
//
// A ProviderContainer hosts the real notifier with a MockRouterRepository, so
// the transaction contents are the ones save() actually builds.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/di.dart';
import '../../../mocks/router_repository_mocks.dart';
import '../../../test_data/device_info_test_data.dart';

// The minimum router data save() parses unconditionally.
final _data = <JNAPAction, JNAPResult>{
  JNAPAction.getGuestRadioSettings: const JNAPSuccess(result: 'OK', output: {
    'isGuestNetworkACaptivePortal': false,
    'isGuestNetworkEnabled': false,
    'radios': [],
  }),
  JNAPAction.getRadioInfo: const JNAPSuccess(result: 'OK', output: {
    'isBandSteeringSupported': false,
    'radios': [],
  }),
};

void main() {
  mockDependencyRegister();

  late MockRouterRepository repo;
  late ProviderContainer container;
  late PnpNotifier notifier;
  // Each save transaction's actions, in the order they were sent.
  late List<List<JNAPAction>> saves;
  // What the router answers to each save transaction, in order.
  late List<Object> saveAnswers;
  // What the router answers to each GetDeviceMode, in order.
  late List<Object> modeAnswers;
  late int modeReads;
  // Every action sent outside a transaction.
  late List<JNAPAction> sends;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockRouterRepository();
    saves = [];
    saveAnswers = [];
    modeAnswers = [];
    modeReads = 0;
    sends = [];

    when(repo.transaction(
      any,
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((invocation) async {
      final builder =
          invocation.positionalArguments.first as JNAPTransactionBuilder;
      final actions = builder.commands.map((e) => e.key).toList();
      if (actions.contains(JNAPAction.isAdminPasswordDefault)) {
        // _queryRouterPasswordSet: factory-default password, not set by user.
        return const JNAPTransactionSuccessWrap(result: 'OK', data: [
          MapEntry(
              JNAPAction.isAdminPasswordDefault,
              JNAPSuccess(
                  result: 'OK', output: {'isAdminPasswordDefault': true})),
          MapEntry(
              JNAPAction.isAdminPasswordSetByUser,
              JNAPSuccess(
                  result: 'OK', output: {'isAdminPasswordSetByUser': false})),
        ]);
      }
      saves.add(actions);
      final answer = saveAnswers.removeAt(0);
      if (answer is JNAPTransactionSuccessWrap) return answer;
      throw answer;
    });

    when(repo.send(
      any,
      data: anyNamed('data'),
      extraHeaders: anyNamed('extraHeaders'),
      auth: anyNamed('auth'),
      type: anyNamed('type'),
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((invocation) async {
      final action = invocation.positionalArguments.first as JNAPAction;
      sends.add(action);
      if (action == JNAPAction.getDeviceMode) {
        modeReads++;
        final answer = modeAnswers.removeAt(0);
        if (answer is Exception) throw answer;
        return JNAPSuccess(result: 'OK', output: {'mode': answer});
      }
      if (action == JNAPAction.getDeviceInfo) {
        // testConnectionReconnected: the same router came back.
        return JNAPSuccess(
            result: 'OK', output: jsonDecode(testDeviceInfo)['output']);
      }
      if (action == JNAPAction.setUserAcknowledgedAutoConfiguration) {
        return const JNAPSuccess(result: 'OK');
      }
      fail('Unexpected send: $action');
    });

    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(repo),
    ]);
    notifier = container.read(pnpProvider.notifier) as PnpNotifier;
  });

  tearDown(() => container.dispose());

  void seed({required bool unconfigured, Map<String, dynamic>? autoConfig}) {
    notifier.state = PnpState(
      deviceInfo: NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
      isUnconfigured: unconfigured,
      data: {
        ..._data,
        if (autoConfig != null)
          JNAPAction.getAutoConfigurationSettings:
              JNAPSuccess(result: 'OK', output: autoConfig),
      },
    );
  }

  // The firmware's answer in the #1748 log: the earlier actions succeed, the
  // SetDeviceMode is rejected, and so is the whole transaction.
  JNAPError alreadyMaster() => JNAPError.fromJson(const {
        'result': 'Error',
        'responses': [
          {'result': 'OK'},
          {'result': 'OK'},
          {'result': errorAlreadyMaster},
        ],
      });

  const ok = JNAPTransactionSuccessWrap(result: 'OK');

  // A successful save waits 3 s of real time for the LAN restart before it
  // checks the router is back.
  Future<Object> runSave() => notifier
      .save()
      .then<Object>((_) => 'saved', onError: (Object error) => error);

  test(
      'ErrorAlreadyMaster re-reads the mode and saves once more as configured '
      '(#1748)', () async {
    seed(unconfigured: true);
    saveAnswers.addAll([alreadyMaster(), ok]);
    modeAnswers.add('Master');

    expect(await runSave(), 'saved');

    expect(modeReads, 1);
    expect(saves, hasLength(2));
    expect(saves.first, contains(JNAPAction.setDeviceMode));
    expect(saves.first, contains(JNAPAction.pnpSetAdminPassword));
    // Rebuilt from the fresh mode: what a configured router gets.
    expect(saves.last, isNot(contains(JNAPAction.setDeviceMode)));
    expect(saves.last, isNot(contains(JNAPAction.pnpSetAdminPassword)));
    expect(
        saves.last, contains(JNAPAction.setUserAcknowledgedAutoConfiguration));
    expect(notifier.state.isRouterUnConfigured, isFalse);
    expect(notifier.didSetAdminPasswordDuringSave, isFalse);
  });

  test(
      'no separate acknowledgement after a recovered save, the resent '
      'transaction already carried it (#1748)', () async {
    seed(unconfigured: true, autoConfig: {
      'isAutoConfigurationSupported': true,
      'userAcknowledgedAutoConfiguration': false,
      'autoConfigurationMethod': 'AutoParent',
    });
    saveAnswers.addAll([alreadyMaster(), ok]);
    modeAnswers.add('Master');

    expect(await runSave(), 'saved');
    expect(
        saves.last, contains(JNAPAction.setUserAcknowledgedAutoConfiguration));
    sends.clear();
    await notifier.acknowledgeAutoConfigurationIfNeeded();

    expect(sends, isEmpty);
  });

  test('the resent save is not resent again on ErrorAlreadyMaster (#1748)',
      () async {
    seed(unconfigured: true);
    saveAnswers.addAll([alreadyMaster(), alreadyMaster()]);
    modeAnswers.add('Master');

    final outcome = await runSave();

    expect(outcome, isA<ExceptionSavingChanges>());
    expect(((outcome as ExceptionSavingChanges).error as JNAPError).result,
        errorAlreadyMaster);
    expect(modeReads, 1);
    expect(saves, hasLength(2));
  });

  test(
      'a connection loss on the resent save still reaches the reconnect flow '
      '(#1748)', () async {
    seed(unconfigured: true);
    saveAnswers.addAll([alreadyMaster(), ClientException('reset')]);
    modeAnswers.add('Master');

    final outcome = await runSave();

    expect(outcome, isA<ExceptionNeedToReconnect>());
    expect(saves, hasLength(2));
    expect(notifier.didSetAdminPasswordDuringSave, isFalse);
  });

  test('a 401 on the resent save still reaches the password prompt (#1748)',
      () async {
    seed(unconfigured: true);
    saveAnswers.addAll(
        [alreadyMaster(), const JNAPError(result: errorJNAPUnauthorized)]);
    modeAnswers.add('Master');

    final outcome = await runSave();

    expect(outcome, isA<ExceptionSavingChanges>());
    expect(((outcome as ExceptionSavingChanges).error as JNAPError).result,
        errorJNAPUnauthorized);
  });

  test('a still-Unconfigured re-read keeps the original error (#1748)',
      () async {
    seed(unconfigured: true);
    saveAnswers.add(alreadyMaster());
    modeAnswers.add('Unconfigured');

    final outcome = await runSave();

    expect(outcome, isA<ExceptionSavingChanges>());
    expect(((outcome as ExceptionSavingChanges).error as JNAPError).result,
        errorAlreadyMaster);
    expect(modeReads, 1);
    expect(saves, hasLength(1));
  });

  test('a failed re-read keeps the original error, no second save (#1748)',
      () async {
    seed(unconfigured: true);
    saveAnswers.add(alreadyMaster());
    modeAnswers.add(Exception('timeout'));

    final outcome = await runSave();

    expect(outcome, isA<ExceptionSavingChanges>());
    expect(((outcome as ExceptionSavingChanges).error as JNAPError).result,
        errorAlreadyMaster);
    expect(modeReads, 1);
    expect(saves, hasLength(1));
  });

  test('other save errors are not re-read or resent (#1748)', () async {
    seed(unconfigured: true);
    saveAnswers.add(const JNAPError(result: 'ErrorInvalidSettings'));

    final outcome = await runSave();

    expect(outcome, isA<ExceptionSavingChanges>());
    expect(modeReads, 0);
    expect(saves, hasLength(1));
  });

  test('a configured router never re-reads on ErrorAlreadyMaster (#1748)',
      () async {
    // No SetDeviceMode was sent, so the error cannot be about a stale mode.
    seed(unconfigured: false);
    saveAnswers.add(alreadyMaster());

    final outcome = await runSave();

    expect(outcome, isA<ExceptionSavingChanges>());
    expect(modeReads, 0);
    expect(saves, hasLength(1));
    expect(saves.first, isNot(contains(JNAPAction.setDeviceMode)));
  });
}
