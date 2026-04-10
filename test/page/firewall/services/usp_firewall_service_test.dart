import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

class MockUspClient extends Mock implements UspClient {}

// Helper to build a FirewallChainRule with the given fields.
FirewallChainRule _rule(
  String instancePath, {
  required bool enable,
  required String description,
  String target = 'Accept',
}) =>
    FirewallChainRule(
      instancePath: instancePath,
      enable: enable,
      description: description,
      target: target,
    );

void main() {
  late MockUspClient mockUsp;
  late UspFirewallService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspFirewallService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // parseFirewallRules
  // ---------------------------------------------------------------------------

  group('UspFirewallService — parseFirewallRules', () {
    test('maps known descriptions to feature keys', () {
      final rules = FirewallChainRules(items: [
        _rule('p.10.', enable: true, description: 'RULE_SPI_IPV4_INPUT'),
        _rule('p.11.', enable: true, description: 'RULE_SPI_IPV4_FORWARD'),
        _rule('p.21.', enable: false, description: 'RULE_LAN2WAN_IPSEC'),
      ]);

      final map = UspFirewallService.parseFirewallRules(rules);

      expect(map, hasLength(3));
      expect(map['spiV4Input']!.instancePath, 'p.10.');
      expect(map['spiV4Forward']!.instancePath, 'p.11.');
      expect(map['ipsec1']!.instancePath, 'p.21.');
    });

    test('skips unknown descriptions', () {
      final rules = FirewallChainRules(items: [
        _rule('p.1.', enable: true, description: 'RULE_SPI_IPV4_INPUT'),
        _rule('p.99.', enable: true, description: 'UNKNOWN_RULE'),
      ]);

      final map = UspFirewallService.parseFirewallRules(rules);

      expect(map, hasLength(1));
      expect(map.containsKey('spiV4Input'), isTrue);
    });

    test('empty rules returns empty map', () {
      final map = UspFirewallService.parseFirewallRules(
        FirewallChainRules(items: []),
      );
      expect(map, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // buildUIModel
  // ---------------------------------------------------------------------------

  group('UspFirewallService — buildUIModel', () {
    test('accept rules: feature ON when rule disabled', () {
      final rules = {
        'spiV4Input': _rule('p.10.', enable: false, description: ''),
        'spiV6Input': _rule('p.12.', enable: false, description: ''),
        'anonymousRequests': _rule('p.19.', enable: false, description: ''),
        'multicast': _rule('p.18.', enable: false, description: ''),
        'ident': _rule('p.20.', enable: false, description: ''),
      };

      final model = UspFirewallService.buildUIModel(rules: rules);

      expect(model.isIPv4FirewallEnabled, isTrue);
      expect(model.isIPv6FirewallEnabled, isTrue);
      expect(model.blockAnonymousRequests, isTrue);
      expect(model.blockMulticast, isTrue);
      expect(model.blockIDENT, isTrue);
    });

    test('accept rules: feature OFF when rule enabled', () {
      final rules = {
        'spiV4Input': _rule('p.10.', enable: true, description: ''),
        'spiV6Input': _rule('p.12.', enable: true, description: ''),
      };

      final model = UspFirewallService.buildUIModel(rules: rules);

      expect(model.isIPv4FirewallEnabled, isFalse);
      expect(model.isIPv6FirewallEnabled, isFalse);
    });

    test('drop rules: block ON when rule enabled', () {
      final rules = {
        'ipsec1': _rule('p.21.', enable: true, description: ''),
        'pptp': _rule('p.23.', enable: true, description: ''),
        'l2tp': _rule('p.24.', enable: true, description: ''),
      };

      final model = UspFirewallService.buildUIModel(rules: rules);

      expect(model.blockIPSec, isTrue);
      expect(model.blockPPTP, isTrue);
      expect(model.blockL2TP, isTrue);
    });

    test('drop rules: block OFF when rule disabled', () {
      final rules = {
        'ipsec1': _rule('p.21.', enable: false, description: ''),
        'pptp': _rule('p.23.', enable: false, description: ''),
        'l2tp': _rule('p.24.', enable: false, description: ''),
      };

      final model = UspFirewallService.buildUIModel(rules: rules);

      expect(model.blockIPSec, isFalse);
      expect(model.blockPPTP, isFalse);
      expect(model.blockL2TP, isFalse);
    });

    test('missing rules default to false', () {
      final model = UspFirewallService.buildUIModel(rules: {});

      // Accept rules with missing key: !(null?.enable ?? false) → !false → true
      expect(model.isIPv4FirewallEnabled, isTrue);
      // Drop rules with missing key: null?.enable ?? false → false
      expect(model.blockIPSec, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // buildSetPayload
  // ---------------------------------------------------------------------------

  group('UspFirewallService — buildSetPayload', () {
    test('no changes returns empty list', () {
      final model = FirewallUIModel();
      final updates = service.buildSetPayload(
        original: model,
        pending: model,
        rules: {},
      );
      expect(updates, isEmpty);
    });

    test('IPv4 SPI toggle generates paired updates', () {
      final rules = {
        'spiV4Input': _rule('p.10.', enable: false, description: ''),
        'spiV4Forward': _rule('p.11.', enable: false, description: ''),
      };

      final updates = service.buildSetPayload(
        original: FirewallUIModel(isIPv4FirewallEnabled: true),
        pending: FirewallUIModel(isIPv4FirewallEnabled: false),
        rules: rules,
      );

      expect(updates, hasLength(2));
      expect(updates[0].instancePath, 'p.10.');
      // Feature OFF → accept rule enabled
      expect(updates[0].enable, isTrue);
      expect(updates[1].instancePath, 'p.11.');
      expect(updates[1].enable, isTrue);
    });

    test('IPv6 SPI toggle generates paired updates', () {
      final rules = {
        'spiV6Input': _rule('p.12.', enable: true, description: ''),
        'spiV6Forward': _rule('p.13.', enable: true, description: ''),
      };

      final updates = service.buildSetPayload(
        original: FirewallUIModel(isIPv6FirewallEnabled: false),
        pending: FirewallUIModel(isIPv6FirewallEnabled: true),
        rules: rules,
      );

      expect(updates, hasLength(2));
      // Feature ON → accept rule disabled
      expect(updates[0].enable, isFalse);
    });

    test('IPSec toggle generates paired updates', () {
      final rules = {
        'ipsec1': _rule('p.21.', enable: false, description: ''),
        'ipsec2': _rule('p.22.', enable: false, description: ''),
      };

      final updates = service.buildSetPayload(
        original: FirewallUIModel(blockIPSec: false),
        pending: FirewallUIModel(blockIPSec: true),
        rules: rules,
      );

      expect(updates, hasLength(2));
      // Block ON → drop rule enabled
      expect(updates[0].enable, isTrue);
      expect(updates[1].enable, isTrue);
    });

    test('single rule toggles (PPTP, L2TP, anonymous, multicast, IDENT)', () {
      final rules = {
        'pptp': _rule('p.23.', enable: false, description: ''),
        'l2tp': _rule('p.24.', enable: false, description: ''),
        'anonymousRequests': _rule('p.19.', enable: true, description: ''),
        'multicast': _rule('p.18.', enable: true, description: ''),
        'ident': _rule('p.20.', enable: true, description: ''),
      };

      final updates = service.buildSetPayload(
        original: FirewallUIModel(),
        pending: FirewallUIModel(
          blockPPTP: true,
          blockL2TP: true,
          blockAnonymousRequests: true,
          blockMulticast: true,
          blockIDENT: true,
        ),
        rules: rules,
      );

      // 5 single-rule toggles
      expect(updates, hasLength(5));
    });

    test('missing rule in map is silently skipped', () {
      // Change IPv4 SPI but only one of the paired rules exists
      final rules = {
        'spiV4Input': _rule('p.10.', enable: false, description: ''),
        // spiV4Forward missing
      };

      final updates = service.buildSetPayload(
        original: FirewallUIModel(isIPv4FirewallEnabled: true),
        pending: FirewallUIModel(isIPv4FirewallEnabled: false),
        rules: rules,
      );

      // Only the existing rule is updated
      expect(updates, hasLength(1));
      expect(updates[0].instancePath, 'p.10.');
    });
  });

  // ---------------------------------------------------------------------------
  // buildFromChainRules (integration)
  // ---------------------------------------------------------------------------

  group('UspFirewallService — buildFromChainRules', () {
    test('returns UI model and context from chain rules', () {
      final rules = FirewallChainRules(items: [
        _rule('p.10.', enable: false, description: 'RULE_SPI_IPV4_INPUT'),
        _rule('p.11.', enable: false, description: 'RULE_SPI_IPV4_FORWARD'),
        _rule('p.21.', enable: true, description: 'RULE_LAN2WAN_IPSEC'),
      ]);

      final (model, context) = service.buildFromChainRules(rules);

      expect(model.isIPv4FirewallEnabled, isTrue);
      expect(model.blockIPSec, isTrue);
      expect(context, isNot(FirewallRuleContext.empty));
    });
  });

  // ---------------------------------------------------------------------------
  // save
  // ---------------------------------------------------------------------------

  group('UspFirewallService — save', () {
    test('no changes returns 0 and makes no USP call', () async {
      final model = FirewallUIModel();
      final context = FirewallRuleContext.fromMap({});

      final count = await service.save(
        original: model,
        pending: model,
        context: context,
      );

      expect(count, 0);
      verifyNever(() => mockUsp.set(any()));
    });

    test('changed toggles call updateMany and return count', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {});

      final rules = {
        'pptp': _rule('p.23.', enable: false, description: 'RULE_LAN2WAN_PPTP'),
      };
      final context = FirewallRuleContext.fromMap(rules);

      final count = await service.save(
        original: FirewallUIModel(blockPPTP: false),
        pending: FirewallUIModel(blockPPTP: true),
        context: context,
      );

      expect(count, 1);
    });
  });
}
