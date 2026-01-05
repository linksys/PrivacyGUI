import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_route_entry_ui_model.dart';

void main() {
  group('StaticRouteEntryUIModel', () {
    test('creates instance with required fields', () {
      const model = StaticRouteEntryUIModel(
        name: 'Home Network',
        destinationIP: '192.168.2.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      expect(model.name, 'Home Network');
      expect(model.destinationIP, '192.168.2.0');
      expect(model.subnetMask, '255.255.255.0');
      expect(model.gateway, '192.168.1.1');
      expect(model.interface, 'LAN');
    });

    test('copyWith updates specified fields', () {
      const original = StaticRouteEntryUIModel(
        name: 'Route1',
        destinationIP: '10.0.0.0',
        subnetMask: '255.0.0.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      final copied = original.copyWith(name: 'Updated', interface: 'Internet');
      expect(copied.name, 'Updated');
      expect(copied.interface, 'Internet');
      expect(copied.destinationIP, '10.0.0.0');
    });

    test('toMap converts to map correctly', () {
      const model = StaticRouteEntryUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        subnetMask: '255.0.0.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      final map = model.toMap();
      expect(map['name'], 'Test');
      expect(map['destinationIP'], '10.0.0.0');
      expect(map['interface'], 'LAN');
    });

    test('fromMap creates instance from map', () {
      final map = {
        'name': 'Test',
        'destinationIP': '10.0.0.0',
        'subnetMask': '255.0.0.0',
        'gateway': '192.168.1.1',
        'interface': 'Internet',
      };
      final model = StaticRouteEntryUIModel.fromMap(map);
      expect(model.name, 'Test');
      expect(model.interface, 'Internet');
    });

    test('fromMap uses defaults for missing values', () {
      final model = StaticRouteEntryUIModel.fromMap(<String, dynamic>{});
      expect(model.name, '');
      expect(model.interface, 'LAN');
    });

    test('toJson/fromJson round-trip works', () {
      const original = StaticRouteEntryUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        subnetMask: '255.0.0.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      final json = original.toJson();
      final restored = StaticRouteEntryUIModel.fromJson(json);
      expect(restored, original);
    });

    test('equality comparison works', () {
      const m1 = StaticRouteEntryUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        subnetMask: '255.0.0.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      const m2 = StaticRouteEntryUIModel(
        name: 'Test',
        destinationIP: '10.0.0.0',
        subnetMask: '255.0.0.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      expect(m1, m2);
    });
  });

  group('StaticRoutingUISettings', () {
    test('creates instance with required fields', () {
      const settings = StaticRoutingUISettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: [],
      );
      expect(settings.isNATEnabled, true);
      expect(settings.isDynamicRoutingEnabled, false);
      expect(settings.entries, isEmpty);
    });

    test('creates instance with entries', () {
      const entry = StaticRouteEntryUIModel(
        name: 'Route1',
        destinationIP: '10.0.0.0',
        subnetMask: '255.0.0.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      const settings = StaticRoutingUISettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: [entry],
      );
      expect(settings.entries, hasLength(1));
    });

    test('copyWith updates specified fields', () {
      const original = StaticRoutingUISettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: [],
      );
      final copied = original.copyWith(isDynamicRoutingEnabled: true);
      expect(copied.isDynamicRoutingEnabled, true);
      expect(copied.isNATEnabled, true);
    });

    test('toMap/fromMap serialization works', () {
      const entry = StaticRouteEntryUIModel(
        name: 'Route1',
        destinationIP: '10.0.0.0',
        subnetMask: '255.0.0.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      const original = StaticRoutingUISettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: [entry],
      );
      final map = original.toMap();
      final restored = StaticRoutingUISettings.fromMap(map);
      expect(restored.entries, hasLength(1));
      expect(restored.isNATEnabled, true);
    });

    test('toJson/fromJson round-trip works', () {
      const settings = StaticRoutingUISettings(
        isNATEnabled: false,
        isDynamicRoutingEnabled: true,
        entries: [],
      );
      final json = settings.toJson();
      final restored = StaticRoutingUISettings.fromJson(json);
      expect(restored, settings);
    });

    test('equality comparison works', () {
      const s1 = StaticRoutingUISettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: [],
      );
      const s2 = StaticRoutingUISettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: [],
      );
      expect(s1, s2);
    });
  });
}
