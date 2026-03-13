import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/usp/models/usp_response.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/usp_page/internet_settings/services/usp_internet_settings_service.dart';

class MockUspService extends Mock implements UspService {}

// Test data constants
const _dhcpWanResponse = <String, dynamic>{
  'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
  'Device.IP.Interface.2.MaxMTUSize': '1500',
  'Device.IP.Interface.2.IPv4Address.1.IPAddress': '192.168.1.100',
  'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
  'Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress': '192.168.1.1',
  'Device.DNS.Client.Server.1.DNSServer': '8.8.8.8',
  'Device.DNS.Client.Server.2.DNSServer': '8.8.4.4',
  'Device.DNS.Client.Server.3.DNSServer': '',
  'Device.PPP.Interface.1.Username': '',
  'Device.PPP.Interface.1.Password': '',
  'Device.PPP.Interface.1.PPPoE.ServiceName': '',
  'Device.PPP.Interface.1.ConnectionTrigger': 'AlwaysOn',
  'Device.PPP.Interface.1.IdleDisconnectTime': '0',
  'Device.PPP.Interface.1.LCPEcho': '30',
  'Device.PPP.Interface.1.ConnectionStatus': 'Connected',
  'Device.Ethernet.VLANTermination.1.Enable': false,
  'Device.Ethernet.VLANTermination.1.VLANID': '0',
  'Device.Bridging.Bridge.1.Enable': false,
  'Device.Ethernet.Link.1.MACAddress': 'AA:BB:CC:DD:EE:FF',
  'Device.Ethernet.Interface.1.MACAddress': '11:22:33:44:55:66',
};

const _ipv6Response = <String, dynamic>{
  'Device.IP.Interface.2.IPv6Enable': true,
  'Device.DHCPv6.Client.1.Enable': true,
  'Device.DHCPv6.Client.1.DUID': '00:01:00:01:2a:3b:4c:5d',
  'Device.IPv6rd.InterfaceSetting.1.Enable': false,
  'Device.IPv6rd.InterfaceSetting.1.SPIPv6Prefix': '',
  'Device.IPv6rd.InterfaceSetting.1.IPv4MaskLength': '0',
  'Device.IPv6rd.InterfaceSetting.1.BorderRelayIPv4Addresses': '',
};

void main() {
  late MockUspService mockUsp;
  late UspInternetSettingsService service;

  setUp(() {
    mockUsp = MockUspService();
    service = UspInternetSettingsService(mockUsp);
  });

  group('fetchSettings', () {
    test('fetches WAN and IPv6 settings in parallel', () async {
      when(() => mockUsp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths
            .contains('Device.IP.Interface.2.IPv4Address.1.AddressingType')) {
          return _dhcpWanResponse;
        }
        return _ipv6Response;
      });

      final (wan, ipv6) = await service.fetchSettings();

      expect(wan.addressingType, equals('DHCP'));
      expect(wan.mtu, equals(1500));
      expect(wan.staticIpAddress, equals('192.168.1.100'));
      expect(ipv6.ipv6Enabled, isTrue);
      expect(ipv6.dhcpv6Enabled, isTrue);
      expect(ipv6.ipv6rdEnabled, isFalse);
    });
  });

  group('saveAll', () {
    setUp(() {
      when(() => mockUsp.set(any())).thenAnswer((_) async {});
    });

    test('sends only changed WAN fields', () async {
      final original = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
        staticIpAddress: '192.168.1.100',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.1',
        dnsServer1: '8.8.8.8',
      );

      final edited = original.copyWith(mtu: 1400);

      await service.saveAll(original, edited);

      // WanSettings.save should be called — verify set was called
      verify(() => mockUsp.set(any())).called(greaterThanOrEqualTo(1));
    });

    test('does not send unchanged fields', () async {
      final form = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
        mtu: 1500,
      );

      await service.saveAll(form, form);

      // Both WanSettings.save and Ipv6Settings.save will be called
      // but with empty params maps, which means set() won't be called
      // because the generated code checks `if (params.isNotEmpty)`
      verifyNever(() => mockUsp.set(any()));
    });
  });

  group('renewDhcpLease', () {
    test('calls WanOperations.renewDhcpLease', () async {
      when(() => mockUsp.operate(any()))
          .thenAnswer((_) async => UspResponse(data: <String, String>{}));

      await service.renewDhcpLease();

      verify(() => mockUsp.operate('Device.DHCPv4.Client.1.Renew()')).called(1);
    });
  });

  group('renewDhcpv6Lease', () {
    test('calls WanOperations.renewDhcpv6Lease', () async {
      when(() => mockUsp.operate(any()))
          .thenAnswer((_) async => UspResponse(data: <String, String>{}));

      await service.renewDhcpv6Lease();

      verify(() => mockUsp.operate('Device.DHCPv6.Client.1.Renew()')).called(1);
    });
  });
}
