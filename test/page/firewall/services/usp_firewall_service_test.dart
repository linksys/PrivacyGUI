import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
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

    // FLWRT 2.0.3 ships RULE_NAT_REDIRECTION as an Accept rule, enabled by
    // default: NAT loopback allowed, so "Filter Internet NAT redirection" reads
    // OFF (FWDEV#204, measured on 2.0.3.26100921).
    test('NAT redirection: an enabled rule reads as not blocked', () {
      final map = UspFirewallService.parseFirewallRules(
        FirewallChainRules(items: [
          _rule('p.31.', enable: true, description: 'RULE_NAT_REDIRECTION'),
        ]),
      );

      final model = UspFirewallService.buildUIModel(rules: map);

      expect(model.blockNATRedirection, isFalse);
    });

    test('NAT redirection: a disabled rule reads as blocked', () {
      final map = UspFirewallService.parseFirewallRules(
        FirewallChainRules(items: [
          _rule('p.31.', enable: false, description: 'RULE_NAT_REDIRECTION'),
        ]),
      );

      final model = UspFirewallService.buildUIModel(rules: map);

      expect(model.blockNATRedirection, isTrue);
    });

    // This test was named "missing rules default to false" and asserted the
    // IPv4 switch read true: an Accept rule with no rule read as "filter on",
    // a value no router reported. A switch with no rule behind it does
    // nothing, so it reads off (#1611).
    test('a switch with no rule behind it reads off', () {
      final model = UspFirewallService.buildUIModel(rules: {});

      expect(model.isIPv4FirewallEnabled, isFalse);
      expect(model.isIPv6FirewallEnabled, isFalse);
      expect(model.blockAnonymousRequests, isFalse);
      expect(model.blockMulticast, isFalse);
      expect(model.blockIDENT, isFalse);
      expect(model.blockNATRedirection, isFalse);
      expect(model.blockIPSec, isFalse);
      expect(model.blockPPTP, isFalse);
      expect(model.blockL2TP, isFalse);
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

    test('NAT redirection: blocking it disables the rule', () {
      final rules = {
        'natRedirection': _rule('p.31.', enable: true, description: ''),
      };

      final updates = service.buildSetPayload(
        original: FirewallUIModel(blockNATRedirection: false),
        pending: FirewallUIModel(blockNATRedirection: true),
        rules: rules,
      );

      expect(updates, hasLength(1));
      expect(updates.single.instancePath, 'p.31.');
      expect(updates.single.enable, isFalse);
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
  // FirewallRuleContext.controls
  // ---------------------------------------------------------------------------

  // A switch whose rule is absent shows a value the router never reported, and
  // saving it with a matched one wrote only the matched one (#1611).
  group('FirewallRuleContext — controls', () {
    test('a switch is controllable only when every rule behind it is present',
        () {
      final context = FirewallRuleContext.fromMap({
        'spiV4Input': _rule('p.21.', enable: false, description: ''),
        // spiV4Forward missing: the IPv4 switch is a pair
        'ident': _rule('p.26.', enable: false, description: ''),
      });

      expect(context.controls(FirewallSwitch.ipv4Firewall), isFalse);
      expect(context.controls(FirewallSwitch.ident), isTrue);
      expect(context.controls(FirewallSwitch.natRedirection), isFalse);
    });

    test('the 2.0.3 rule set controls every switch', () {
      final context = FirewallRuleContext.fromMap(
        UspFirewallService.parseFirewallRules(FirewallChainRules(items: [
          for (final (i, d) in const [
            (11, 'UDP_FORWARD_FOR_IGMP'),
            (21, 'RULE_SPI_IPV4_INPUT'),
            (22, 'RULE_SPI_IPV4_FORWARD'),
            (23, 'RULE_SPI_IPV6_INPUT'),
            (24, 'RULE_SPI_IPV6_FORWARD'),
            (25, 'RULE_PING_IPV4'),
            (26, 'RULE_IDENT_WAN'),
            (27, 'RULE_LAN2WAN_IPSEC'),
            (28, 'RULE_IPSEC_ESP'),
            (29, 'RULE_LAN2WAN_PPTP'),
            (30, 'RULE_LAN2WAN_L2TP'),
            (31, 'RULE_NAT_REDIRECTION'),
          ])
            _rule('p.$i.', enable: false, description: d),
        ])),
      );

      for (final s in FirewallSwitch.values) {
        expect(context.controls(s), isTrue, reason: '$s');
      }
    });

    // The table behind `controls` and the one inside buildSetPayload are the
    // same fact written twice; this keeps them from drifting apart.
    test('every switch a context controls produces a write', () {
      final all = FirewallRuleContext.fromMap({
        for (final key in FirewallSwitch.values.expand(debugRuleKeysOf))
          key: _rule('p.$key.', enable: false, description: ''),
      });
      const off = FirewallUIModel(
        isIPv4FirewallEnabled: false,
        isIPv6FirewallEnabled: false,
        blockIPSec: false,
        blockPPTP: false,
        blockL2TP: false,
        blockAnonymousRequests: false,
        blockMulticast: false,
        blockIDENT: false,
        blockNATRedirection: false,
      );
      const on = FirewallUIModel(
        isIPv4FirewallEnabled: true,
        isIPv6FirewallEnabled: true,
        blockIPSec: true,
        blockPPTP: true,
        blockL2TP: true,
        blockAnonymousRequests: true,
        blockMulticast: true,
        blockIDENT: true,
        blockNATRedirection: true,
      );

      final written = service
          .buildSetPayload(original: off, pending: on, rules: all.debugRuleMap)
          .map((u) => u.instancePath)
          .toSet();

      expect(
        written,
        {
          for (final key in FirewallSwitch.values.expand(debugRuleKeysOf))
            'p.$key.',
        },
      );
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

    // FW 2.0.2 shipped none of the named rules, so a toggle had nothing to
    // write: the save sent nothing and still reported success (#1611).
    test(
        'a changed toggle whose rule is absent fails instead of saving nothing',
        () async {
      final context = FirewallRuleContext.fromMap({
        'pptp': _rule('p.23.', enable: false, description: 'RULE_LAN2WAN_PPTP'),
      });

      await expectLater(
        service.save(
          original: FirewallUIModel(blockIDENT: false),
          pending: FirewallUIModel(blockIDENT: true),
          context: context,
        ),
        throwsA(isA<ResourceNotFoundError>()),
      );
      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
    });

    test('changed toggles call updateMany and return count', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

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
