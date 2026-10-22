import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';

import '../../../mocks/test_data/local_network_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;

  /// The LAN data GETs: `LanNetworkInfo` on Interface.3, the `dhcp-lan` pool
  /// on Pool.4 (behind the guest pool on Pool.2).
  final lanInterfaceResponse = LocalNetworkTestData.lanInterfaceResponse(
    hostName: 'LinksysRouter',
    ipv6Enabled: true,
  );
  final lanPoolResponse = LocalNetworkTestData.lanPoolResponse(
    minAddress: '192.168.1.100',
    maxAddress: '192.168.1.199',
    leaseTime: '7200',
    dnsServers: '8.8.8.8,8.8.4.4',
  );

  /// The LAN interface's IPv6 address table, `LanIpv6` rows from 3.
  Map<String, dynamic> ipv6Table(List<String> addresses) => {
        for (var i = 0; i < addresses.length; i++)
          '${LocalNetworkTestData.lanInterface}IPv6Address.${i + 3}.IPAddress':
              addresses[i],
      };

  /// Includes a link-local (fe80::) address (kept but reordered after global,
  /// tagged by the UI) and a global address that must be preferred first (#1129).
  final ipv6Response = ipv6Table(['fe80::1', '2001:db8::1']);

  void stubLan({Object? ipv6}) {
    when(() => mockUsp.get(any())).thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List<String>;
      if (ipv6 is Exception &&
          paths.contains('${LocalNetworkTestData.lanInterface}IPv6Address.')) {
        throw ipv6;
      }
      return LocalNetworkTestData.answer(
        paths,
        lanInterfaceGet: lanInterfaceResponse,
        lanPoolGet: lanPoolResponse,
        ipv6Addresses: ipv6 is Map<String, dynamic> ? ipv6 : ipv6Response,
      );
    });
  }

  setUp(() {
    mockUsp = MockUspClient();
    stubLan();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
      ],
    );
  }

  group('LanDataNotifier', () {
    test('build fetches LAN info and IPv6', () async {
      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      expect(data.model.ipAddress, '192.168.1.1');
      expect(data.model.subnetMask, '255.255.255.0');
      expect(data.model.dhcpEnabled, isTrue);
      expect(data.model.minAddress, '192.168.1.100');
      expect(data.model.maxAddress, '192.168.1.199');
      expect(data.model.leaseTimeMinutes, 120); // 7200s / 60
      expect(data.model.dnsServers, '8.8.8.8,8.8.4.4');
      expect(data.model.hostName, 'LinksysRouter');
      expect(data.model.ipv6Enabled, isTrue);
      // #1129: link-local fe80:: is kept but reordered after the global address
      // (the UI tags it with a scope badge rather than hiding it).
      expect(data.model.ipv6Addresses, ['2001:db8::1', 'fe80::1']);
      container.dispose();
    });

    test('reads the dhcp-lan pool, not the guest pool in front of it',
        () async {
      // The guest pool (cpe-2) is on a lower row than the LAN pool.
      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      expect(data.model.minAddress, '192.168.1.100');
      expect(data.model.maxAddress, '192.168.1.199');
      final requested = verify(() => mockUsp.get(captureAny()))
          .captured
          .cast<List<String>>()
          .expand((paths) => paths);
      expect(
          requested.where((p) => p.startsWith(LocalNetworkTestData.guestPool)),
          isEmpty,
          reason: 'the guest pool must not be read as the LAN pool');
      container.dispose();
    });

    test('a LAN interface with no address row reads an empty IP', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((invocation) async => LocalNetworkTestData.answer(
                invocation.positionalArguments[0] as List<String>,
                lanInterfaceGet: LocalNetworkTestData.lanInterfaceResponse(
                    hasAddress: false),
              ));

      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      expect(data.model.ipAddress, isEmpty);
      expect(data.model.subnetMask, isEmpty);
      expect(data.model.minAddress, '192.168.1.100');
      container.dispose();
    });

    test('link-local-only IPv6 keeps the link-local address (#1129)', () async {
      // Reproduces the reported case: br-lan holds only a scope-link fe80::
      // address and no global/ULA prefix. It is still surfaced (tagged with a
      // scope badge by the UI), not hidden.
      stubLan(ipv6: ipv6Table(['fe80::7612:13ff:fe21:5394']));

      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      expect(data.model.ipv6Enabled, isTrue);
      expect(data.model.ipv6Addresses, ['fe80::7612:13ff:fe21:5394']);
      container.dispose();
    });

    test('link-local reordered after global, all kept (#1129)', () async {
      stubLan(ipv6: ipv6Table(['fe80::1%eth0', 'febf::1', '2001:db8:abcd::5']));

      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      // fe80::1%eth0 (zone index) and febf::1 (top of fe80::/10) are link-local;
      // all addresses are kept, with the global one surfaced first.
      expect(data.model.ipv6Addresses,
          ['2001:db8:abcd::5', 'fe80::1%eth0', 'febf::1']);
      container.dispose();
    });

    test('fec0::1 is NOT link-local (#1129)', () async {
      // fec0::1 is the first address just above the fe80::/10 range
      // (link-local spans fe80::-febf::). It is a deprecated site-local
      // address (RFC 3513), NOT link-local:
      //   0xfec0 & 0xffc0 == 0xfec0 != 0xfe80
      // It is kept and, not being link-local, is not tagged as such by the UI.
      stubLan(ipv6: ipv6Table(['fec0::1']));

      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      expect(data.model.ipv6Addresses, ['fec0::1']);
      container.dispose();
    });

    test('build throws ServiceNotInitializedError when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(null),
        ],
      );

      expect(
        container.read(lanDataProvider.future),
        throwsA(isA<ServiceNotInitializedError>()),
      );
      container.dispose();
    });

    test('IPv6 fetch failure falls back to disabled', () async {
      stubLan(ipv6: Exception('IPv6 not supported'));

      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      // LAN info should still be present
      expect(data.model.ipAddress, '192.168.1.1');
      // ipv6Enabled comes from LanNetworkInfo (still true from IPv6Enable key),
      // but addresses should be empty because the address fetch failed
      expect(data.model.ipv6Enabled, isTrue);
      expect(data.model.ipv6Addresses, isEmpty);
      container.dispose();
    });

    test('dhcpRange formats min ~ max', () async {
      final container = createContainer();
      final data = await container.read(lanDataProvider.future);

      expect(data.model.dhcpRange, '192.168.1.100 ~ 192.168.1.199');
      container.dispose();
    });

    test('LanData.empty() has default values', () {
      const data = LanData.empty();
      expect(data.model.ipAddress, isEmpty);
      expect(data.model.subnetMask, isEmpty);
      expect(data.model.dhcpEnabled, isFalse);
      expect(data.model.minAddress, isEmpty);
      expect(data.model.maxAddress, isEmpty);
    });

    test('LanData equality uses model props', () async {
      final container = createContainer();
      final data1 = await container.read(lanDataProvider.future);
      final data2 = await container.read(lanDataProvider.future);

      expect(data1, equals(data2));
      expect(data1.props, [data1.model]);

      const empty = LanData.empty();
      expect(data1, isNot(equals(empty)));
      container.dispose();
    });

    test('fetch maps USP transport error to ServiceError', () async {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Request timeout');

      final container = createContainer();

      expect(
        container.read(lanDataProvider.future),
        throwsA(isA<NetworkError>()),
      );
      container.dispose();
    });
  });
}
