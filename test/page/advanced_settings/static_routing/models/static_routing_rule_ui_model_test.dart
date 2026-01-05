import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_routing_rule_ui_model.dart';

void main() {
  group('StaticRoutingRuleUIModel', () {
    test('creates instance with required fields', () {
      const model = StaticRoutingRuleUIModel(
        name: 'Test Route',
        destinationIP: '192.168.2.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      expect(model.name, 'Test Route');
      expect(model.destinationIP, '192.168.2.0');
      expect(model.networkPrefixLength, 24);
      expect(model.gateway, '192.168.1.1');
      expect(model.interface, 'LAN');
    });

    test('creates instance with null gateway', () {
      const model = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 8,
        gateway: null,
        interface: 'Internet',
      );
      expect(model.gateway, isNull);
    });

    test('copyWith updates specified fields', () {
      const original = StaticRoutingRuleUIModel(
        name: 'Route1',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 8,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      final copied =
          original.copyWith(name: 'Updated', networkPrefixLength: 16);
      expect(copied.name, 'Updated');
      expect(copied.networkPrefixLength, 16);
      expect(copied.destinationIP, '10.0.0.0');
    });

    test('toMap converts to map correctly', () {
      const model = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      final map = model.toMap();
      expect(map['name'], 'Test');
      expect(map['destinationIP'], '10.0.0.0');
      expect(map['networkPrefixLength'], 24);
      expect(map['gateway'], '192.168.1.1');
      expect(map['interface'], 'LAN');
    });

    test('fromMap creates instance from map', () {
      final map = {
        'name': 'Test',
        'destinationIP': '10.0.0.0',
        'networkPrefixLength': 16,
        'gateway': '192.168.1.1',
        'interface': 'Internet',
      };
      final model = StaticRoutingRuleUIModel.fromMap(map);
      expect(model.name, 'Test');
      expect(model.networkPrefixLength, 16);
      expect(model.interface, 'Internet');
    });

    test('fromMap uses defaults for missing values', () {
      final model = StaticRoutingRuleUIModel.fromMap(const <String, dynamic>{});
      expect(model.name, '');
      expect(model.networkPrefixLength, 24);
      expect(model.interface, 'LAN');
    });

    test('fromMap handles null gateway', () {
      final map = {
        'name': 'Test',
        'destinationIP': '10.0.0.0',
        'networkPrefixLength': 24,
        'gateway': null,
        'interface': 'LAN',
      };
      final model = StaticRoutingRuleUIModel.fromMap(map);
      expect(model.gateway, isNull);
    });

    test('toJson/fromJson round-trip works', () {
      const original = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      final json = original.toJson();
      final restored = StaticRoutingRuleUIModel.fromJson(json);
      expect(restored, original);
    });

    test('equality comparison works', () {
      const m1 = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      const m2 = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      expect(m1, m2);
    });

    test('distinguishes different models', () {
      const m1 = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      const m2 = StaticRoutingRuleUIModel(
        name: 'Test2',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      expect(m1, isNot(m2));
    });

    test('props returns correct list', () {
      const model = StaticRoutingRuleUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      expect(model.props, [
        model.name,
        model.destinationIP,
        model.networkPrefixLength,
        model.gateway,
        model.interface,
      ]);
    });
  });
}
