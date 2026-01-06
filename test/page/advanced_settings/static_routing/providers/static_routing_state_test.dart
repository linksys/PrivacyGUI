import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_route_entry_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';

void main() {
  group('StaticRouteEntryUI - Model Tests', () {
    test('creates instance with required fields', () {
      // Act
      final entry = StaticRouteEntryUIModel(
        name: 'Route 1',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Assert
      expect(entry.name, 'Route 1');
      expect(entry.destinationIP, '10.0.0.0');
      expect(entry.subnetMask, '255.255.255.0');
      expect(entry.gateway, '192.168.1.1');
    });

    test('copyWith creates new instance with overrides', () {
      // Arrange
      final original = StaticRouteEntryUIModel(
        name: 'Original',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final copied = original.copyWith(name: 'Modified');

      // Assert
      expect(copied.name, 'Modified');
      expect(copied.destinationIP, '10.0.0.0');
      expect(original.name, 'Original');
    });

    test('equality comparison works correctly', () {
      // Arrange
      final entry1 = StaticRouteEntryUIModel(
        name: 'Route 1',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      final entry2 = StaticRouteEntryUIModel(
        name: 'Route 1',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      final entry3 = StaticRouteEntryUIModel(
        name: 'Route 2',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Assert
      expect(entry1, entry2);
      expect(entry1, isNot(entry3));
    });

    test('toMap returns correct map representation', () {
      // Arrange
      final entry = StaticRouteEntryUIModel(
        name: 'Route 1',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final map = entry.toMap();

      // Assert
      expect(map['name'], 'Route 1');
      expect(map['destinationIP'], '10.0.0.0');
      expect(map['subnetMask'], '255.255.255.0');
      expect(map['gateway'], '192.168.1.1');
    });

    test('fromMap constructs instance from map', () {
      // Arrange
      final map = {
        'name': 'Route 1',
        'destinationIP': '10.0.0.0',
        'subnetMask': '255.255.255.0',
        'gateway': '192.168.1.1',
      };

      // Act
      final entry = StaticRouteEntryUIModel.fromMap(map);

      // Assert
      expect(entry.name, 'Route 1');
      expect(entry.destinationIP, '10.0.0.0');
      expect(entry.subnetMask, '255.255.255.0');
      expect(entry.gateway, '192.168.1.1');
    });

    test('toJson and fromJson round-trip preserves data', () {
      // Arrange
      final original = StaticRouteEntryUIModel(
        name: 'Route 1',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final json = original.toJson();
      final restored = StaticRouteEntryUIModel.fromJson(json);

      // Assert
      expect(restored, original);
      expect(restored.name, 'Route 1');
      expect(restored.destinationIP, '10.0.0.0');
    });

    test('fromMap handles missing fields with defaults', () {
      // Arrange
      final map = <String, dynamic>{};

      // Act
      final entry = StaticRouteEntryUIModel.fromMap(map);

      // Assert
      expect(entry.name, '');
      expect(entry.destinationIP, '');
      expect(entry.subnetMask, '');
      expect(entry.gateway, '');
    });
  });

  group('StaticRoutingUISettings - Model Tests', () {
    test('creates instance with fields', () {
      // Act
      final settings = StaticRoutingSettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: const [],
      );

      // Assert
      expect(settings.isNATEnabled, true);
      expect(settings.isDynamicRoutingEnabled, false);
      expect(settings.entries, isEmpty);
    });

    test('copyWith creates new instance with overrides', () {
      // Arrange
      final original = StaticRoutingSettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: const [],
      );

      // Act
      final copied = original.copyWith(isDynamicRoutingEnabled: true);

      // Assert
      expect(copied.isNATEnabled, true);
      expect(copied.isDynamicRoutingEnabled, true);
      expect(original.isDynamicRoutingEnabled, false);
    });

    test('equality comparison works correctly', () {
      // Arrange
      final settings1 = StaticRoutingSettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: const [],
      );
      final settings2 = StaticRoutingSettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: const [],
      );
      final settings3 = StaticRoutingSettings(
        isNATEnabled: false,
        isDynamicRoutingEnabled: false,
        entries: const [],
      );

      // Assert
      expect(settings1, settings2);
      expect(settings1, isNot(settings3));
    });

    test('toMap returns correct map representation', () {
      // Arrange
      final entry = StaticRouteEntryUIModel(
        name: 'Route 1',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      final settings = StaticRoutingSettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: [entry],
      );

      // Act
      final map = settings.toMap();

      // Assert
      expect(map['isNATEnabled'], true);
      expect(map['isDynamicRoutingEnabled'], false);
      expect(map['entries'], isNotEmpty);
      expect((map['entries'] as List).length, 1);
    });

    test('fromMap constructs instance from map', () {
      // Arrange
      final map = {
        'isNATEnabled': true,
        'isDynamicRoutingEnabled': false,
        'entries': [],
      };

      // Act
      final settings = StaticRoutingSettings.fromMap(map);

      // Assert
      expect(settings.isNATEnabled, true);
      expect(settings.isDynamicRoutingEnabled, false);
      expect(settings.entries, isEmpty);
    });

    test('toJson and fromJson round-trip preserves data', () {
      // Arrange
      final original = StaticRoutingSettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: const [],
      );

      // Act
      final json = original.toJson();
      final restored = StaticRoutingSettings.fromJson(json);

      // Assert
      expect(restored, original);
      expect(restored.isNATEnabled, true);
      expect(restored.isDynamicRoutingEnabled, false);
    });

    test('toJson and fromJson with entries round-trip preserves data', () {
      // Arrange
      final entry = StaticRouteEntryUIModel(
        name: 'Route 1',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );
      final original = StaticRoutingSettings(
        isNATEnabled: true,
        isDynamicRoutingEnabled: false,
        entries: [entry],
      );

      // Act
      final json = original.toJson();
      final restored = StaticRoutingSettings.fromJson(json);

      // Assert
      expect(restored, original);
      expect(restored.entries.length, 1);
      expect(restored.entries.first.name, 'Route 1');
    });

    test('fromMap handles missing entries with default empty list', () {
      // Arrange
      final map = {
        'isNATEnabled': true,
        'isDynamicRoutingEnabled': false,
      };

      // Act
      final settings = StaticRoutingSettings.fromMap(map);

      // Assert
      expect(settings.entries, isEmpty);
    });
  });

  group('StaticRoutingStatus - Model Tests', () {
    test('creates instance with fields', () {
      // Act
      final status = StaticRoutingStatus(
        maxStaticRouteEntries: 10,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      // Assert
      expect(status.maxStaticRouteEntries, 10);
      expect(status.routerIp, '192.168.1.1');
      expect(status.subnetMask, '255.255.255.0');
    });

    test('copyWith creates new instance with overrides', () {
      // Arrange
      final original = StaticRoutingStatus(
        maxStaticRouteEntries: 10,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      // Act
      final copied = original.copyWith(maxStaticRouteEntries: 20);

      // Assert
      expect(copied.maxStaticRouteEntries, 20);
      expect(copied.routerIp, '192.168.1.1');
      expect(original.maxStaticRouteEntries, 10);
    });

    test('toJson and fromJson round-trip preserves data', () {
      // Arrange
      final original = StaticRoutingStatus(
        maxStaticRouteEntries: 10,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      // Act
      final json = original.toJson();
      final restored = StaticRoutingStatus.fromJson(json);

      // Assert
      expect(restored, original);
      expect(restored.maxStaticRouteEntries, 10);
      expect(restored.routerIp, '192.168.1.1');
    });
  });

  group('StaticRoutingState - Model Tests', () {
    test('creates empty state correctly', () {
      // Act
      final state = StaticRoutingState.empty();

      // Assert
      expect(state.settings.original.isNATEnabled, false);
      expect(state.settings.current.isNATEnabled, false);
      expect(state.settings.original.entries, isEmpty);
      expect(state.status.maxStaticRouteEntries, 0);
    });

    test('copyWith creates new state instance', () {
      // Arrange
      final original = StaticRoutingState.empty();
      final newStatus = StaticRoutingStatus(
        maxStaticRouteEntries: 20,
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );

      // Act
      final copied = original.copyWith(status: newStatus);

      // Assert
      expect(copied.status.maxStaticRouteEntries, 20);
      expect(original.status.maxStaticRouteEntries, 0);
    });

    test('toJson and fromJson round-trip preserves state', () {
      // Arrange
      final original = StaticRoutingState.empty();

      // Act
      final json = original.toJson();
      final restored = StaticRoutingState.fromJson(json);

      // Assert
      expect(restored.settings.original.isNATEnabled,
          original.settings.original.isNATEnabled);
      expect(restored.status.maxStaticRouteEntries,
          original.status.maxStaticRouteEntries);
    });
  });
}
