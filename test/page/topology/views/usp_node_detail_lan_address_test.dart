import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../layout_gate/surface.dart';
import '../../../mocks/provider_overrides/mock_dhcp.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/scenes/cards_scene_data.dart'
    show testLanDisabledData;
import '../../../mocks/test_data/scenes/topology_scene_data.dart';
import '../../../util/settle.dart';

/// A LAN read that fails, the way the service surfaces one.
class _FailingLanDataNotifier extends LanDataNotifier {
  @override
  Future<LanData> build() async =>
      throw const NetworkError(detail: 'LAN read failed');
}

/// The LAN addresses on a node's detail page (#1722).
///
/// Each node's come from one source. The router's come from the LAN interface
/// (`lanDataProvider`), which is what the Local Network page shows. Its Hosts
/// row is never drawn, and on FL-WRT 2.0 it has none. An agent's come from its
/// own Hosts row.
void main() {
  late AppLocalizations loc;
  setUpAll(() async {
    loc = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> pump(
    WidgetTester tester,
    UspNodeDetailState state, {
    required List<Override> lan,
  }) async {
    await setLayoutSurface(tester, const Size(1280, 1800));
    await tester.pumpWidget(pageSurfaceHost(
      view: UspNodeDetailView(deviceId: state.node!.deviceId),
      locale: const Locale('en'),
      overrides: [...nodeDetailOverrides(state), ...lan],
    ));
    // The node card's `AppImage.provider` stream never completes under the test
    // binding, so `pumpAndSettle` would time out on it.
    await settleIgnoringAnimations(tester);
  }

  List<Override> lanServing(LanData data) =>
      [lanDataProvider.overrideWith(() => FixedLanDataNotifier(data))];

  // What the LAN interface and the Hosts row each carry, asserted rather than
  // assumed: the tests below tell the two sources apart by these values.
  const interfaceIp = '192.168.1.1';
  const interfaceIpv6 = '2001:db8::1';
  const hostsIp = '192.168.1.254';
  const hostsIpv6 = '2001:db8::254';

  /// Neither of the router's Hosts addresses is anywhere on the page.
  void expectNoHostsAddresses() {
    expect(find.text(hostsIp), findsNothing);
    expect(find.text(hostsIpv6), findsNothing);
  }

  test('the fixtures carry the addresses the tests tell apart', () {
    expect(routerLanData.model.ipAddress, interfaceIp);
    expect(routerLanData.model.ipv6Addresses, [interfaceIpv6]);
    expect(testLanDisabledData.model.ipAddress, interfaceIp);
    expect(testLanDisabledData.model.ipv6Addresses, isEmpty);

    final bare = masterNodeEmptyDevices.node!;
    expect(bare.isMaster, isTrue);
    expect(bare.ipAddress, isNull);
    expect(bare.ipv6Addresses, isEmpty);

    final withHosts = masterNodeWithHostsAddresses.node!;
    expect(withHosts.isMaster, isTrue);
    expect(withHosts.ipAddress, hostsIp);
    expect(withHosts.ipv6Addresses, [hostsIpv6]);
  });

  testWidgets('a router with no Hosts row shows the LAN interface addresses', (
    tester,
  ) async {
    await pump(tester, masterNodeEmptyDevices, lan: lanServing(routerLanData));

    expect(find.text(loc.lanIp), findsOneWidget);
    expect(find.text(interfaceIp), findsOneWidget);
    expect(find.text(loc.lanIpv6), findsOneWidget);
    expect(find.text(interfaceIpv6), findsOneWidget);
  });

  testWidgets('a router draws the LAN interface, not its Hosts row', (
    tester,
  ) async {
    await pump(tester, masterNodeWithHostsAddresses,
        lan: lanServing(routerLanData));

    expect(find.text(interfaceIp), findsOneWidget);
    expect(find.text(interfaceIpv6), findsOneWidget);
    expectNoHostsAddresses();
  });

  testWidgets('an address the LAN interface lacks is not taken from Hosts', (
    tester,
  ) async {
    // The interface has an IPv4 and no IPv6, and the Hosts row has both.
    await pump(tester, masterNodeWithHostsAddresses,
        lan: lanServing(testLanDisabledData));

    expect(find.text(interfaceIp), findsOneWidget);
    expect(find.text(loc.lanIpv6), findsNothing);
    expectNoHostsAddresses();
  });

  testWidgets('a LAN interface with no address leaves the LAN rows hidden', (
    tester,
  ) async {
    // `LanData.empty()` reads the interface's IPv4 as '', not null.
    await pump(tester, masterNodeWithHostsAddresses,
        lan: lanServing(const LanData.empty()));

    expect(find.text(loc.lanIp), findsNothing);
    expect(find.text(loc.lanIpv6), findsNothing);
    expectNoHostsAddresses();
  });

  testWidgets('a failed LAN read hides the LAN rows and leaves the page', (
    tester,
  ) async {
    await pump(tester, masterNodeWithHostsAddresses, lan: [
      lanDataProvider.overrideWith(_FailingLanDataNotifier.new),
    ]);

    final container = ProviderScope.containerOf(
        tester.element(find.byType(UspNodeDetailView)));
    expect(container.read(lanDataProvider).hasError, isTrue,
        reason: 'the read must have failed, not still be loading');
    expect(find.text(loc.lanIp), findsNothing);
    expect(find.text(loc.lanIpv6), findsNothing);
    expectNoHostsAddresses();
    // The rest of the page still renders: the Network card's own header and
    // the router's model on the node card.
    expect(find.text(loc.network), findsOneWidget);
    expect(find.text('MR7500'), findsWidgets);
  });

  testWidgets('an extender shows only its own Hosts addresses', (
    tester,
  ) async {
    // The extender has a routable IPv6 and no IPv4 on its Hosts row. The
    // router's LAN addresses are served too, and must not leak onto it.
    final extender = slaveNodeGlobalIpv6.node!;
    expect(extender.isMaster, isFalse);
    expect(extender.ipAddress, isNull);
    await pump(tester, slaveNodeGlobalIpv6, lan: lanServing(routerLanData));

    expect(find.text(extender.ipv6Addresses.single), findsOneWidget);
    expect(find.text(loc.lanIpv6), findsOneWidget);
    expect(find.text(loc.lanIp), findsNothing);
    expect(find.text(interfaceIp), findsNothing);
    expect(find.text(interfaceIpv6), findsNothing);
  });
}
