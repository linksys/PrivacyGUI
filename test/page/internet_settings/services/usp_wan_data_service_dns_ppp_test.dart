import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/active_ipv4_connection.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/dns_client.g.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_wan_data_service.dart';

import '../../../mocks/test_data/internet_settings_test_data.dart';

class _MockUspClient extends Mock implements UspClient {}

/// linksys/PrivacyGUI#1702 — the Network Status card's DNS row, its PPP type
/// and its gateway on the TR-181 path, against the contract in FW's comment on
/// linksys/FWDEV#212:
///
/// - DNS: the enabled `Device.DNS.Client.Server.*.DNSServer` rows whose
///   `Interface` is the WAN, IPv4 only.
/// - Type: for `IPCP`, `PPP.Interface.{i}.LowerLayers` decides —
///   `GRE.Tunnel` = PPTP, `L2TPv2.Tunnel` = L2TP, anything else = PPPoE.
/// - Gateway: of the default routes on the WAN, the lowest `ForwardingMetric`.
///
/// The WAN is on `Interface.5` (see [InternetSettingsTestData]), so nothing
/// here passes on an assumed `Interface.2`.
void main() {
  const wan = InternetSettingsTestData.wanInterface; // Device.IP.Interface.5.
  late _MockUspClient usp;

  setUp(() => usp = _MockUspClient());

  /// One `Device.DNS.Client.Server.{i}.` row.
  Map<String, dynamic> dnsRow(
    int i, {
    required String address,
    String iface = 'Device.IP.Interface.5',
    Object enable = true,
  }) =>
      {
        'Device.DNS.Client.Server.$i.DNSServer': address,
        'Device.DNS.Client.Server.$i.Type': 'DHCPv4',
        'Device.DNS.Client.Server.$i.Enable': enable,
        'Device.DNS.Client.Server.$i.Status': 'Enabled',
        'Device.DNS.Client.Server.$i.Alias': 'cpe-$i',
        'Device.DNS.Client.Server.$i.Interface': iface,
      };

  /// The `DnsClient` GET: the WAN's two IPv4 resolvers, plus the rows the
  /// filter must drop — a disabled one, one on the LAN, one on an interface
  /// whose number only *starts* with the WAN's (`Interface.50`), and an IPv6
  /// one on the WAN.
  Map<String, dynamic> dnsTable() => {
        'Device.DNS.Client.Enable': true,
        'Device.DNS.Client.Status': 'Enabled',
        'Device.DNS.Client.ServerNumberOfEntries': 6,
        ...dnsRow(1, address: '203.0.113.53'),
        ...dnsRow(2, address: '192.0.2.99', enable: false),
        ...dnsRow(3, address: '192.168.1.1', iface: 'Device.IP.Interface.3'),
        ...dnsRow(4, address: '198.18.0.53', iface: 'Device.IP.Interface.50'),
        ...dnsRow(5, address: '2001:db8::53'),
        // With a trailing dot, which the router may report either way.
        ...dnsRow(6, address: '198.51.100.53', iface: 'Device.IP.Interface.5.'),
      };

  /// `Device.PPP.Interface.*`: one row, on [lowerLayers].
  Map<String, dynamic> pppTable(String lowerLayers) => {
        'Device.PPP.Interface.1.Username': 'user',
        'Device.PPP.Interface.1.Password': '',
        'Device.PPP.Interface.1.PPPoE.ServiceName': '',
        'Device.PPP.Interface.1.ConnectionTrigger': 'AlwaysOn',
        'Device.PPP.Interface.1.IdleDisconnectTime': 0,
        'Device.PPP.Interface.1.LowerLayers': lowerLayers,
        'Device.PPP.Interface.1.LCPEcho': 30,
        'Device.PPP.Interface.1.LCPEchoRetry': 3,
        'Device.PPP.Interface.1.ConnectionStatus': 'Connected',
      };

  /// Two default routes on the WAN, the tunnel's (metric 0) listed AFTER the
  /// underlay's (metric 10) — the PPTP / L2TP layout FW measured on
  /// linksys/FWDEV#212, in the order that a first-match read gets wrong.
  Map<String, dynamic> tunnelRouting() {
    const r = 'Device.Routing.Router.1.';
    Map<String, dynamic> route(int i, String gw, int metric,
            {String iface = 'Device.IP.Interface.5',
            String dest = '0.0.0.0'}) =>
        {
          '${r}IPv4Forwarding.$i.Enable': true,
          '${r}IPv4Forwarding.$i.DestIPAddress': dest,
          '${r}IPv4Forwarding.$i.DestSubnetMask': '0.0.0.0',
          '${r}IPv4Forwarding.$i.GatewayIPAddress': gw,
          '${r}IPv4Forwarding.$i.Interface': iface,
          '${r}IPv4Forwarding.$i.Origin': 'Automatic',
          '${r}IPv4Forwarding.$i.ForwardingMetric': '$metric',
          '${r}IPv4Forwarding.$i.Alias': 'route-$i',
        };
    return {
      '${r}Alias': 'cpe-1',
      ...route(1, '10.0.0.1', 10), // underlay, first
      ...route(2, '192.0.2.1', -1, iface: 'Device.IP.Interface.3'), // LAN side
      ...route(3, '192.0.2.2', 0, dest: '10.0.0.0'), // not a default route
      ...route(4, '172.16.0.1', 0), // tunnel, lowest metric
      ...route(5, '172.16.0.9', 0), // a tie: the first listed is kept
    };
  }

  /// Answers every GET of a WAN status read by the paths requested.
  void stub({
    String addressingType = 'DHCP',
    Object? dns,
    Object? ppp,
    String wanLowerLayers = 'Device.PPP.Interface.1',
    Map<String, dynamic>? routing,
    Map<String, dynamic>? autoIPoE,
  }) {
    when(() => usp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List<String>;
      if (paths.contains(ActiveIpv4Connection.path)) {
        if (autoIPoE == null) return {};
        return {ActiveIpv4Connection.path: jsonEncode(autoIPoE)};
      }
      if (paths.contains('Device.IP.Interface.*.Alias')) {
        return InternetSettingsTestData.interfaceAliases();
      }
      if (paths.contains('${wan}Enable')) {
        return {
          '${wan}Enable': true,
          '${wan}MaxMTUSize': '1500',
          '${wan}IPv6Enable': false,
        };
      }
      if (paths.contains('${wan}Status')) {
        return InternetSettingsTestData.wanStatus(
            addressingType: addressingType);
      }
      if (paths.contains('${wan}LowerLayers')) {
        return {'${wan}LowerLayers': wanLowerLayers};
      }
      if (paths.any((p) => p.startsWith('Device.DNS.Client.'))) {
        if (dns is Exception) throw dns;
        if (dns is String) throw dns; // a WASM error is a plain String
        return (dns as Map<String, dynamic>?) ?? dnsTable();
      }
      if (paths.any((p) => p.startsWith('Device.PPP.Interface.'))) {
        if (ppp is Exception) throw ppp;
        return (ppp as Map<String, dynamic>?) ?? {};
      }
      if (paths.any((p) => p.startsWith('Device.Routing.'))) {
        return routing ?? InternetSettingsTestData.routing();
      }
      return {};
    });
  }

  // ---------------------------------------------------------------------------
  // DNS servers
  // ---------------------------------------------------------------------------

  /// The model `wanDataProvider` publishes — the one the card reads — over the
  /// real [UspWanDataService] on [usp]. The DNS row is merged there (#1702).
  Future<WanStatusUIModel> cardModel({bool autoIPoE = false}) async {
    final container = ProviderContainer(overrides: [
      uspClientProvider.overrideWithValue(usp),
      deviceCapabilitiesProvider.overrideWithValue(autoIPoE
          ? const DeviceCapabilities({DeviceCapability.autoIPoE})
          : DeviceCapabilities.empty),
      sseInvalidationProvider.overrideWith((ref) => const Stream.empty()),
    ]);
    addTearDown(container.dispose);
    return (await container.read(wanDataProvider.future)).model;
  }

  group('#1702 DNS servers in use', () {
    for (final type in ['DHCP', 'Static', 'IPCP']) {
      test('$type WAN: the enabled IPv4 resolvers on the WAN, in table order',
          () async {
        stub(
          addressingType: type,
          ppp: pppTable('Device.Ethernet.Link.2'),
        );

        final model = await cardModel();

        expect(model.dnsServers, ['203.0.113.53', '198.51.100.53']);
      });
    }

    test('Auto-IPoE path reads the same table', () async {
      stub(autoIPoE: {
        'apiVersion': 1,
        'available': true,
        'state': 'Up',
        'activeIPv4Route': true,
        'protocol': 'dhcp',
        'address': '203.0.113.1',
        'gateway': '203.0.113.254',
        'mtu': 1500,
      });

      final model = await cardModel(autoIPoE: true);

      expect(model.addressingType, 'DHCP');
      expect(model.dnsServers, ['203.0.113.53', '198.51.100.53']);
    });

    test('a failed DNS read hides the row and leaves the rest of the card',
        () async {
      stub(dns: 'Get failed: Transport error: HTTP error: HTTP 500');

      final model = await cardModel();

      expect(model.dnsServers, isEmpty);
      expect(model.ipAddress, '203.0.113.1');
      expect(model.addressingType, 'DHCP');
      expect(model.gateway, '203.0.113.254');
      expect(model.isUp, isTrue);
    });

    test('a failed DNS read on the Auto-IPoE path also leaves the card',
        () async {
      stub(
        dns: Exception('no DNS client'),
        autoIPoE: {
          'apiVersion': 1,
          'available': true,
          'state': 'Up',
          'activeIPv4Route': true,
          'protocol': 'pppoe',
          'address': '203.0.113.1',
          'mtu': 1492,
        },
      );

      final model = await cardModel(autoIPoE: true);

      expect(model.dnsServers, isEmpty);
      expect(model.addressingType, 'PPPoE');
      expect(model.ipAddress, '203.0.113.1');
    });

    test('an incomplete DNS table (a required leaf missing) hides the row',
        () async {
      stub(dns: {
        for (final e in dnsTable().entries)
          if (!e.key.endsWith('.Interface')) e.key: e.value,
      });

      final model = await cardModel();

      expect(model.dnsServers, isEmpty);
      expect(model.ipAddress, '203.0.113.1');
    });

    test('fetchDnsServers never throws on a failed read', () async {
      stub(dns: 'Get failed: Transport error');

      expect(await UspWanDataService(usp).fetchDnsServers(), isEmpty);
    });

    test('the status read alone does not touch the DNS table', () async {
      // Diagnostics calls fetch() and reads Device.DNS.Client.* itself, so the
      // shared status read must not add a DNS read of its own.
      stub();

      await UspWanDataService(usp).fetch();

      final requested =
          verify(() => usp.get(captureAny(), priority: any(named: 'priority')))
              .captured
              .cast<List<String>>()
              .expand((p) => p);
      expect(requested.any((p) => p.startsWith('Device.DNS.')), isFalse);
    });
  });

  group('#1702 wanDnsServers filter', () {
    DnsServer server(String address,
            {bool enabled = true, String iface = 'Device.IP.Interface.2'}) =>
        DnsServer(
          instancePath: 'Device.DNS.Client.Server.1.',
          address: address,
          type: 'DHCPv4',
          enabled: enabled,
          status: 'Enabled',
          alias: '',
          interface_: iface,
        );
    const wan2 = 'Device.IP.Interface.2.';

    test('keeps an enabled IPv4 server on the WAN', () {
      expect(UspWanDataService.wanDnsServers([server('8.8.8.8')], wan2),
          ['8.8.8.8']);
    });

    test('drops a disabled server', () {
      expect(
          UspWanDataService.wanDnsServers(
              [server('8.8.8.8', enabled: false)], wan2),
          isEmpty);
    });

    test('drops a server on another interface, Interface.20 included', () {
      expect(
          UspWanDataService.wanDnsServers([
            server('8.8.8.8', iface: 'Device.IP.Interface.1'),
            server('8.8.4.4', iface: 'Device.IP.Interface.20'),
            server('1.1.1.1', iface: ''),
          ], wan2),
          isEmpty);
    });

    test('drops IPv6 and anything that is not a dotted-quad IPv4', () {
      expect(
          UspWanDataService.wanDnsServers([
            server('2001:4860:4860::8888'),
            server('::ffff:8.8.8.8'),
            server('256.1.1.1'),
            server('8.8.8'),
            server(''),
          ], wan2),
          isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // PPP type
  // ---------------------------------------------------------------------------

  group('#1702 IPCP names its PPP type on the TR-181 path', () {
    for (final (lowerLayers, label) in [
      ('Device.Ethernet.Link.2', 'PPPoE'),
      ('', 'PPPoE'),
      ('Device.GRE.Tunnel.1.Interface.1', 'PPTP'),
      ('Device.L2TPv2.Tunnel.1.Interface.1', 'L2TP'),
    ]) {
      test('PPP.LowerLayers "$lowerLayers" reads as $label', () async {
        stub(addressingType: 'IPCP', ppp: pppTable(lowerLayers));

        final model = await UspWanDataService(usp).fetch();

        expect(model.addressingType, label);
      });
    }

    test('a non-IPCP WAN keeps its own type and never reads the PPP table',
        () async {
      stub(
          addressingType: 'Static',
          ppp: pppTable('Device.GRE.Tunnel.1.Interface.1'));

      final model = await UspWanDataService(usp).fetch();

      expect(model.addressingType, 'Static');
      final requested =
          verify(() => usp.get(captureAny(), priority: any(named: 'priority')))
              .captured
              .cast<List<String>>()
              .expand((p) => p);
      expect(requested.any((p) => p.startsWith('Device.PPP.')), isFalse);
    });

    test('a PPP read that fails keeps IPCP and the rest of the card', () async {
      stub(addressingType: 'IPCP', ppp: Exception('no PPP'));

      final model = await UspWanDataService(usp).fetch();

      expect(model.addressingType, 'IPCP');
      expect(model.ipAddress, '203.0.113.1');
    });

    test('several PPP rows: the one the WAN LowerLayers names wins', () async {
      stub(
        addressingType: 'IPCP',
        wanLowerLayers: 'Device.PPP.Interface.2',
        ppp: {
          ...pppTable('Device.Ethernet.Link.2'),
          for (final e
              in pppTable('Device.L2TPv2.Tunnel.1.Interface.1').entries)
            e.key.replaceFirst('Interface.1.', 'Interface.2.'): e.value,
        },
      );

      final model = await UspWanDataService(usp).fetch();

      expect(model.addressingType, 'L2TP');
    });
  });

  // ---------------------------------------------------------------------------
  // Gateway
  // ---------------------------------------------------------------------------

  group('#1702 gateway is the lowest-metric default route on the WAN', () {
    test('PPTP / L2TP: the tunnel route wins over the underlay listed first',
        () async {
      stub(
        addressingType: 'IPCP',
        ppp: pppTable('Device.GRE.Tunnel.1.Interface.1'),
        routing: tunnelRouting(),
      );

      final model = await cardModel();

      expect(model.gateway, '172.16.0.1');
      expect(model.addressingType, 'PPTP');
      expect(model.dnsServers, ['203.0.113.53', '198.51.100.53']);
    });

    test('a single default route is still found', () async {
      stub(routing: InternetSettingsTestData.routing(gateway: '10.9.9.1'));

      final model = await UspWanDataService(usp).fetch();

      expect(model.gateway, '10.9.9.1');
    });
  });
}
