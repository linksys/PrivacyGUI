import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspPath', () {
    group('parse', () {
      test('should parse an empty string as an empty path', () {
        final path = UspPath.parse('');
        expect(path.segments, isEmpty);
        expect(path.fullPath, '');
        expect(path.hasWildcard, isFalse);
        expect(path.aliasFilter, isEmpty);
      });

      test('should parse a root path (e.g., "Device.") correctly', () {
        final path = UspPath.parse('Device.');
        expect(path.segments, ['Device']);
        expect(path.fullPath, 'Device');
        expect(path.hasWildcard, isFalse);
        expect(path.aliasFilter, isEmpty);
      });

      test('should parse a simple path correctly', () {
        final path = UspPath.parse('Device.DeviceInfo.Manufacturer');
        expect(path.segments, ['Device', 'DeviceInfo', 'Manufacturer']);
        expect(path.fullPath, 'Device.DeviceInfo.Manufacturer');
        expect(path.hasWildcard, isFalse);
        expect(path.aliasFilter, isEmpty);
      });

      test('should parse path with multiple wildcards', () {
        final path = UspPath.parse('Device.WiFi.*.Radio.*.Status');
        expect(path.segments, ['Device', 'WiFi', '*', 'Radio', '*', 'Status']);
        expect(path.fullPath, 'Device.WiFi.*.Radio.*.Status');
        expect(path.hasWildcard, isTrue);
        expect(path.aliasFilter, isEmpty);
      });

      test('should parse path with alias filter and wildcard', () {
        final path = UspPath.parse(
          'Device.WiFi.SSID.[Alias=="Guest"].Radio.*.Enable',
        );
        expect(path.segments, [
          'Device',
          'WiFi',
          'SSID',
          'Radio',
          '*',
          'Enable',
        ]);
        expect(path.fullPath, 'Device.WiFi.SSID.Radio.*.Enable');
        expect(path.hasWildcard, isTrue);
        expect(path.aliasFilter, {'Alias': 'Guest'});
      });

      test(
        'should handle paths with empty segments correctly (e.g., "Device..Info")',
        () {
          final path = UspPath.parse('Device..Info');
          expect(path.segments, ['Device', 'Info']);
          expect(path.fullPath, 'Device.Info');
        },
      );

      test('should parse path with quotes in alias filter value', () {
        final path = UspPath.parse(
          'Device.Hosts.Host.[HostName=="MyHost"].IPAddress',
        );
        expect(path.aliasFilter, {'HostName': 'MyHost'});
      });
    });

    group('fullPath', () {
      test('should return the correct full path string', () {
        final path = UspPath.parse('Device.LAN.Host.1.IPAddress');
        expect(path.fullPath, 'Device.LAN.Host.1.IPAddress');
      });

      test('should return empty string for empty path', () {
        final path = UspPath.parse('');
        expect(path.fullPath, '');
      });
    });

    group('parentPath', () {
      test('should return the parent path for a multi-segment path', () {
        final path = UspPath.parse('Device.LAN.Host.1.IPAddress');
        final parent = path.parent;
        expect(parent?.fullPath, 'Device.LAN.Host.1');
      });

      test('should return empty path for a single-segment path', () {
        final path = UspPath.parse('Device');
        final parent = path.parent;
        expect(parent?.fullPath, '');
      });

      test('should return null when getting parent of an empty path', () {
        final path = UspPath.parse('');
        expect(path.parent, null);
      });
    });

    group('equality', () {
      test(
        'should be equal if segments, wildcard, and aliasFilter are identical',
        () {
          final path1 = UspPath.parse('Device.WiFi.Radio.1.Status');
          final path2 = UspPath.parse('Device.WiFi.Radio.1.Status');
          expect(path1 == path2, isTrue);
        },
      );

      test('should be equal if alias filter is identical', () {
        final path1 = UspPath.parse('Device.SSID.[Alias=="Guest"]');
        final path2 = UspPath.parse('Device.SSID.[Alias=="Guest"]');
        expect(path1 == path2, isTrue);
      });

      test('should be unequal if segments are different', () {
        final path1 = UspPath.parse('Device.WiFi.Radio.1.Status');
        final path2 = UspPath.parse('Device.WiFi.Radio.2.Status');
        expect(path1 == path2, isFalse);
      });

      test('should be unequal if wildcard status is different', () {
        final path1 = UspPath.parse('Device.WiFi.Radio.*.Status');
        final path2 = UspPath.parse('Device.WiFi.Radio.1.Status');
        expect(path1 == path2, isFalse);
      });

      test('should be unequal if alias filter is different', () {
        final path1 = UspPath.parse('Device.SSID.[Alias=="Guest"]');
        final path2 = UspPath.parse('Device.SSID.[Alias=="Admin"]');
        expect(path1 == path2, isFalse);
      });
    });

    group('hashCode', () {
      test('should be consistent for equal objects', () {
        final path1 = UspPath.parse('Device.Info.Status');
        final path2 = UspPath.parse('Device.Info.Status');
        expect(path1.hashCode, path2.hashCode);
      });

      test('should be different for unequal objects', () {
        final path1 = UspPath.parse('Device.Info.Status1');
        final path2 = UspPath.parse('Device.Info.Status2');
        expect(path1.hashCode == path2.hashCode, isFalse);
      });
    });

    group('toString', () {
      test('should return a correct string representation', () {
        final path = UspPath.parse('Device.LAN.Host.1.IPAddress');
        expect(path.toString(), 'UspPath(Device.LAN.Host.1.IPAddress)');
      });

      test('should return UspPath() for empty path', () {
        final path = UspPath.parse('');
        expect(path.toString(), 'UspPath()');
      });
    });

    group('serialization', () {
      test('should serialize and deserialize UspPath with aliasFilter', () {
        final path = UspPath.parse(
          'Device.WiFi.SSID.[Alias=="Guest"].Radio.*.Enable',
        );
        final json = path.toJson();

        expect(json['aliasFilter'], {'Alias': 'Guest'});
        expect(json['segments'], [
          'Device',
          'WiFi',
          'SSID',
          'Radio',
          '*',
          'Enable',
        ]);
        expect(json['hasWildcard'], isTrue);

        final deserializedPath = UspPath.fromJson(json);
        expect(deserializedPath, path);
      });
    });
  });
}
