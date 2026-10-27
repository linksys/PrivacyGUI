import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';
import 'package:privacy_gui/page/instant_safety/services/instant_safety_service.dart';

import '../../../mocks/test_data/local_network_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspInstantSafetyService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspInstantSafetyService(mockUsp);
  });

  group('UspInstantSafetyService — buildUIModel', () {
    test('detects OpenDNS from matching first DNS entry', () {
      final data = LocalNetworkTestData.createLanDhcpPool(
          dnsServers: '208.67.222.222,208.67.220.220');

      final model = service.buildUIModel(data);

      expect(model.type, SafeBrowsingType.openDNS);
      expect(model.isEnabled, isTrue);
      expect(model.currentDnsServers, '208.67.222.222,208.67.220.220');
    });

    test('detects off when DNS is different', () {
      final data =
          LocalNetworkTestData.createLanDhcpPool(dnsServers: '8.8.8.8,8.8.4.4');

      final model = service.buildUIModel(data);

      expect(model.type, SafeBrowsingType.off);
      expect(model.isEnabled, isFalse);
    });

    test('detects off when DNS is empty', () {
      final data = LocalNetworkTestData.createLanDhcpPool(dnsServers: '');

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
      when(() => mockUsp.get(any()))
          .thenAnswer((invocation) async => LocalNetworkTestData.answer(
                invocation.positionalArguments[0] as List<String>,
                lanPoolGet: LocalNetworkTestData.lanPoolResponse(
                    dnsServers: '208.67.222.222,208.67.220.220'),
              ));

      final model = await service.fetch();

      expect(model.type, SafeBrowsingType.openDNS);
      expect(model.isEnabled, isTrue);
    });
  });

  group('UspInstantSafetyService — save', () {
    // LanDhcpPool.update resolves the pool by Alias: the guest pool on
    // Pool.2, dhcp-lan on Pool.4.
    final aliasResponse = LocalNetworkTestData.poolAliases();

    test('save(openDNS) writes OpenDNS values', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => aliasResponse);
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.save(SafeBrowsingType.openDNS);

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      expect(captured, hasLength(1));
      final params = captured.first as Map<String, dynamic>;
      expect(params, {
        '${LocalNetworkTestData.lanPool}DNSServers':
            '208.67.222.222,208.67.220.220',
      });
    });

    test('save(off) writes empty string', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => aliasResponse);
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.save(SafeBrowsingType.off);

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      final params = captured.first as Map<String, dynamic>;
      expect(params, {'${LocalNetworkTestData.lanPool}DNSServers': ''});
    });
  });

  group('UspInstantSafetyService — error handling', () {
    // LanDhcpPool.update resolves the pool by Alias: the guest pool on
    // Pool.2, dhcp-lan on Pool.4.
    final aliasResponse = LocalNetworkTestData.poolAliases();

    test('fetch maps USP error to ServiceError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Request timeout');

      expect(() => service.fetch(), throwsA(isA<NetworkError>()));
    });

    test('save maps USP error to ServiceError', () {
      when(() => mockUsp.get(any())).thenAnswer((_) async => aliasResponse);
      when(() => mockUsp.set(any()))
          .thenThrow('Set failed: Authentication error: Session expired');

      expect(
        () => service.save(SafeBrowsingType.openDNS),
        throwsA(isA<SessionTokenExpiredError>()),
      );
    });
  });
}
