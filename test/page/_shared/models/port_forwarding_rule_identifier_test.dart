import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';

PortForwardingRuleUIModel _pfRule({
  String? instancePath,
  String description = 'Web Server',
}) {
  return PortForwardingRuleUIModel(
    instancePath: instancePath,
    description: description,
    externalPort: 8080,
    internalPort: 80,
    internalClient: '192.168.1.100',
    protocol: 'TCP',
    enabled: true,
  );
}

PortTriggeringRuleUIModel _triggerRule({
  String? instancePath,
  String description = 'Game Trigger',
}) {
  return PortTriggeringRuleUIModel(
    instancePath: instancePath,
    enabled: true,
    description: description,
    triggerPort: 21,
    triggerProtocol: 'TCP',
  );
}

void main() {
  group('ruleIdentifierKey', () {
    test('slugifies a normal description', () {
      expect(ruleIdentifierKey('Web Server', null), 'web-server');
    });

    test('lowercases and collapses non-alphanumeric runs into single dashes',
        () {
      expect(ruleIdentifierKey('  My   Cool_Rule!! ', null), 'my-cool-rule');
    });

    test('trims leading/trailing dashes produced by symbols', () {
      expect(ruleIdentifierKey('***HTTP***', null), 'http');
    });

    test(
        'falls back to the trailing instance number on a DOT-TERMINATED path '
        '(the shape production actually emits)', () {
      // port_forwarding.g.dart:89 builds `final p = '$basePath$id.'` and passes
      // it verbatim (:133) — so the real input carries a trailing '.'.
      expect(ruleIdentifierKey('', 'Device.NAT.PortMapping.2.'), '2');
    });

    test('still tolerates a bare (non-dot-terminated) instance number', () {
      expect(ruleIdentifierKey('', 'Device.NAT.PortMapping.2'), '2');
    });

    test('falls back to the instance number when description is all symbols',
        () {
      expect(ruleIdentifierKey('---', 'Device.NAT.PortTrigger.7.'), '7');
    });

    test('falls back to "unnamed" when both description and path are unusable',
        () {
      expect(ruleIdentifierKey('', null), 'unnamed');
      expect(ruleIdentifierKey('   ', 'no-trailing-number'), 'unnamed');
      // Degenerate dot-terminated paths (no digit before the tail) stay unnamed.
      expect(ruleIdentifierKey('', 'Device.NAT.PortMapping.'), 'unnamed');
      expect(ruleIdentifierKey('', 'Device.NAT.PortMapping.2..'), 'unnamed');
    });
  });

  group('PortForwardingRuleUIModel.identifierKey', () {
    test('derives from description', () {
      expect(_pfRule(description: 'Web Server').identifierKey, 'web-server');
    });

    test('uses instance number when unnamed (dot-terminated path)', () {
      expect(
        _pfRule(description: '', instancePath: 'Device.NAT.PortMapping.3.')
            .identifierKey,
        '3',
      );
    });
  });

  group('PortTriggeringRuleUIModel.identifierKey', () {
    test('derives from description', () {
      expect(_triggerRule(description: 'Game Trigger').identifierKey,
          'game-trigger');
    });

    test('uses instance number when unnamed (dot-terminated path)', () {
      expect(
        _triggerRule(description: '', instancePath: 'Device.NAT.PortTrigger.5.')
            .identifierKey,
        '5',
      );
    });
  });
}
