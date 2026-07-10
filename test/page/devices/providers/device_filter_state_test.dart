import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';

void main() {
  group('DeviceFilterConfig', () {
    test('default config has isActive false', () {
      const config = DeviceFilterConfig();

      expect(config.isActive, isFalse);
      expect(config.searchQuery, isEmpty);
      expect(config.status, DeviceStatusFilter.all);
      expect(config.connections, isEmpty);
      expect(config.signals, isEmpty);
      expect(config.includeUnknownSignal, isFalse);
      expect(config.nodeIds, isEmpty);
      expect(config.ssidNames, isEmpty);
      expect(config.bands, isEmpty);
    });

    test('isActive true when status is not all', () {
      const config = DeviceFilterConfig(status: DeviceStatusFilter.online);
      expect(config.isActive, isTrue);
    });

    test('isActive true when connections is set', () {
      const config = DeviceFilterConfig(connections: {ConnectionType.wifi});
      expect(config.isActive, isTrue);
    });

    test('isActive true when signals is set', () {
      const config = DeviceFilterConfig(signals: {DeviceSignalLevel.excellent});
      expect(config.isActive, isTrue);
    });

    test('isActive true when includeUnknownSignal is true', () {
      const config = DeviceFilterConfig(includeUnknownSignal: true);
      expect(config.isActive, isTrue);
    });

    test('isActive true when nodeIds is set', () {
      const config = DeviceFilterConfig(nodeIds: {'node1'});
      expect(config.isActive, isTrue);
    });

    test('isActive true when ssidNames is set', () {
      const config = DeviceFilterConfig(ssidNames: {'Home'});
      expect(config.isActive, isTrue);
    });

    test('isActive true when bands is set', () {
      const config = DeviceFilterConfig(bands: {'5GHz'});
      expect(config.isActive, isTrue);
    });

    test('isActive true when searchQuery is non-empty', () {
      const config = DeviceFilterConfig(searchQuery: 'iphone');
      expect(config.isActive, isTrue);
    });

    test('copyWith updates fields correctly', () {
      const config = DeviceFilterConfig();
      final updated = config.copyWith(
        searchQuery: 'test',
        status: DeviceStatusFilter.offline,
        connections: const {ConnectionType.wifi},
        signals: const {DeviceSignalLevel.good},
        includeUnknownSignal: true,
        nodeIds: () => const {'node1'},
        ssidNames: () => const {'Guest'},
        bands: () => const {'2.4GHz'},
      );

      expect(updated.searchQuery, 'test');
      expect(updated.status, DeviceStatusFilter.offline);
      expect(updated.connections, const {ConnectionType.wifi});
      expect(updated.signals, const {DeviceSignalLevel.good});
      expect(updated.includeUnknownSignal, isTrue);
      expect(updated.nodeIds, const {'node1'});
      expect(updated.ssidNames, const {'Guest'});
      expect(updated.bands, const {'2.4GHz'});
    });

    test('copyWith Set fields can be cleared with empty-set-returning closure',
        () {
      const config = DeviceFilterConfig(
        nodeIds: {'node1'},
        ssidNames: {'Home'},
        bands: {'5GHz'},
      );
      final cleared = config.copyWith(
        nodeIds: () => const {},
        ssidNames: () => const {},
        bands: () => const {},
      );

      expect(cleared.nodeIds, isEmpty);
      expect(cleared.ssidNames, isEmpty);
      expect(cleared.bands, isEmpty);
    });

    test('copyWith preserves unchanged fields', () {
      const config = DeviceFilterConfig(
        searchQuery: 'phone',
        status: DeviceStatusFilter.online,
        nodeIds: {'node1'},
      );
      final updated = config.copyWith(searchQuery: 'laptop');

      expect(updated.searchQuery, 'laptop');
      expect(updated.status, DeviceStatusFilter.online);
      expect(updated.nodeIds, const {'node1'});
    });

    test('equatable compares all fields', () {
      const a = DeviceFilterConfig(searchQuery: 'test', nodeIds: {'n1'});
      const b = DeviceFilterConfig(searchQuery: 'test', nodeIds: {'n1'});
      const c = DeviceFilterConfig(searchQuery: 'test', nodeIds: {'n2'});

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hasWifiOnlyFilter returns true when any WiFi-specific filter is set',
        () {
      expect(
        const DeviceFilterConfig(signals: {DeviceSignalLevel.excellent})
            .hasWifiOnlyFilter,
        isTrue,
      );
      expect(
        const DeviceFilterConfig(includeUnknownSignal: true).hasWifiOnlyFilter,
        isTrue,
      );
      expect(
        const DeviceFilterConfig(ssidNames: {'Home'}).hasWifiOnlyFilter,
        isTrue,
      );
      expect(
        const DeviceFilterConfig(bands: {'5GHz'}).hasWifiOnlyFilter,
        isTrue,
      );
      expect(
        const DeviceFilterConfig().hasWifiOnlyFilter,
        isFalse,
      );
    });

    test('isEthernetOnly returns true only for single wired selection', () {
      expect(
        const DeviceFilterConfig(connections: {ConnectionType.wired})
            .isEthernetOnly,
        isTrue,
      );
      expect(
        const DeviceFilterConfig(
                connections: {ConnectionType.wifi, ConnectionType.wired})
            .isEthernetOnly,
        isFalse,
      );
      expect(
        const DeviceFilterConfig(connections: {ConnectionType.wifi})
            .isEthernetOnly,
        isFalse,
      );
      expect(
        const DeviceFilterConfig().isEthernetOnly,
        isFalse,
      );
    });

    test('activeCount counts non-empty dimensions correctly', () {
      expect(const DeviceFilterConfig().activeCount, 0);
      expect(
        const DeviceFilterConfig(connections: {ConnectionType.wifi})
            .activeCount,
        1,
      );
      expect(
        const DeviceFilterConfig(
          connections: {ConnectionType.wifi},
          signals: {DeviceSignalLevel.excellent},
        ).activeCount,
        2,
      );
      expect(
        const DeviceFilterConfig(
          status: DeviceStatusFilter.online,
          connections: {ConnectionType.wifi},
          signals: {DeviceSignalLevel.excellent},
          nodeIds: {'node1'},
          ssidNames: {'Home'},
          bands: {'5GHz'},
        ).activeCount,
        6,
      );
    });

    test('activeCountExcludingStatus excludes status from count', () {
      expect(
        const DeviceFilterConfig(status: DeviceStatusFilter.online)
            .activeCountExcludingStatus,
        0,
      );
      expect(
        const DeviceFilterConfig(
          status: DeviceStatusFilter.online,
          connections: {ConnectionType.wifi},
        ).activeCountExcludingStatus,
        1,
      );
    });
  });

  group('DeviceFilterOptions', () {
    test('default options are empty', () {
      const options = DeviceFilterOptions();

      expect(options.nodes, isEmpty);
      expect(options.ssids, isEmpty);
      expect(options.bands, isEmpty);
      expect(options.hasUnknownSignalDevices, isFalse);
    });
  });
}
