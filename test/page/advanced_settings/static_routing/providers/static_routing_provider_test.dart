import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';

import '../../../../common/router_boundary.dart';

/// `GetLANSettings` output: 192.168.1.1/24.
const _lan = <String, dynamic>{
  'minNetworkPrefixLength': 16,
  'maxNetworkPrefixLength': 30,
  'minAllowedDHCPLeaseMinutes': 1,
  'maxDHCPReservationDescriptionLength': 63,
  'hostName': 'Linksys00042',
  'ipAddress': '192.168.1.1',
  'networkPrefixLength': 24,
  'isDHCPEnabled': true,
  'dhcpSettings': {
    'firstClientIPAddress': '192.168.1.100',
    'lastClientIPAddress': '192.168.1.149',
    'leaseMinutes': 1440,
    'reservations': <Map<String, dynamic>>[],
  },
};

const _lanRoute = <String, dynamic>{
  'name': 'Lab',
  'settings': {
    'interface': 'LAN',
    'destinationLAN': '192.168.50.0',
    'networkPrefixLength': 24,
    'gateway': '192.168.1.254',
  },
};

const _internetRoute = <String, dynamic>{
  'name': 'Office',
  'settings': {
    'interface': 'Internet',
    'destinationLAN': '10.20.0.0',
    'networkPrefixLength': 16,
    'gateway': '203.0.113.1',
  },
};

/// `GetRoutingSettings` output, after the spec's sample.
Map<String, dynamic> _routing(
  List<Map<String, dynamic>> entries, {
  bool nat = true,
  bool dynamicRouting = false,
  int max = 20,
}) =>
    {
      'isNATEnabled': nat,
      'isDynamicRoutingEnabled': dynamicRouting,
      'entries': entries,
      'maxStaticRouteEntries': max,
    };

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late StaticRoutingNotifier notifier;

  StaticRoutingState page() => container.read(staticRoutingProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getLANSettings, _lan)
      ..holds(
          JNAPAction.getRoutingSettings, _routing([_lanRoute, _internetRoute]));
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(staticRoutingProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('lists the routes the router holds, with its limit', () async {
      final shown = await notifier.fetch();

      expect(shown, page());
      expect(page().setting.entries, [
        NamedStaticRouteEntry.fromMap(_lanRoute),
        NamedStaticRouteEntry.fromMap(_internetRoute),
      ]);
      expect(page().setting.isNATEnabled, isTrue);
      expect(page().setting.isDynamicRoutingEnabled, isFalse);
      expect(page().setting.maxStaticRouteEntries, 20);
    });

    test('takes the router address and mask a LAN gateway must sit in',
        () async {
      await notifier.fetch();

      expect(page().routerIp, '192.168.1.1');
      expect(page().subnetMask, '255.255.255.0');
    });

    test('reports a read the router refuses, and keeps the page', () async {
      router.refuses(JNAPAction.getRoutingSettings);

      await expectLater(notifier.fetch(), throwsA(isA<JNAPError>()));

      expect(page(), StaticRoutingState.empty());
    });
  });

  group('the network mode', () {
    setUp(() => notifier.fetch());

    test('is NAT or dynamic routing, never both', () {
      notifier.updateSettingNetwork(RoutingSettingNetwork.dynamicRouting);
      expect(page().setting.isNATEnabled, isFalse);
      expect(page().setting.isDynamicRoutingEnabled, isTrue);

      notifier.updateSettingNetwork(RoutingSettingNetwork.nat);
      expect(page().setting.isNATEnabled, isTrue);
      expect(page().setting.isDynamicRoutingEnabled, isFalse);
    });
  });

  group('save', () {
    setUp(() async {
      await notifier.fetch();
      router.sent.clear();
    });

    test('writes the mode and the routes the user kept', () async {
      notifier
        ..updateSettingNetwork(RoutingSettingNetwork.dynamicRouting)
        ..deleteRule(NamedStaticRouteEntry.fromMap(_lanRoute));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setRoutingSettings).single, {
        'isNATEnabled': false,
        'isDynamicRoutingEnabled': true,
        'entries': [_internetRoute],
      });
    });

    test('reads the routes back from the router after the write', () async {
      router.holds(JNAPAction.getRoutingSettings, _routing([_internetRoute]));

      final saved = await notifier.save();

      expect(router.actions.first, JNAPAction.setRoutingSettings);
      expect(router.actions.last, JNAPAction.getRoutingSettings);
      expect(saved.setting.entries,
          [NamedStaticRouteEntry.fromMap(_internetRoute)]);
      expect(page(), saved);
    });

    test('reports a write the router refuses, and reads nothing back',
        () async {
      router.refuses(JNAPAction.setRoutingSettings,
          result: 'ErrorInvalidGateway');
      notifier.deleteRule(NamedStaticRouteEntry.fromMap(_lanRoute));

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(router.actions, [JNAPAction.setRoutingSettings]);
      expect(page().setting.entries, hasLength(1));
    });
  });

  group('editing the list', () {
    setUp(() => notifier.fetch());

    final added = NamedStaticRouteEntry.fromMap(const {
      'name': 'Cameras',
      'settings': {
        'interface': 'LAN',
        'destinationLAN': '192.168.60.0',
        'networkPrefixLength': 24,
        'gateway': '192.168.1.253',
      },
    });

    test('adds a route at the end', () {
      notifier.addRule(added);

      expect(page().setting.entries.last, added);
      expect(page().setting.entries, hasLength(3));
    });

    test('replaces a route in place', () {
      notifier.editRule(1, added);

      expect(page().setting.entries,
          [NamedStaticRouteEntry.fromMap(_lanRoute), added]);
    });

    test('is full once it holds as many routes as the router allows', () async {
      router.holds(
          JNAPAction.getRoutingSettings, _routing([_lanRoute], max: 2));
      await notifier.fetch();
      expect(notifier.isExceedMax(), isFalse);

      notifier.addRule(added);

      expect(notifier.isExceedMax(), isTrue);
    });
  });
}
