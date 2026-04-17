import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_data_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspFirewallDataService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspFirewallDataService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // Helper to stub codegen fetches
  // ---------------------------------------------------------------------------

  void stubResponses({
    List<Map<String, dynamic>> firewallRules = const [],
    List<Map<String, dynamic>> dmzEntries = const [],
  }) {
    when(() => mockUsp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List<String>;

      // FirewallChainRules.fetch (Device.Firewall.Chain.1.Rule.*)
      if (paths.any((p) => p.contains('Firewall.Chain'))) {
        final result = <String, dynamic>{};
        for (var i = 0; i < firewallRules.length; i++) {
          final rule = firewallRules[i];
          final prefix = 'Device.Firewall.Chain.1.Rule.${i + 1}.';
          result['${prefix}Enable'] = rule['enable'] ?? true;
          result['${prefix}Target'] = rule['target'] ?? 'Accept';
          result['${prefix}Description'] = rule['description'] ?? '';
        }
        return result;
      }

      // Dmz.fetch (Device.Firewall.DMZ.*)
      if (paths.any((p) => p.contains('Firewall.DMZ'))) {
        final result = <String, dynamic>{};
        for (var i = 0; i < dmzEntries.length; i++) {
          final entry = dmzEntries[i];
          final prefix = 'Device.Firewall.DMZ.${i + 1}.';
          result['${prefix}Enable'] = entry['enable'] ?? true;
          result['${prefix}DestIP'] = entry['destIp'] ?? '';
          result['${prefix}SourcePrefix'] = entry['sourcePrefix'] ?? '';
          result['${prefix}Interface'] = entry['interface'] ?? '';
          result['${prefix}Description'] = entry['description'] ?? '';
          // Status must be non-empty for entry to be parsed (codegen skips all-empty entries)
          result['${prefix}Status'] = entry['status'] ?? 'Enabled';
        }
        return result;
      }

      return {};
    });
  }

  // ---------------------------------------------------------------------------
  // DMZ UIModel building
  // ---------------------------------------------------------------------------

  group('UspFirewallDataService — DMZ UIModel', () {
    test('empty DMZ items returns disabled model', () async {
      stubResponses(dmzEntries: []);

      final result = await svc.fetch();

      expect(result.dmzModel.isEnabled, isFalse);
      expect(result.dmzModel.destIp, isEmpty);
      expect(result.dmzSummaries, isEmpty);
    });

    test('DMZ entry with empty sourcePrefix → sourceType any', () async {
      stubResponses(dmzEntries: [
        {'enable': true, 'destIp': '192.168.1.100', 'sourcePrefix': ''},
      ]);

      final result = await svc.fetch();

      expect(result.dmzModel.isEnabled, isTrue);
      expect(result.dmzModel.destIp, '192.168.1.100');
      expect(result.dmzModel.sourceType, DmzSourceType.any);
    });

    test('DMZ entry with 0.0.0.0/0 sourcePrefix → sourceType any', () async {
      stubResponses(dmzEntries: [
        {
          'enable': true,
          'destIp': '192.168.1.100',
          'sourcePrefix': '0.0.0.0/0'
        },
      ]);

      final result = await svc.fetch();

      expect(result.dmzModel.sourceType, DmzSourceType.any);
    });

    test('DMZ entry with specific CIDR → sourceType cidr', () async {
      stubResponses(dmzEntries: [
        {
          'enable': true,
          'destIp': '192.168.1.100',
          'sourcePrefix': '10.0.0.0/8'
        },
      ]);

      final result = await svc.fetch();

      expect(result.dmzModel.sourceType, DmzSourceType.cidr);
      expect(result.dmzModel.sourcePrefix, '10.0.0.0/8');
    });

    test('DMZ disabled entry', () async {
      stubResponses(dmzEntries: [
        {'enable': false, 'destIp': '192.168.1.100', 'sourcePrefix': ''},
      ]);

      final result = await svc.fetch();

      expect(result.dmzModel.isEnabled, isFalse);
      expect(result.dmzModel.destIp, '192.168.1.100');
    });

    test('DMZ summaries match entries', () async {
      stubResponses(dmzEntries: [
        {'enable': true, 'destIp': '192.168.1.100', 'sourcePrefix': ''},
        {'enable': false, 'destIp': '192.168.1.101', 'sourcePrefix': ''},
      ]);

      final result = await svc.fetch();

      expect(result.dmzSummaries, hasLength(2));
      expect(result.dmzSummaries[0].enable, isTrue);
      expect(result.dmzSummaries[0].destIp, '192.168.1.100');
      expect(result.dmzSummaries[1].enable, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Firewall rules
  // ---------------------------------------------------------------------------

  group('UspFirewallDataService — firewall rules', () {
    test('firewall rule summaries match chain rules', () async {
      stubResponses(firewallRules: [
        {'enable': true, 'target': 'Accept'},
        {'enable': false, 'target': 'Drop'},
        {'enable': true, 'target': 'Reject'},
      ]);

      final result = await svc.fetch();

      expect(result.ruleSummaries, hasLength(3));
      expect(result.ruleSummaries[0].target, 'Accept');
      expect(result.ruleSummaries[0].enabled, isTrue);
      expect(result.ruleSummaries[1].target, 'Drop');
      expect(result.ruleSummaries[1].enabled, isFalse);
      expect(result.ruleSummaries[2].target, 'Reject');
    });

    test('empty rules returns empty summaries and context', () async {
      stubResponses(firewallRules: []);

      final result = await svc.fetch();

      expect(result.ruleSummaries, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  group('UspFirewallDataService — error handling', () {
    test('fetch maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Transport error');

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });
  });
}
