import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_forwarding_data_service.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;
  late UspPortForwardingDataService svc;

  setUp(() {
    mockUsp = MockUspService();
    svc = UspPortForwardingDataService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------

  void stubPortForwardingResponse(List<Map<String, dynamic>> rules) {
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((_) async {
      final result = <String, dynamic>{};
      for (var i = 0; i < rules.length; i++) {
        final rule = rules[i];
        final prefix = 'Device.NAT.PortMapping.${i + 1}.';
        result['${prefix}Enable'] = rule['enabled'] ?? true;
        result['${prefix}ExternalPort'] = rule['externalPort'] ?? 80;
        result['${prefix}ExternalPortEndRange'] =
            rule['externalPortEndRange'] ?? 0;
        result['${prefix}InternalPort'] = rule['internalPort'] ?? 80;
        result['${prefix}InternalClient'] =
            rule['internalClient'] ?? '192.168.1.100';
        result['${prefix}Protocol'] = rule['protocol'] ?? 'TCP';
        result['${prefix}Description'] = rule['description'] ?? 'Test Rule';
      }
      return result;
    });
  }

  // ---------------------------------------------------------------------------
  // fetch
  // ---------------------------------------------------------------------------

  group('UspPortForwardingDataService — fetch', () {
    test('returns empty list when no rules', () async {
      stubPortForwardingResponse([]);

      final result = await svc.fetch();

      expect(result, isEmpty);
    });

    test('transforms rules to UI models', () async {
      stubPortForwardingResponse([
        {
          'enabled': true,
          'externalPort': 8080,
          'externalPortEndRange': 8090,
          'internalPort': 80,
          'internalClient': '192.168.1.50',
          'protocol': 'TCP',
          'description': 'Web Server',
        },
        {
          'enabled': false,
          'externalPort': 22,
          'externalPortEndRange': 0,
          'internalPort': 22,
          'internalClient': '192.168.1.100',
          'protocol': 'TCP',
          'description': 'SSH',
        },
      ]);

      final result = await svc.fetch();

      expect(result, hasLength(2));

      expect(result[0].enabled, isTrue);
      expect(result[0].externalPort, 8080);
      expect(result[0].externalPortEndRange, 8090);
      expect(result[0].internalPort, 80);
      expect(result[0].internalClient, '192.168.1.50');
      expect(result[0].protocol, 'TCP');
      expect(result[0].description, 'Web Server');

      expect(result[1].enabled, isFalse);
      expect(result[1].description, 'SSH');
    });

    test('includes instancePath in UI models', () async {
      stubPortForwardingResponse([
        {'description': 'Rule 1'},
      ]);

      final result = await svc.fetch();

      expect(result[0].instancePath, 'Device.NAT.PortMapping.1.');
    });
  });

  // ---------------------------------------------------------------------------
  // error handling
  // ---------------------------------------------------------------------------

  group('UspPortForwardingDataService — error handling', () {
    test('fetch maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error');

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });
  });
}
