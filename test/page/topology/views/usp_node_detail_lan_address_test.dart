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
import '../../../mocks/test_data/scenes/topology_scene_data.dart';
import '../../../util/settle.dart';

/// A LAN read that fails, the way the service surfaces one.
class _FailingLanDataNotifier extends LanDataNotifier {
  @override
  Future<LanData> build() async =>
      throw const NetworkError(detail: 'LAN read failed');
}

/// The router's LAN addresses on its node detail page (#1722).
///
/// On FL-WRT 2.0 the controller has no `Device.Hosts.Host` row of its own, so
/// its node carries no LAN address and the Network card showed only the WAN
/// rows. The page now takes the router's LAN addresses from the LAN interface
/// (`lanDataProvider`), which is what the Local Network page shows. An agent
/// still takes its addresses from its own Hosts row.
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

  final routerLan = [
    lanDataProvider.overrideWith(() => FixedLanDataNotifier(routerLanData)),
  ];

  test('the fixture router has no LAN address of its own', () {
    // Asserted rather than assumed: with a Hosts address on the node, the
    // tests below would pass without the LAN interface being read at all.
    final router = masterNodeEmptyDevices.node!;
    expect(router.isMaster, isTrue);
    expect(router.ipAddress, isNull);
    expect(router.ipv6Addresses, isEmpty);
  });

  testWidgets('a router with no Hosts row shows the LAN interface addresses', (
    tester,
  ) async {
    await pump(tester, masterNodeEmptyDevices, lan: routerLan);

    expect(find.text(loc.lanIp), findsOneWidget);
    expect(find.text('192.168.1.1'), findsOneWidget);
    expect(find.text(loc.lanIpv6), findsNWidgets(2));
    expect(find.text('2001:db8::1'), findsOneWidget);
    expect(find.text('fe80::1'), findsOneWidget);
  });

  testWidgets('a router whose Hosts row has addresses keeps them', (
    tester,
  ) async {
    await pump(tester, masterNodeWithHostsAddresses, lan: routerLan);

    expect(find.text('192.168.1.254'), findsOneWidget);
    expect(find.text('2001:db8::254'), findsOneWidget);
    expect(find.text('192.168.1.1'), findsNothing);
    expect(find.text('2001:db8::1'), findsNothing);
    expect(find.text('fe80::1'), findsNothing);
  });

  testWidgets('an extender shows only its own Hosts addresses', (
    tester,
  ) async {
    // The extender has a routable IPv6 and no IPv4 on its Hosts row. The
    // router's LAN addresses are served too, and must not leak onto it.
    final extender = slaveNodeGlobalIpv6.node!;
    expect(extender.isMaster, isFalse);
    expect(extender.ipAddress, isNull);
    await pump(tester, slaveNodeGlobalIpv6, lan: routerLan);

    expect(find.text(extender.ipv6Addresses.single), findsOneWidget);
    expect(find.text(loc.lanIpv6), findsOneWidget);
    expect(find.text(loc.lanIp), findsNothing);
    expect(find.text('192.168.1.1'), findsNothing);
    expect(find.text('2001:db8::1'), findsNothing);
    expect(find.text('fe80::1'), findsNothing);
  });

  testWidgets('a failed LAN read hides the rows and leaves the page', (
    tester,
  ) async {
    await pump(tester, masterNodeEmptyDevices, lan: [
      lanDataProvider.overrideWith(_FailingLanDataNotifier.new),
    ]);

    expect(find.text(loc.lanIp), findsNothing);
    expect(find.text(loc.lanIpv6), findsNothing);
    // The rest of the page still renders: the Network card's own header and
    // the router's model on the node card.
    expect(find.text(loc.network), findsOneWidget);
    expect(find.text('MR7500'), findsWidgets);
  });
}
