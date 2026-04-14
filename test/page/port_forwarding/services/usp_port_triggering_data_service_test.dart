import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_triggering_data_service.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;
  late UspPortTriggeringDataService svc;

  setUp(() {
    mockUsp = MockUspService();
    svc = UspPortTriggeringDataService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------

  void stubPortTriggeringResponse(List<Map<String, dynamic>> triggers) {
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((_) async {
      final result = <String, dynamic>{};
      for (var i = 0; i < triggers.length; i++) {
        final trigger = triggers[i];
        final prefix = 'Device.NAT.PortTrigger.${i + 1}.';
        result['${prefix}Enable'] = trigger['enabled'] ?? true;
        result['${prefix}Description'] = trigger['description'] ?? 'Trigger';
        // Codegen uses Port, not TriggerPort
        result['${prefix}Port'] = trigger['triggerPort'] ?? 21;
        result['${prefix}PortEndRange'] = trigger['triggerPortEndRange'] ?? 0;
        result['${prefix}Protocol'] = trigger['triggerProtocol'] ?? 'TCP';

        // Forward rules use Rule.*.Port path
        final forwardRules =
            trigger['forwardRules'] as List<Map<String, dynamic>>? ?? [];
        for (var j = 0; j < forwardRules.length; j++) {
          final fwd = forwardRules[j];
          final fwdPrefix = '${prefix}Rule.${j + 1}.';
          result['${fwdPrefix}Port'] = fwd['forwardPort'] ?? 20;
          result['${fwdPrefix}PortEndRange'] = fwd['forwardPortEndRange'] ?? 0;
          result['${fwdPrefix}Protocol'] = fwd['forwardProtocol'] ?? 'TCP';
        }
      }
      return result;
    });
  }

  // ---------------------------------------------------------------------------
  // fetch
  // ---------------------------------------------------------------------------

  group('UspPortTriggeringDataService — fetch', () {
    test('returns empty list when no triggers', () async {
      stubPortTriggeringResponse([]);

      final result = await svc.fetch();

      expect(result, isEmpty);
    });

    test('transforms triggers to UI models', () async {
      stubPortTriggeringResponse([
        {
          'enabled': true,
          'description': 'FTP Trigger',
          'triggerPort': 21,
          'triggerPortEndRange': 0,
          'triggerProtocol': 'TCP',
          'forwardRules': [
            {
              'forwardPort': 20,
              'forwardPortEndRange': 0,
              'forwardProtocol': 'TCP',
            },
          ],
        },
      ]);

      final result = await svc.fetch();

      expect(result, hasLength(1));
      expect(result[0].enabled, isTrue);
      expect(result[0].description, 'FTP Trigger');
      expect(result[0].triggerPort, 21);
      expect(result[0].triggerProtocol, 'TCP');
      expect(result[0].forwardRules, hasLength(1));
      expect(result[0].forwardRules[0].forwardPort, 20);
    });

    test('includes instancePath in UI models', () async {
      stubPortTriggeringResponse([
        {'description': 'Trigger 1'},
      ]);

      final result = await svc.fetch();

      expect(result[0].instancePath, 'Device.NAT.PortTrigger.1.');
    });

    test('handles multiple forward rules per trigger', () async {
      stubPortTriggeringResponse([
        {
          'description': 'Multi-forward',
          'forwardRules': [
            {'forwardPort': 100, 'forwardProtocol': 'TCP'},
            {'forwardPort': 200, 'forwardProtocol': 'UDP'},
          ],
        },
      ]);

      final result = await svc.fetch();

      expect(result[0].forwardRules, hasLength(2));
      expect(result[0].forwardRules[0].forwardPort, 100);
      expect(result[0].forwardRules[1].forwardPort, 200);
    });
  });

  // ---------------------------------------------------------------------------
  // error handling
  // ---------------------------------------------------------------------------

  group('UspPortTriggeringDataService — error handling', () {
    test('fetch maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error');

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });
  });
}
