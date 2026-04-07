import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';
import 'package:privacy_gui/page/instant_safety/services/instant_safety_service.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;
  late UspInstantSafetyService service;

  setUp(() {
    mockUsp = MockUspService();
    service = UspInstantSafetyService(mockUsp);
  });

  group('UspInstantSafetyService — buildUIModel', () {
    test('detects OpenDNS from matching first DNS entry', () {
      final data = LanNetworkInfo(
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        dhcpEnabled: true,
        minAddress: '192.168.1.100',
        maxAddress: '192.168.1.200',
        leaseTime: 86400,
        dnsServers: '208.67.222.222,208.67.220.220',
        hostName: 'router',
        ipv6Enabled: false,
      );

      final model = service.buildUIModel(data);

      expect(model.type, SafeBrowsingType.openDNS);
      expect(model.isEnabled, isTrue);
      expect(model.currentDnsServers, '208.67.222.222,208.67.220.220');
    });

    test('detects off when DNS is different', () {
      final data = LanNetworkInfo(
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        dhcpEnabled: true,
        minAddress: '192.168.1.100',
        maxAddress: '192.168.1.200',
        leaseTime: 86400,
        dnsServers: '8.8.8.8,8.8.4.4',
        hostName: 'router',
        ipv6Enabled: false,
      );

      final model = service.buildUIModel(data);

      expect(model.type, SafeBrowsingType.off);
      expect(model.isEnabled, isFalse);
    });

    test('detects off when DNS is empty', () {
      final data = LanNetworkInfo(
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        dhcpEnabled: true,
        minAddress: '192.168.1.100',
        maxAddress: '192.168.1.200',
        leaseTime: 86400,
        dnsServers: '',
        hostName: 'router',
        ipv6Enabled: false,
      );

      final model = service.buildUIModel(data);

      expect(model.type, SafeBrowsingType.off);
    });
  });

  group('UspInstantSafetyService — dnsValueForType', () {
    test('openDNS returns full DNS string', () {
      expect(
        service.dnsValueForType(SafeBrowsingType.openDNS),
        '208.67.222.222,208.67.220.220',
      );
    });

    test('off returns empty string', () {
      expect(service.dnsValueForType(SafeBrowsingType.off), '');
    });
  });

  group('UspInstantSafetyService — fetch', () {
    test('fetch returns SafeBrowsingUIModel from router data', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.IP.Interface.1.IPv4Address.1.IPAddress': '192.168.1.1',
            'Device.IP.Interface.1.IPv4Address.1.SubnetMask': '255.255.255.0',
            'Device.DHCPv4.Server.Pool.1.Enable': true,
            'Device.DHCPv4.Server.Pool.1.MinAddress': '192.168.1.100',
            'Device.DHCPv4.Server.Pool.1.MaxAddress': '192.168.1.200',
            'Device.DHCPv4.Server.Pool.1.LeaseTime': '86400',
            'Device.DHCPv4.Server.Pool.1.DNSServers':
                '208.67.222.222,208.67.220.220',
            'Device.DeviceInfo.HostName': 'router',
          });

      final model = await service.fetch();

      expect(model.type, SafeBrowsingType.openDNS);
      expect(model.isEnabled, isTrue);
    });
  });

  group('UspInstantSafetyService — save', () {
    test('save(openDNS) writes OpenDNS values', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {});

      await service.save(SafeBrowsingType.openDNS);

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      expect(captured, hasLength(1));
      final params = captured.first as Map<String, dynamic>;
      expect(
        params['Device.DHCPv4.Server.Pool.1.DNSServers'],
        '208.67.222.222,208.67.220.220',
      );
    });

    test('save(off) writes empty string', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {});

      await service.save(SafeBrowsingType.off);

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      final params = captured.first as Map<String, dynamic>;
      expect(params['Device.DHCPv4.Server.Pool.1.DNSServers'], '');
    });
  });

  group('UspInstantSafetyService — error handling', () {
    test('fetch maps USP error to ServiceError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Request timeout');

      expect(() => service.fetch(), throwsA(isA<NetworkError>()));
    });

    test('save maps USP error to ServiceError', () {
      when(() => mockUsp.set(any()))
          .thenThrow('Set failed: Authentication error: Session expired');

      expect(
        () => service.save(SafeBrowsingType.openDNS),
        throwsA(isA<SessionTokenExpiredError>()),
      );
    });
  });
}
