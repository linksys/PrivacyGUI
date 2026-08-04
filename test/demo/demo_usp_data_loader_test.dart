/// Characterization tests for [DemoUspDataLoader] — the shared TR-181 data
/// engine behind demo mode.
///
/// This loader is the mutable in-memory store that both the current
/// `DemoUspClient` (subclass) and the future `DemoUspTransport` read/write. It
/// is deliberately pinned BEFORE the P3/P4 transport migration: the migration
/// moves demo from a `UspClient` subclass down to a `UspTransport` behind the
/// real `UspClient`, but it does NOT change this engine. These tests staying
/// green after P3/P4 proves the data layer was not disturbed by the migration.
///
/// Only the pure map operations (resolve / setValue / nextInstanceId /
/// removeByPrefix) are exercised — `load()` reads a rootBundle asset and is not
/// part of the engine's query/mutation contract.
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/demo/usp/demo_usp_data_loader.dart';

void main() {
  final loader = DemoUspDataLoader.instance;

  setUp(() {
    // The loader is a singleton with a mutable store and no reset(); clear it
    // between tests. removeByPrefix('') matches every key (startsWith('') is
    // always true), giving a clean slate.
    loader.removeByPrefix('');
    // Seed a small, representative TR-181 slice.
    loader.setValue('Device.DeviceInfo.Manufacturer', 'Linksys');
    loader.setValue('Device.WiFi.Radio.1.Enable', 'true');
    loader.setValue('Device.WiFi.Radio.2.Enable', 'false');
    loader.setValue('Device.WiFi.Radio.1.Channel', '36');
    loader.setValue('Device.Hosts.Host.1.HostName', 'laptop');
    loader.setValue('Device.Hosts.Host.2.HostName', 'phone');
    loader.setValue('Device.NAT.PortMapping.1.Description', 'Web');
    loader.setValue('Device.NAT.PortMapping.2.Description', 'SSH');
  });

  group('resolve — exact', () {
    test('returns the value for an exact path', () {
      final r = loader.resolve(['Device.DeviceInfo.Manufacturer']);
      expect(r, {'Device.DeviceInfo.Manufacturer': 'Linksys'});
    });

    test('omits a missing exact path (no null entry at loader level)', () {
      final r = loader.resolve(['Device.DeviceInfo.DoesNotExist']);
      expect(r, isEmpty);
    });
  });

  group('resolve — wildcard', () {
    test('expands a single embedded wildcard to all matching instances', () {
      final r = loader.resolve(['Device.WiFi.Radio.*.Enable']);
      expect(r, {
        'Device.WiFi.Radio.1.Enable': 'true',
        'Device.WiFi.Radio.2.Enable': 'false',
      });
    });

    test('wildcard is anchored — does not match deeper/other suffixes', () {
      final r = loader.resolve(['Device.WiFi.Radio.*.Enable']);
      expect(r.keys, isNot(contains('Device.WiFi.Radio.1.Channel')));
    });
  });

  group('resolve — prefix', () {
    test('expands a trailing-dot prefix to all children', () {
      final r = loader.resolve(['Device.Hosts.Host.']);
      expect(r, {
        'Device.Hosts.Host.1.HostName': 'laptop',
        'Device.Hosts.Host.2.HostName': 'phone',
      });
    });
  });

  group('setValue — read-after-write', () {
    test('a written value is visible on the next resolve', () {
      loader.setValue('Device.WiFi.Radio.1.Channel', '149');
      final r = loader.resolve(['Device.WiFi.Radio.1.Channel']);
      expect(r['Device.WiFi.Radio.1.Channel'], '149');
    });

    test('setValue creates a previously absent path', () {
      loader.setValue('Device.WiFi.SSID.1.SSID', 'DemoNet');
      final r = loader.resolve(['Device.WiFi.SSID.1.SSID']);
      expect(r['Device.WiFi.SSID.1.SSID'], 'DemoNet');
    });
  });

  group('nextInstanceId', () {
    test('returns highest existing id + 1', () {
      expect(loader.nextInstanceId('Device.NAT.PortMapping.'), 3);
    });

    test('returns 1 for an empty table', () {
      expect(loader.nextInstanceId('Device.Firewall.Rule.'), 1);
    });

    test('accepts an object path without the trailing dot', () {
      expect(loader.nextInstanceId('Device.NAT.PortMapping'), 3);
    });
  });

  group('removeByPrefix', () {
    test('removes all descendants of the prefix', () {
      loader.removeByPrefix('Device.Hosts.Host.1.');
      final r = loader.resolve(['Device.Hosts.Host.']);
      expect(r, {'Device.Hosts.Host.2.HostName': 'phone'});
    });

    test('removing one instance does not affect siblings or others', () {
      loader.removeByPrefix('Device.NAT.PortMapping.1.');
      expect(loader.resolve(['Device.NAT.PortMapping.']),
          {'Device.NAT.PortMapping.2.Description': 'SSH'});
      // Unrelated table untouched.
      expect(loader.resolve(['Device.DeviceInfo.Manufacturer']),
          {'Device.DeviceInfo.Manufacturer': 'Linksys'});
    });
  });
}
