import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';

void main() {
  group('DeviceFilterConfig', () {
    test('default config has isActive false', () {
      const config = DeviceFilterConfig();

      expect(config.isActive, isFalse);
      expect(config.searchQuery, isEmpty);
      expect(config.status, DeviceStatusFilter.all);
      expect(config.nodeId, isNull);
      expect(config.ssidName, isNull);
      expect(config.band, isNull);
    });

    test('isActive true when status is not all', () {
      const config = DeviceFilterConfig(status: DeviceStatusFilter.online);
      expect(config.isActive, isTrue);
    });

    test('isActive true when nodeId is set', () {
      const config = DeviceFilterConfig(nodeId: 'node1');
      expect(config.isActive, isTrue);
    });

    test('isActive true when ssidName is set', () {
      const config = DeviceFilterConfig(ssidName: 'Home');
      expect(config.isActive, isTrue);
    });

    test('isActive true when band is set', () {
      const config = DeviceFilterConfig(band: '5GHz');
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
        nodeId: () => 'node1',
        ssidName: () => 'Guest',
        band: () => '2.4GHz',
      );

      expect(updated.searchQuery, 'test');
      expect(updated.status, DeviceStatusFilter.offline);
      expect(updated.nodeId, 'node1');
      expect(updated.ssidName, 'Guest');
      expect(updated.band, '2.4GHz');
    });

    test('copyWith nullable fields can be cleared with null-returning closure',
        () {
      const config = DeviceFilterConfig(
        nodeId: 'node1',
        ssidName: 'Home',
        band: '5GHz',
      );
      final cleared = config.copyWith(
        nodeId: () => null,
        ssidName: () => null,
        band: () => null,
      );

      expect(cleared.nodeId, isNull);
      expect(cleared.ssidName, isNull);
      expect(cleared.band, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const config = DeviceFilterConfig(
        searchQuery: 'phone',
        status: DeviceStatusFilter.online,
        nodeId: 'node1',
      );
      final updated = config.copyWith(searchQuery: 'laptop');

      expect(updated.searchQuery, 'laptop');
      expect(updated.status, DeviceStatusFilter.online);
      expect(updated.nodeId, 'node1');
    });

    test('equatable compares all fields', () {
      const a = DeviceFilterConfig(searchQuery: 'test', nodeId: 'n1');
      const b = DeviceFilterConfig(searchQuery: 'test', nodeId: 'n1');
      const c = DeviceFilterConfig(searchQuery: 'test', nodeId: 'n2');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('DeviceFilterOptions', () {
    test('default options are empty', () {
      const options = DeviceFilterOptions();

      expect(options.nodes, isEmpty);
      expect(options.ssids, isEmpty);
      expect(options.bands, isEmpty);
    });
  });
}
