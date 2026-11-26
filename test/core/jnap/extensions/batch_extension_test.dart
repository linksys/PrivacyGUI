// The batched reads and writes the repository offers, as the router meets
// them: which actions go out together, and whether they skip the cache.
//
// fetchIpDetails, fetchAllRadioInfo and fetchCreateTicketDeviceInfo have no
// caller in lib/ and are not tested (#1866 Decision 3).

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/extensions/batch_extension.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

import '../../../common/router_boundary.dart';

/// How a transaction was sent: its builder and the cache options beside it.
typedef _Sent = ({
  JNAPTransactionBuilder builder,
  bool fetchRemote,
  CacheLevel cacheLevel,
});

void main() {
  late RouterBoundary router;

  _Sent sentTransaction() {
    final captured = verify(router.repo.transaction(
      captureAny,
      fetchRemote: captureAnyNamed('fetchRemote'),
      cacheLevel: captureAnyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).captured;
    return (
      builder: captured[0] as JNAPTransactionBuilder,
      fetchRemote: captured[1] as bool,
      cacheLevel: captured[2] as CacheLevel,
    );
  }

  setUp(() {
    router = RouterBoundary();
  });

  test('asks the router about its admin password in one fresh transaction',
      () async {
    router
      ..holds(JNAPAction.isAdminPasswordSetByUser,
          {'isAdminPasswordSetByUser': true})
      ..holds(
          JNAPAction.isAdminPasswordDefault, {'isAdminPasswordDefault': false});

    final results = await router.repo.fetchIsConfigured();

    expect(router.transactions.single.map((command) => command.key), [
      JNAPAction.isAdminPasswordSetByUser,
      JNAPAction.isAdminPasswordDefault,
    ]);
    final sent = sentTransaction();
    expect(sent.builder.auth, isTrue);
    expect(sent.fetchRemote, isTrue);
    expect((results.first.value as JNAPSuccess).output,
        {'isAdminPasswordSetByUser': true});
    expect((results.last.value as JNAPSuccess).output,
        {'isAdminPasswordDefault': false});
  });

  test(
      'reads the Internet settings in one transaction, from the cache unless '
      'told not to', () async {
    for (final action in [
      JNAPAction.getIPv6Settings,
      JNAPAction.getWANSettings,
      JNAPAction.getWANStatus,
      JNAPAction.getMACAddressCloneSettings,
      JNAPAction.getLANSettings,
    ]) {
      router.holds(action, {'from': action.name});
    }

    final results = await router.repo.fetchInternetSettings();
    final sent = sentTransaction();

    expect(results.map((result) => result.key), [
      JNAPAction.getIPv6Settings,
      JNAPAction.getWANSettings,
      JNAPAction.getWANStatus,
      JNAPAction.getMACAddressCloneSettings,
      JNAPAction.getLANSettings,
    ]);
    expect((results[2].value as JNAPSuccess).output, {'from': 'getWANStatus'});
    expect(sent.builder.auth, isTrue);
    expect(sent.fetchRemote, isFalse);

    await router.repo.fetchInternetSettings(fetchRemote: true);
    expect(sentTransaction().fetchRemote, isTrue);
  });

  test('deletes each device in one transaction that skips the cache', () async {
    router.holds(JNAPAction.deleteDevice, const {});

    final results =
        await router.repo.deleteDevices(['tablet-id', 'printer-id']);

    expect(router.payloadsOf(JNAPAction.deleteDevice), [
      {'deviceID': 'tablet-id'},
      {'deviceID': 'printer-id'},
    ]);
    expect(router.transactions, hasLength(1));
    final sent = sentTransaction();
    expect(sent.builder.auth, isTrue);
    expect(sent.fetchRemote, isTrue);
    expect(sent.cacheLevel, CacheLevel.noCache);
    expect(results.map((result) => result.value.result), ['OK', 'OK']);
  });

  test('passes a refused transaction on to the caller', () async {
    router.failsTransactions(const JNAPError(result: 'ErrorUnknown'));

    await expectLater(
        router.repo.deleteDevices(['tablet-id']), throwsA(isA<JNAPError>()));
  });
}
