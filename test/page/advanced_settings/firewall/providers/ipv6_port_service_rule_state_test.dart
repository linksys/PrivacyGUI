import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';

import '../services/ipv6_port_service_list_service_test_data.dart';

void main() {
  group('IPv6PortServiceRuleUI', () {
    test('creates instance with required fields', () {
      // Arrange & Act
      final rule = IPv6PortServiceRuleUI(
        protocol: 'TCP',
        externalPort: 80,
        internalPort: 8080,
        internalIPAddress: '2001:db8::1',
        description: 'Web Server',
        enabled: true,
      );

      // Assert
      expect(rule.protocol, 'TCP');
      expect(rule.externalPort, 80);
      expect(rule.internalPort, 8080);
      expect(rule.internalIPAddress, '2001:db8::1');
      expect(rule.description, 'Web Server');
      expect(rule.enabled, true);
    });

    test('copyWith creates new instance with updated fields', () {
      // Arrange
      final original = IPv6PortServiceTestData.createUIRule();

      // Act
      final updated = original.copyWith(
        description: 'Updated Description',
        enabled: false,
      );

      // Assert
      expect(updated.description, 'Updated Description');
      expect(updated.enabled, false);
      // Unchanged fields
      expect(updated.protocol, original.protocol);
      expect(updated.externalPort, original.externalPort);
      expect(updated.internalPort, original.internalPort);
      expect(updated.internalIPAddress, original.internalIPAddress);
    });

    test('copyWith with no changes returns equivalent instance', () {
      // Arrange
      final original = IPv6PortServiceTestData.createUIRule();

      // Act
      final copy = original.copyWith();

      // Assert
      expect(copy, equals(original));
    });

    test('toMap serializes all fields correctly', () {
      // Arrange
      final rule = IPv6PortServiceTestData.createUIRule(
        protocol: 'UDP',
        externalPort: 7777,
        internalPort: 7777,
        internalIPAddress: '2001:db8::2',
        description: 'Game Server',
        enabled: false,
      );

      // Act
      final map = rule.toMap();

      // Assert
      expect(map['protocol'], 'UDP');
      expect(map['externalPort'], 7777);
      expect(map['internalPort'], 7777);
      expect(map['internalIPAddress'], '2001:db8::2');
      expect(map['description'], 'Game Server');
      expect(map['enabled'], false);
    });

    test('fromMap deserializes all fields correctly', () {
      // Arrange
      final map = {
        'protocol': 'Both',
        'externalPort': 27000,
        'internalPort': 27100,
        'internalIPAddress': '2001:db8::3',
        'description': 'Port Range',
        'enabled': true,
      };

      // Act
      final rule = IPv6PortServiceRuleUI.fromMap(map);

      // Assert
      expect(rule.protocol, 'Both');
      expect(rule.externalPort, 27000);
      expect(rule.internalPort, 27100);
      expect(rule.internalIPAddress, '2001:db8::3');
      expect(rule.description, 'Port Range');
      expect(rule.enabled, true);
    });

    test('round-trip serialization preserves all data', () {
      // Arrange
      final original = IPv6PortServiceTestData.createUIRule(
        protocol: 'TCP',
        externalPort: 443,
        internalPort: 8443,
        internalIPAddress: '2001:db8:abcd::1',
        description: 'HTTPS Proxy',
        enabled: true,
      );

      // Act
      final map = original.toMap();
      final deserialized = IPv6PortServiceRuleUI.fromMap(map);

      // Assert
      expect(deserialized, equals(original));
    });

    test('toJson produces valid JSON string', () {
      // Arrange
      final rule = IPv6PortServiceTestData.createUIRule();

      // Act
      final jsonString = rule.toJson();
      final decoded = json.decode(jsonString);

      // Assert
      expect(decoded, isA<Map>());
      expect(decoded['protocol'], rule.protocol);
      expect(decoded['description'], rule.description);
    });

    test('fromJson parses JSON string correctly', () {
      // Arrange
      final original = IPv6PortServiceTestData.createUIRule();
      final jsonString = original.toJson();

      // Act
      final parsed = IPv6PortServiceRuleUI.fromJson(jsonString);

      // Assert
      expect(parsed, equals(original));
    });

    test('equality compares all fields', () {
      // Arrange
      final rule1 = IPv6PortServiceTestData.createUIRule();
      final rule2 = IPv6PortServiceTestData.createUIRule();
      final rule3 = IPv6PortServiceTestData.createUIRule(description: 'Different');

      // Act & Assert
      expect(rule1, equals(rule2));
      expect(rule1, isNot(equals(rule3)));
    });

    test('props includes all fields for equality', () {
      // Arrange
      final rule = IPv6PortServiceTestData.createUIRule();

      // Act
      final props = rule.props;

      // Assert
      expect(props.length, 6);
      expect(props, contains(rule.protocol));
      expect(props, contains(rule.externalPort));
      expect(props, contains(rule.internalPort));
      expect(props, contains(rule.internalIPAddress));
      expect(props, contains(rule.description));
      expect(props, contains(rule.enabled));
    });

    test('handles different protocols correctly', () {
      // Arrange & Act
      final tcpRule = IPv6PortServiceTestData.createUIRule(protocol: 'TCP');
      final udpRule = IPv6PortServiceTestData.createUIRule(protocol: 'UDP');
      final bothRule = IPv6PortServiceTestData.createUIRule(protocol: 'Both');

      // Assert
      expect(tcpRule.protocol, 'TCP');
      expect(udpRule.protocol, 'UDP');
      expect(bothRule.protocol, 'Both');
    });

    test('handles port ranges correctly', () {
      // Arrange & Act
      final singlePort = IPv6PortServiceTestData.createUIRule(
        externalPort: 80,
        internalPort: 80,
      );
      final portRange = IPv6PortServiceTestData.createUIRule(
        externalPort: 27000,
        internalPort: 27100,
      );

      // Assert
      expect(singlePort.externalPort, singlePort.internalPort);
      expect(portRange.internalPort - portRange.externalPort, 100);
    });

    test('handles IPv6 addresses correctly', () {
      // Arrange
      final testAddresses = [
        '2001:db8::1',
        'fe80::1',
        '::1',
        '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
      ];

      // Act & Assert
      for (final address in testAddresses) {
        final rule = IPv6PortServiceTestData.createUIRule(
          internalIPAddress: address,
        );
        expect(rule.internalIPAddress, address);
      }
    });

    test('handles enabled/disabled states correctly', () {
      // Arrange & Act
      final enabledRule = IPv6PortServiceTestData.createUIRule(enabled: true);
      final disabledRule = IPv6PortServiceTestData.createUIRule(enabled: false);

      // Assert
      expect(enabledRule.enabled, true);
      expect(disabledRule.enabled, false);
    });
  });

  group('Ipv6PortServiceRuleState', () {
    test('creates instance with default empty values', () {
      // Arrange & Act
      const state = Ipv6PortServiceRuleState();

      // Assert
      expect(state.rules, isEmpty);
      expect(state.rule, isNull);
      expect(state.editIndex, isNull);
    });

    test('creates instance with provided values', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final rule = rules.first;

      // Act
      final state = Ipv6PortServiceRuleState(
        rules: rules,
        rule: rule,
        editIndex: 0,
      );

      // Assert
      expect(state.rules, equals(rules));
      expect(state.rule, equals(rule));
      expect(state.editIndex, 0);
    });

    test('copyWith updates rules field', () {
      // Arrange
      const original = Ipv6PortServiceRuleState();
      final newRules = IPv6PortServiceTestData.createUIRuleList();

      // Act
      final updated = original.copyWith(rules: newRules);

      // Assert
      expect(updated.rules, equals(newRules));
      expect(updated.rule, original.rule);
      expect(updated.editIndex, original.editIndex);
    });

    test('copyWith updates rule field with ValueGetter', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final state = Ipv6PortServiceRuleState(rules: rules);
      final newRule = rules.first;

      // Act
      final updated = state.copyWith(rule: () => newRule);

      // Assert
      expect(updated.rule, equals(newRule));
      expect(updated.rules, equals(rules));
    });

    test('copyWith can set rule to null using ValueGetter', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final state = Ipv6PortServiceRuleState(
        rules: rules,
        rule: rules.first,
      );

      // Act
      final updated = state.copyWith(rule: () => null);

      // Assert
      expect(updated.rule, isNull);
    });

    test('copyWith updates editIndex field with ValueGetter', () {
      // Arrange
      const original = Ipv6PortServiceRuleState();

      // Act
      final updated = original.copyWith(editIndex: () => 5);

      // Assert
      expect(updated.editIndex, 5);
    });

    test('copyWith can set editIndex to null using ValueGetter', () {
      // Arrange
      const original = Ipv6PortServiceRuleState(editIndex: 5);

      // Act
      final updated = original.copyWith(editIndex: () => null);

      // Assert
      expect(updated.editIndex, isNull);
    });

    test('toMap serializes all fields correctly', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final rule = rules.first;
      final state = Ipv6PortServiceRuleState(
        rules: rules,
        rule: rule,
        editIndex: 1,
      );

      // Act
      final map = state.toMap();

      // Assert
      expect(map['rules'], isA<List>());
      expect((map['rules'] as List).length, rules.length);
      expect(map['rule'], isA<Map>());
      expect(map['editIndex'], 1);
    });

    test('toMap handles null rule correctly', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final state = Ipv6PortServiceRuleState(rules: rules);

      // Act
      final map = state.toMap();

      // Assert
      expect(map['rule'], isNull);
    });

    test('toMap handles null editIndex correctly', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final state = Ipv6PortServiceRuleState(rules: rules);

      // Act
      final map = state.toMap();

      // Assert
      expect(map['editIndex'], isNull);
    });

    test('fromMap deserializes all fields correctly', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final map = {
        'rules': rules.map((r) => r.toMap()).toList(),
        'rule': rules.first.toMap(),
        'editIndex': 2,
      };

      // Act
      final state = Ipv6PortServiceRuleState.fromMap(map);

      // Assert
      expect(state.rules.length, rules.length);
      expect(state.rule, isNotNull);
      expect(state.editIndex, 2);
    });

    test('fromMap handles empty rules list', () {
      // Arrange
      final map = {
        'rules': [],
        'rule': null,
        'editIndex': null,
      };

      // Act
      final state = Ipv6PortServiceRuleState.fromMap(map);

      // Assert
      expect(state.rules, isEmpty);
      expect(state.rule, isNull);
      expect(state.editIndex, isNull);
    });

    test('fromMap handles missing rules field gracefully', () {
      // Arrange
      final map = <String, dynamic>{
        'rule': null,
        'editIndex': null,
      };

      // Act
      final state = Ipv6PortServiceRuleState.fromMap(map);

      // Assert
      expect(state.rules, isEmpty);
    });

    test('round-trip serialization preserves all data', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final original = Ipv6PortServiceRuleState(
        rules: rules,
        rule: rules[1],
        editIndex: 1,
      );

      // Act
      final map = original.toMap();
      final deserialized = Ipv6PortServiceRuleState.fromMap(map);

      // Assert
      expect(deserialized.rules.length, original.rules.length);
      expect(deserialized.rule, equals(original.rule));
      expect(deserialized.editIndex, original.editIndex);
    });

    test('toJson produces valid JSON string', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final state = Ipv6PortServiceRuleState(rules: rules);

      // Act
      final jsonString = state.toJson();
      final decoded = json.decode(jsonString);

      // Assert
      expect(decoded, isA<Map>());
      expect(decoded['rules'], isA<List>());
    });

    test('fromJson parses JSON string correctly', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final original = Ipv6PortServiceRuleState(rules: rules, editIndex: 0);
      final jsonString = original.toJson();

      // Act
      final parsed = Ipv6PortServiceRuleState.fromJson(jsonString);

      // Assert
      expect(parsed.rules.length, original.rules.length);
      expect(parsed.editIndex, original.editIndex);
    });

    test('equality compares all fields', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final state1 = Ipv6PortServiceRuleState(rules: rules, editIndex: 0);
      final state2 = Ipv6PortServiceRuleState(rules: rules, editIndex: 0);
      final state3 = Ipv6PortServiceRuleState(rules: rules, editIndex: 1);

      // Act & Assert
      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('props includes all fields for equality', () {
      // Arrange
      final rules = IPv6PortServiceTestData.createUIRuleList();
      final rule = rules.first;
      final state = Ipv6PortServiceRuleState(
        rules: rules,
        rule: rule,
        editIndex: 0,
      );

      // Act
      final props = state.props;

      // Assert
      expect(props.length, 3);
      expect(props, contains(state.rules));
      expect(props, contains(state.rule));
      expect(props, contains(state.editIndex));
    });

    test('toString returns readable representation', () {
      // Arrange
      final rules = [IPv6PortServiceTestData.createUIRule()];
      final state = Ipv6PortServiceRuleState(
        rules: rules,
        rule: rules.first,
        editIndex: 0,
      );

      // Act
      final string = state.toString();

      // Assert
      expect(string, contains('Ipv6PortServiceRuleState'));
      expect(string, contains('rules:'));
      expect(string, contains('rule:'));
      expect(string, contains('editIndex:'));
    });
  });
}
