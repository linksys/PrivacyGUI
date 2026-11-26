// Unit tests for VPNNotifier's reads after a poll (#1834).
//
// The notifier reads its status when polling signals a completed poll
// (pollCompletedProvider), instead of being called by polling, and only on a
// router that supports VPN. The router is a RouterBoundary, so what the
// notifier sends is observable.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_state.dart';

import '../../../common/di.dart';
import '../../../common/router_boundary.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../test_data/vpn_test_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  mockDependencyRegister();

  late RouterBoundary router;
  late MockServiceHelper helper;
  late ProviderContainer container;

  final vpn = VPNTestState.defaultState;
  Map<String, dynamic> vpnService(IPsecStatus status) => {
        'settings': VPNServiceSettings(
          enabled: true,
          autoConnect: true,
          statistics: vpn.status.statistics,
          tunnelStatus: status,
        ).toMap(),
      };

  setUp(() {
    initBetterActions();
    helper = serviceHelper as MockServiceHelper;
    when(helper.isSupportVPN()).thenReturn(true);
    router = RouterBoundary()
      ..holds(JNAPAction.getVPNUser,
          {'credentials': vpn.settings.userCredentials!.toMap()})
      ..holds(JNAPAction.getVPNGateway,
          {'settings': vpn.settings.gatewaySettings!.toMap()})
      ..holds(JNAPAction.getVPNService, vpnService(IPsecStatus.connected));
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
  });

  tearDown(() {
    container.dispose();
    reset(helper);
  });

  test('a completed poll reads the status, on a router with VPN', () async {
    container.read(vpnProvider);

    container.read(pollCompletedProvider.notifier).state++;
    await pumpEventQueue();

    expect(router.actions, contains(JNAPAction.getVPNService));
    expect(container.read(vpnProvider).status.tunnelStatus,
        IPsecStatus.connected);
  });

  test('a completed poll reads nothing on a router without VPN', () async {
    when(helper.isSupportVPN()).thenReturn(false);
    container.read(vpnProvider);

    container.read(pollCompletedProvider.notifier).state++;
    await pumpEventQueue();

    expect(router.actions, isEmpty);
  });

  test('a failed read after a poll stays with VPN', () async {
    // An error that escaped the listener would fail this test as an uncaught
    // error, and in the app it would never reach polling either way.
    container.read(vpnProvider);
    router.refuses(JNAPAction.getVPNService, result: '_ErrorUnexpected');

    container.read(pollCompletedProvider.notifier).state++;
    await pumpEventQueue();

    expect(router.actions, contains(JNAPAction.getVPNService));
    expect(container.read(vpnProvider).status.tunnelStatus,
        const VPNState.init().status.tunnelStatus,
        reason: 'the status it had');
  });
}
