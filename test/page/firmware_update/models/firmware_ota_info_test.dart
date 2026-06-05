import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_info.dart';

void main() {
  group('FirmwareOtaInfo', () {
    test('fromJson parses complete response correctly', () {
      final json = {
        'version': '1.0.10.25092307',
        'release_date': '2025-09-23T17:06:26Z',
        'download_url': 'http://download.linksys.com/updates/firmware.img',
        'checksum': '1022217387',
        'check_interval': 'daily',
        'check_time': '06:00:00Z',
      };

      final info = FirmwareOtaInfo.fromJson(json);

      expect(info.version, '1.0.10.25092307');
      expect(info.releaseDate, DateTime.utc(2025, 9, 23, 17, 6, 26));
      expect(
          info.downloadUrl, 'http://download.linksys.com/updates/firmware.img');
      expect(info.checksum, '1022217387');
      expect(info.checkInterval, 'daily');
      expect(info.checkTime, '06:00:00Z');
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final info = FirmwareOtaInfo.fromJson(json);

      expect(info.version, '');
      expect(info.downloadUrl, '');
      expect(info.checksum, '');
      expect(info.checkInterval, '');
      expect(info.checkTime, '');
    });

    test('fromJson handles null values', () {
      final json = {
        'version': null,
        'release_date': null,
        'download_url': null,
        'checksum': null,
        'check_interval': null,
        'check_time': null,
      };

      final info = FirmwareOtaInfo.fromJson(json);

      expect(info.version, '');
      expect(info.downloadUrl, '');
    });

    test('fromJson handles invalid date format with null', () {
      final json = {
        'version': '1.0.0',
        'release_date': 'not-a-date',
        'download_url': 'http://example.com/fw.img',
        'checksum': '123',
        'check_interval': 'daily',
        'check_time': '06:00:00Z',
      };

      final info = FirmwareOtaInfo.fromJson(json);

      expect(info.version, '1.0.0');
      expect(info.releaseDate, isNull);
    });

    test('fromJson handles missing release_date with null', () {
      final json = {
        'version': '1.0.0',
        'download_url': 'http://example.com/fw.img',
        'checksum': '123',
        'check_interval': 'daily',
        'check_time': '06:00:00Z',
      };

      final info = FirmwareOtaInfo.fromJson(json);

      expect(info.releaseDate, isNull);
    });

    test('equality works correctly', () {
      final info1 = FirmwareOtaInfo(
        version: '1.0.0',
        releaseDate: DateTime.utc(2025, 1, 1),
        downloadUrl: 'http://example.com/fw.img',
        checksum: '123',
        checkInterval: 'daily',
        checkTime: '06:00:00Z',
      );

      final info2 = FirmwareOtaInfo(
        version: '1.0.0',
        releaseDate: DateTime.utc(2025, 1, 1),
        downloadUrl: 'http://example.com/fw.img',
        checksum: '123',
        checkInterval: 'daily',
        checkTime: '06:00:00Z',
      );

      final info3 = FirmwareOtaInfo(
        version: '2.0.0',
        releaseDate: DateTime.utc(2025, 1, 1),
        downloadUrl: 'http://example.com/fw.img',
        checksum: '123',
        checkInterval: 'daily',
        checkTime: '06:00:00Z',
      );

      expect(info1, equals(info2));
      expect(info1, isNot(equals(info3)));
    });
  });

  group('FirmwareOtaCheckParams', () {
    test('toQueryParams returns correct map', () {
      const params = FirmwareOtaCheckParams(
        macAddress: '74-12-13-21-56-3A',
        installedVersion: '1.2.1.26052809',
        modelNumber: 'M60-US',
        hardwareVersion: '1',
        ipAddress: '118.163.122.211',
      );

      final queryParams = params.toQueryParams();

      expect(queryParams, {
        'mac_address': '74-12-13-21-56-3A',
        'installed_version': '1.2.1.26052809',
        'model_number': 'M60-US',
        'hardware_version': '1',
        'ip_address': '118.163.122.211',
      });
    });

    test('equality works correctly', () {
      const params1 = FirmwareOtaCheckParams(
        macAddress: '74-12-13-21-56-3A',
        installedVersion: '1.2.1',
        modelNumber: 'M60-US',
        hardwareVersion: '1',
        ipAddress: '192.168.1.1',
      );

      const params2 = FirmwareOtaCheckParams(
        macAddress: '74-12-13-21-56-3A',
        installedVersion: '1.2.1',
        modelNumber: 'M60-US',
        hardwareVersion: '1',
        ipAddress: '192.168.1.1',
      );

      const params3 = FirmwareOtaCheckParams(
        macAddress: 'AA-BB-CC-DD-EE-FF',
        installedVersion: '1.2.1',
        modelNumber: 'M60-US',
        hardwareVersion: '1',
        ipAddress: '192.168.1.1',
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}
