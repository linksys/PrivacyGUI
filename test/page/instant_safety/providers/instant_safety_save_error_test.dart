import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_safety/providers/_providers.dart';

import '../../../common/di.dart';
import '../../../mocks/router_repository_mocks.dart';

const _lanSettings = RouterLANSettings(
  minNetworkPrefixLength: 16,
  maxNetworkPrefixLength: 30,
  minAllowedDHCPLeaseMinutes: 1,
  dhcpSettings: DHCPSettings(
    lastClientIPAddress: '192.168.1.149',
    leaseMinutes: 1440,
    reservations: [],
    firstClientIPAddress: '192.168.1.100',
  ),
  hostName: 'Linksys',
  maxDHCPReservationDescriptionLength: 63,
  isDHCPEnabled: true,
  networkPrefixLength: 24,
  ipAddress: '192.168.1.1',
);

/// The real notifier, loaded with LAN settings and kept off the network on
/// entry: its build() fetches straight away.
class _LoadedSafety extends InstantSafetyNotifier {
  @override
  InstantSafetyState build() =>
      const InstantSafetyState(lanSetting: _lanSettings);
}

void main() {
  mockDependencyRegister();

  late MockRouterRepository repository;

  InstantSafetyNotifier safetyFailingWith(Object error) {
    repository = MockRouterRepository();
    when(repository.send(
      JNAPAction.setLANSettings,
      data: anyNamed('data'),
      auth: anyNamed('auth'),
      cacheLevel: anyNamed('cacheLevel'),
    )).thenAnswer((_) async => throw error);
    final container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWith((ref) => repository),
      instantSafetyProvider.overrideWith(_LoadedSafety.new),
    ]);
    addTearDown(container.dispose);
    return container.read(instantSafetyProvider.notifier);
  }

  // #1637: the save cast every error to JNAPError to read its message. A write
  // refused in read-only mode is not one, so the cast threw a TypeError that
  // hid the refusal from the page.
  test('a refused write reaches the page as a refusal', () async {
    const refused = ReadOnlyAccessException(JNAPAction.setLANSettings);
    final safety = safetyFailingWith(refused);

    await expectLater(safety.setSafeBrowsing(InstantSafetyType.openDNS),
        throwsA(same(refused)));
  });

  test('a router error still becomes a safe browsing error', () async {
    final safety = safetyFailingWith(
        const JNAPError(result: 'ErrorUnknown', error: 'something broke'));

    await expectLater(
        safety.setSafeBrowsing(InstantSafetyType.openDNS),
        throwsA(isA<SafeBrowsingError>()
            .having((e) => e.message, 'message', 'something broke')));
  });

  test('a side effect is passed on untouched', () async {
    final sideEffect = JNAPSideEffectError();
    final safety = safetyFailingWith(sideEffect);

    await expectLater(safety.setSafeBrowsing(InstantSafetyType.openDNS),
        throwsA(same(sideEffect)));
  });
}
