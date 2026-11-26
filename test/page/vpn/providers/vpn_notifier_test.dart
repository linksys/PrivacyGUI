// VPN settings as the notifier reads and writes them, against the router
// behind RouterRepository.
//
// No 1.x firmware implements the VPN actions (they are plans), so the router
// here answers with the shapes VPNService reads. Since #1834 the notifier also
// reads its status when polling signals a completed poll
// (pollCompletedProvider), on a router with VPN: "after a poll" covers that.
// The other tests call fetch() themselves and never assert that polling does.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_state.dart';

import '../../../common/di.dart';
import '../../../common/router_boundary.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';

const _credentials = <String, dynamic>{
  'username': 'alice@example.com',
  'authMode': 'EAP',
  'secret': 'eap-secret',
};

const _gateway = <String, dynamic>{
  'gatewayAddress': '203.0.113.10',
  'dnsName': 'vpn.example.com',
  'ikeMode': 'ikev2',
  'ikeProposal': 'aes256-sha256-modp2048',
  'espProposal': 'aes256-sha256',
};

const _statistics = <String, dynamic>{
  'uptime': 3600,
  'packetsSent': 1024,
  'packetsReceived': 2048,
  'bytesSent': 1048576,
  'bytesReceived': 2097152,
  'currentBandwidth': 51200,
  'activeSAs': 2,
  'rekeyCount': 1,
};

Map<String, dynamic> _service({
  bool enabled = true,
  bool autoConnect = true,
  String tunnelStatus = 'Connected',
  Map<String, dynamic>? statistics = _statistics,
}) =>
    {
      'settings': {
        'enabled': enabled,
        'autoConnect': autoConnect,
        if (statistics != null) 'statistics': statistics,
        'tunnelStatus': tunnelStatus,
      },
    };

void main() {
  // The listener asks serviceHelper whether the router has VPN.
  mockDependencyRegister();

  late RouterBoundary router;
  late ProviderContainer container;
  late VPNNotifier notifier;

  VPNState page() => container.read(vpnProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getVPNUser, {'credentials': _credentials})
      ..holds(JNAPAction.getVPNGateway, {'settings': _gateway})
      ..holds(JNAPAction.getVPNService, _service());
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(vpnProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('starts disconnected, with the service off and nothing read', () {
    expect(page().status.tunnelStatus, IPsecStatus.disconnected);
    expect(page().status.statistics, isNull);
    expect(page().settings.serviceSettings.enabled, isFalse);
    expect(page().settings.serviceSettings.autoConnect, isFalse);
    expect(page().settings.userCredentials, isNull);
    expect(page().settings.gatewaySettings, isNull);
    expect(router.sent, isEmpty, reason: 'build reads nothing');
  });

  group('fetch', () {
    test('reads the user, the gateway and the service in one transaction',
        () async {
      await notifier.fetch();

      expect(router.transactions.single.map((command) => command.key), [
        JNAPAction.getVPNUser,
        JNAPAction.getVPNGateway,
        JNAPAction.getVPNService,
      ]);
    });

    test('a forced fetch skips the cache', () async {
      await notifier.fetch(true);

      verify(router.repo.transaction(any, fetchRemote: true)).called(1);
    });

    test('shows the user and the gateway the router holds', () async {
      await notifier.fetch();

      expect(
        page().settings.userCredentials,
        const VPNUserCredentials(
          username: 'alice@example.com',
          authMode: AuthMode.eap,
          secret: 'eap-secret',
        ),
      );
      expect(page().settings.gatewaySettings?.gatewayAddress, '203.0.113.10');
      expect(page().settings.gatewaySettings?.dnsName, 'vpn.example.com');
    });

    test('shows the service switches, without the status that came with them',
        () async {
      router.holds(JNAPAction.getVPNService,
          _service(enabled: true, autoConnect: false));

      await notifier.fetch();

      expect(page().settings.serviceSettings,
          const VPNServiceSetSettings(enabled: true, autoConnect: false));
    });

    test('shows the tunnel status and its statistics', () async {
      await notifier.fetch();

      expect(page().status.tunnelStatus, IPsecStatus.connected);
      expect(page().status.statistics?.uptime, 3600);
      expect(page().status.statistics?.bytesReceived, 2097152);
    });

    test('returns the state it ends in', () async {
      final returned = await notifier.fetch();

      expect(returned, same(page()));
    });

    test(
        'a status-only fetch updates the tunnel and keeps the edits on the '
        'page', () async {
      await notifier.fetch();
      await notifier.setVPNGateway(
          VPNGatewaySettings.fromMap(_gateway).copyWith(dnsName: 'edited'));
      router.holds(JNAPAction.getVPNService,
          _service(enabled: false, tunnelStatus: 'Failed', statistics: null));

      await notifier.fetch(false, true);

      expect(page().status.tunnelStatus, IPsecStatus.failed);
      expect(page().settings.gatewaySettings?.dnsName, 'edited');
      expect(page().settings.serviceSettings.enabled, isTrue,
          reason: 'the switch the page shows is not the status');
    });

    test('a refused read reaches the caller and leaves the page as it was',
        () async {
      final before = page();
      router.refuses(JNAPAction.getVPNService);

      await expectLater(notifier.fetch(), throwsA(isA<JNAPError>()));

      expect(page(), same(before));
    });

    test('a read that fails after the transaction leaves the page as it was',
        () async {
      // The transaction answers; the user read after it does not.
      router.holdsInTurn(JNAPAction.getVPNUser, [
        {'credentials': _credentials},
        const JNAPError(result: 'ErrorUnknown'),
      ]);
      final before = page();

      await expectLater(notifier.fetch(), throwsA(isA<JNAPError>()));

      expect(page(), same(before));
    });
  });

  group('save', () {
    setUp(() => notifier.fetch());

    test('writes the service switches', () async {
      await notifier.setVPNService(
          const VPNServiceSetSettings(enabled: false, autoConnect: true));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setVPNService).single,
          {'enabled': false, 'autoConnect': true});
    });

    test('writes the gateway the page holds', () async {
      await notifier.setVPNGateway(VPNGatewaySettings.fromMap(_gateway)
          .copyWith(gatewayAddress: '198.51.100.1'));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setVPNGateway).single,
          {..._gateway, 'gatewayAddress': '198.51.100.1'});
    });

    test('writes the user only while the credentials are being edited',
        () async {
      await notifier.save();
      expect(router.actions, isNot(contains(JNAPAction.setVPNUser)));

      await notifier.setEditingCredentials(true);
      await notifier.setVPNUser(const VPNUserCredentials(
          username: 'bob', authMode: AuthMode.psk, secret: 'psk-secret'));
      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setVPNUser).single,
          {'username': 'bob', 'authMode': 'PSK', 'secret': 'psk-secret'});
    });

    test('writes the tunneled user once the page has one', () async {
      await notifier.save();
      expect(router.actions, isNot(contains(JNAPAction.setTunneledUser)));

      await notifier.setTunneledUser('192.168.1.100');
      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setTunneledUser).single,
          {'ipAddress': '192.168.1.100'});
    });

    test('writes no gateway before one has been read or set', () async {
      final fresh = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router.repo),
      ]);
      addTearDown(fresh.dispose);
      router.transactions.clear();

      await fresh.read(vpnProvider.notifier).save();

      expect(router.transactions.first.map((command) => command.key),
          [JNAPAction.setVPNService]);
    });

    test('writes in one transaction, then applies, then reads back', () async {
      router.sent.clear();
      router.transactions.clear();

      await notifier.save();

      expect(router.transactions.first.map((command) => command.key), [
        JNAPAction.setVPNGateway,
        JNAPAction.setVPNService,
      ]);
      final actions = router.actions;
      final apply = actions.indexOf(JNAPAction.setVPNApply);
      for (final write in [
        JNAPAction.setVPNGateway,
        JNAPAction.setVPNService
      ]) {
        expect(actions.indexOf(write), inInclusiveRange(0, apply - 1),
            reason: '$write is written before the apply');
      }
      for (final read in [
        JNAPAction.getVPNUser,
        JNAPAction.getVPNGateway,
        JNAPAction.getVPNService,
      ]) {
        expect(actions.indexOf(read, apply), greaterThan(apply),
            reason: '$read is read back after the apply');
      }
    });

    test('shows what the router holds after the save', () async {
      router.holds(JNAPAction.getVPNService,
          _service(enabled: false, tunnelStatus: 'Disconnected'));

      final saved = await notifier.save();

      expect(saved.settings.serviceSettings.enabled, isFalse);
      expect(page().status.tunnelStatus, IPsecStatus.disconnected);
    });

    test('a refused write reaches the caller, and nothing is applied',
        () async {
      router.refuses(JNAPAction.setVPNService);

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(router.actions, isNot(contains(JNAPAction.setVPNApply)));
    });

    test('a refused apply reaches the caller, and nothing is read back',
        () async {
      router.refuses(JNAPAction.setVPNApply);
      router.sent.clear();

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(router.actions.last, JNAPAction.setVPNApply);
    });
  });

  group('testVPNConnection', () {
    setUp(() {
      router.holds(JNAPAction.testVPNConnection, {
        'success': true,
        'statusMessage': 'IPsec SA established',
        'latency': 42,
      });
      return notifier.fetch();
    });

    test('shows the result of the test', () async {
      await notifier.testVPNConnection();

      expect(
        page().status.testResult,
        const VPNTestResult(
            success: true, statusMessage: 'IPsec SA established', latency: 42),
      );
    });

    test('reads the tunnel again after the test', () async {
      router.holds(JNAPAction.getVPNService,
          _service(tunnelStatus: 'Connecting', statistics: null));
      router.sent.clear();

      await notifier.testVPNConnection();

      expect(router.actions.first, JNAPAction.testVPNConnection);
      expect(page().status.tunnelStatus, IPsecStatus.connecting);
      verify(router.repo.transaction(any, fetchRemote: true)).called(1);
    });

    test('a refused test reaches the caller and shows no result', () async {
      router.refuses(JNAPAction.testVPNConnection);

      await expectLater(
          notifier.testVPNConnection(), throwsA(isA<JNAPError>()));

      expect(page().status.testResult, isNull);
    });
  });

  group('after a poll (#1834)', () {
    // The notifier reads its status when polling signals a completed poll,
    // instead of being called by polling, and only on a router with VPN.
    late MockServiceHelper services;

    setUp(() {
      services = serviceHelper as MockServiceHelper;
      when(services.isSupportVPN()).thenReturn(true);
    });

    tearDown(() => reset(services));

    void signalPoll() => container.read(pollCompletedProvider.notifier).state++;

    test('a completed poll reads the status, on a router with VPN', () async {
      signalPoll();
      await pumpEventQueue();

      expect(router.actions, contains(JNAPAction.getVPNService));
      expect(page().status.tunnelStatus, IPsecStatus.connected);
    });

    test('a completed poll reads nothing on a router without VPN', () async {
      when(services.isSupportVPN()).thenReturn(false);

      signalPoll();
      await pumpEventQueue();

      expect(router.sent, isEmpty);
    });

    test('a failed read after a poll stays with VPN', () async {
      // An error that escaped the listener would fail this test as an uncaught
      // error, and in the app it would never reach polling either way.
      router.refuses(JNAPAction.getVPNService, result: '_ErrorUnexpected');

      signalPoll();
      await pumpEventQueue();

      expect(router.actions, contains(JNAPAction.getVPNService));
      expect(page().status.tunnelStatus, IPsecStatus.disconnected,
          reason: 'the status it had');
    });
  });
}
